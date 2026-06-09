function t
    if test (count $argv) -eq 0
        echo "Nhập tên bài hát nữa bạn ơi! Ví dụ: y lofi chill"
        return
    end

    echo "🔍 Đang khởi tạo bộ xem trước..."

    # 1. Khởi tạo thư mục tạm, Ueberzugpp và FIFO
    set -l tmp_dir (mktemp -d)
    set -x FIFO_UEBERZUG "$tmp_dir/fzf-ueberzug-pipe"
    mkfifo "$FIFO_UEBERZUG"

    sh -c "ueberzugpp layer --parser json --output x11 < \"$FIFO_UEBERZUG\"" &
    set -l ueberzug_pid $last_pid

    sh -c "sleep infinity > \"$FIFO_UEBERZUG\"" &
    set -l sleep_pid $last_pid

    # 2. Tạo script Preview (xử lý việc tải & hiển thị Thumbnail)
    set -l preview_script "$tmp_dir/preview.sh"
    echo '#!/usr/bin/env bash
line="$1"

# Lấy URL ở cột cuối cùng từ dòng chọn của fzf
url=$(echo "$line" | awk "{print \$NF}")

# Trích xuất Video ID từ URL (VD: https://www.youtube.com/watch?v=dQw4w9WgXcQ -> dQw4w9WgXcQ)
vid_id=$(echo "$url" | sed -E "s/.*(v=|youtu\.be\/)([^&?]+).*/\2/")

x=${FZF_PREVIEW_LEFT:-0}
y=${FZF_PREVIEW_TOP:-0}
w=${FZF_PREVIEW_COLUMNS:-0}
h=${FZF_PREVIEW_LINES:-0}

if [[ -n "$vid_id" && -p "$FIFO_UEBERZUG" ]]; then
    img_path="'$tmp_dir'/${vid_id}.jpg"
    
    # Tải thumbnail (bản mqdefault 320x180 load cực nhanh) nếu chưa có
    if [[ ! -f "$img_path" ]]; then
        curl -s "https://img.youtube.com/vi/${vid_id}/mqdefault.jpg" -o "$img_path"
    fi
    
    printf "{\"action\": \"add\", \"identifier\": \"fzf_preview\", \"x\": %d, \"y\": %d, \"width\": %d, \"height\": %d, \"scaler\": \"fit_contain\", \"path\": \"%s\"}\n" "$x" "$y" "$w" "$h" "$img_path" > "$FIFO_UEBERZUG"
else
    if [[ -p "$FIFO_UEBERZUG" ]]; then
        printf "{\"action\": \"remove\", \"identifier\": \"fzf_preview\"}\n" > "$FIFO_UEBERZUG"
    fi
fi
' > "$preview_script"
    chmod +x "$preview_script"

    echo "🔍 Đang bốc dữ liệu trực tiếp từ YouTube bằng yt-dlp..."

    # 3. Chuỗi lệnh lấy data và nạp vào FZF (kết nối với script preview)
    set -l selected (yt-dlp "ytsearch20:$argv" \
        --flat-playlist \
        --dump-json \
        --extractor-args "youtube:player_client=android" 2>/dev/null \
        | jq -r '[
            (.title // "Không rõ"), 
            (.channel // .uploader // "Không rõ"), 
            (.duration // 0), 
            (.view_count // 0), 
            .url
          ] | @tsv' \
        | awk -F '\t' -v OFS='\t' '
            function commas(n) {
                if (n == 0 || n == "null") return "N/A"
                r = ""
                while(length(n) > 3) {
                    r = "," substr(n, length(n)-2) r
                    n = substr(n, 1, length(n)-3)
                }
                return n r
            }
            {
                title = length($1) > 55 ? substr($1, 1, 52) "..." : $1
                channel = length($2) > 20 ? substr($2, 1, 17) "..." : $2
                
                m = int($3 / 60)
                s = int($3 % 60)
                time = sprintf("%d:%02d", m, s)
                
                views = commas($4)
                
                print title, "|", channel, "|", time, "|", views, "|", $5
            }
        ' \
        | column -t -s (printf '\t') \
        | env FIFO_UEBERZUG="$FIFO_UEBERZUG" fzf --ansi --reverse --prompt="🎵 Chọn bài để quẩy: " \
            --preview "$preview_script {}" \
            --preview-window "right:40%")

    # 4. Dọn dẹp FIFO, tiến trình và rác
    if test -p "$FIFO_UEBERZUG"
        printf '{"action": "remove", "identifier": "fzf_preview"}\n' > "$FIFO_UEBERZUG"
    end
    
    if test -n "$ueberzug_pid"
        kill $ueberzug_pid 2>/dev/null
    end
    if test -n "$sleep_pid"
        kill $sleep_pid 2>/dev/null
    end
    
    rm -rf "$tmp_dir"

    # 5. Xử lý chơi nhạc
    if test -n "$selected"
        set -l video_url (echo $selected | awk '{print $NF}')
        
        set -l video_title (echo $selected | awk -F '\\|' '{print $1}')
        set video_title (string trim "$video_title")
        
        echo "▶️ Đang phát bài: $video_title"
        mpv --no-video "$video_url"
    else
        echo "Đã hủy chọn bài."
    end
end
