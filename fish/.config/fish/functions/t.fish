function t
    if test (count $argv) -eq 0
        echo "Nhập tên bài hát nữa bạn ơi! Ví dụ: t lofi chill"
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

    # 2. Tạo script Preview (Hiển thị ngay lập tức vì ảnh đã được pre-fetch)
    set -l preview_script "$tmp_dir/preview.sh"
    echo '#!/usr/bin/env bash
line="$1"

# Lấy URL ở cột cuối cùng từ dòng chọn của fzf
url=$(echo "$line" | awk "{print \$NF}")

# Trích xuất Video ID từ URL
vid_id=$(echo "$url" | sed -E "s/.*(v=|youtu\.be\/)([^&?]+).*/\2/")

x=${FZF_PREVIEW_LEFT:-0}
y=${FZF_PREVIEW_TOP:-0}
w=${FZF_PREVIEW_COLUMNS:-0}
h=${FZF_PREVIEW_LINES:-0}

if [[ -n "$vid_id" && -p "$FIFO_UEBERZUG" ]]; then
    img_path="'$tmp_dir'/${vid_id}.jpg"
    current_vid_file="'$tmp_dir'/current_vid"
    
    echo "$vid_id" > "$current_vid_file"

    draw_image() {
        if [[ "$(cat "$current_vid_file" 2>/dev/null)" == "$vid_id" ]]; then
            printf "{\"action\": \"add\", \"identifier\": \"fzf_preview\", \"x\": %d, \"y\": %d, \"width\": %d, \"height\": %d, \"scaler\": \"fit_contain\", \"path\": \"%s\"}\n" "$x" "$y" "$w" "$h" "$img_path" > "$FIFO_UEBERZUG"
        fi
    }

    # Đa số trường hợp ảnh đã được tải xong bởi bước 3.
    # Lệnh if này chỉ làm chốt chặn (fallback) nếu mạng quá chậm, người dùng cuộn quá nhanh khi ảnh chưa kịp tải xong.
    if [[ ! -f "$img_path" ]]; then
        (
            curl -s "https://img.youtube.com/vi/${vid_id}/hqdefault.jpg" -o "$img_path"
            draw_image
        ) &
    else
        draw_image
    fi
else
    if [[ -p "$FIFO_UEBERZUG" ]]; then
        printf "{\"action\": \"remove\", \"identifier\": \"fzf_preview\"}\n" > "$FIFO_UEBERZUG"
    fi
fi
' > "$preview_script"
    chmod +x "$preview_script"

    echo "🔍 Đang bốc dữ liệu và tải ngầm ảnh bìa..."

    # 3. Chuỗi lệnh lấy data: Cập nhật JQ để lấy ID và AWK để ép tải ảnh ngầm (Pre-fetch)
    set -l selected (yt-dlp "ytsearch20:$argv" \
        --flat-playlist \
        --dump-json \
        --extractor-args "youtube:player_client=android" 2>/dev/null \
        | jq -r '[
            (.title // "Không rõ"), 
            (.channel // .uploader // "Không rõ"), 
            (.duration // 0), 
            (.view_count // 0), 
            .url,
            .id
          ] | @tsv' \
        | awk -F '\t' -v OFS='\t' -v tmp="$tmp_dir" '
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
                # KÍCH HOẠT PRE-FETCH: Bắn ngầm curl tải ảnh ngay khi có data của từng bài
                id = $6
                system("curl -s \"https://img.youtube.com/vi/" id "/hqdefault.jpg\" -o \"" tmp "/" id ".jpg\" >/dev/null 2>&1 &")

                # Format text để hiển thị
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
            --preview-window "up:50%")

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
