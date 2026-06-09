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

    sh -c "ueberzugpp layer --parser json --output x11 < \"$FIFO_UEBERZUG\" >/dev/null 2>&1" &
    set -l ueberzug_pid $last_pid

    sh -c "sleep infinity > \"$FIFO_UEBERZUG\"" &
    set -l sleep_pid $last_pid

    # 2. Tạo script Preview (Giao diện 9:1 mượt mà)
    set -l preview_script "$tmp_dir/preview.sh"
    echo '#!/usr/bin/env bash
line="$1"

url=$(echo "$line" | awk "{print \$NF}")
vid_id=$(echo "$url" | sed -E "s/.*(v=|youtu\.be\/)([^&?]+).*/\2/")

x=${FZF_PREVIEW_LEFT:-0}
y=${FZF_PREVIEW_TOP:-0}
w=${FZF_PREVIEW_COLUMNS:-0}
h=${FZF_PREVIEW_LINES:-0}

C_CYAN="\033[1;36m"
C_BLUE="\033[1;34m"
C_YELLOW="\033[1;33m"
C_MAG="\033[1;35m"
C_RESET="\033[0m"

img_h=$((h - 7))
if [[ $img_h -lt 5 ]]; then img_h=5; fi

echo ""

if [[ -n "$vid_id" && -p "$FIFO_UEBERZUG" ]]; then
    img_path="'$tmp_dir'/${vid_id}.jpg"
    current_vid_file="'$tmp_dir'/current_vid"
    echo "$vid_id" > "$current_vid_file"

    TAB=$(printf "\t")
    IFS="$TAB" read -r m_id m_title m_channel m_time m_views < <(grep -m 1 "^${vid_id}" "'$tmp_dir'/metadata.tsv" 2>/dev/null)

    for (( i=0; i<img_h; i++ )); do echo ""; done

    pad_len=$(( (w - 60) / 2 ))
    [[ $pad_len -lt 0 ]] && pad_len=0
    pad=$(printf "%*s" "$pad_len" "")

    if [[ -n "$m_title" ]]; then
        echo -e "${pad}${C_CYAN}▶ ${m_title}${C_RESET}"
    else
        echo -e "${pad}${C_CYAN}Đang tải dữ liệu...${C_RESET}"
    fi

    echo -e "${pad}${C_YELLOW}👤 ${m_channel:-N/A}   |   ${C_MAG}👁 ${m_views:-N/A} views   |   ${C_BLUE}⏱ ${m_time:-N/A}${C_RESET}"
    echo -e "${pad}🔗 youtu.be/${vid_id}"

    draw_image() {
        if [[ "$(cat "$current_vid_file" 2>/dev/null)" == "$vid_id" ]]; then
            printf "{\"action\": \"add\", \"identifier\": \"fzf_preview\", \"x\": %d, \"y\": %d, \"width\": %d, \"height\": %d, \"scaler\": \"fit_contain\", \"path\": \"%s\"}\n" "$x" "$y" "$w" "$img_h" "$img_path" > "$FIFO_UEBERZUG"
        fi
    }

    if [[ -f "$img_path" ]]; then
        draw_image
    else
        (
            curl -s -f "https://img.youtube.com/vi/${vid_id}/maxresdefault.jpg" -o "$img_path" || \
            curl -s -f "https://img.youtube.com/vi/${vid_id}/hqdefault.jpg" -o "$img_path"
            draw_image
        ) &
    fi
else
    if [[ -p "$FIFO_UEBERZUG" ]]; then
        printf "{\"action\": \"remove\", \"identifier\": \"fzf_preview\"}\n" > "$FIFO_UEBERZUG"
    fi
fi
' > "$preview_script"
    chmod +x "$preview_script"

    echo "⚡ Đang truy xuất siêu tốc từ YouTube..."

    # 3. Bộ lọc TUYỆT CHIÊU: Tối ưu yt-dlp tối đa để đạt tốc độ bàn thờ
    # - Giới hạn 10 kết quả (đủ dùng và nhanh gấp đôi 20 kết quả)
    # - --playlist-end 10 ép dừng cào sớm
    # - Sử dụng extractor-args của web client mobile để giảm tải dung lượng JSON
    set -l selected (yt-dlp "ytsearch10:$argv" \
        --flat-playlist \
        --playlist-end 10 \
        --dump-json \
        --no-check-certificates \
        --extractor-args "youtube:player_client=web" 2>/dev/null \
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
                id = $6
                title_full = $1
                channel_full = $2
                
                m = int($3 / 60)
                s = int($3 % 60)
                time = sprintf("%d:%02d", m, s)
                views = commas($4)

                meta_file = tmp "/metadata.tsv"
                printf "%s\t%s\t%s\t%s\t%s\n", id, title_full, channel_full, time, views >> meta_file
                fflush(meta_file)

                # Tải ảnh ngầm (Non-blocking)
                system("(curl -s -f \"https://img.youtube.com/vi/" id "/maxresdefault.jpg\" -o \"" tmp "/" id ".jpg\" || curl -s -f \"https://img.youtube.com/vi/" id "/hqdefault.jpg\" -o \"" tmp "/" id ".jpg\") >/dev/null 2>&1 &")

                title_trunc = length($1) > 55 ? substr($1, 1, 52) "..." : $1
                channel_trunc = length($2) > 20 ? substr($2, 1, 17) "..." : $2
                
                print title_trunc, "|", channel_trunc, "|", time, "|", views, "|", $5
            }
        ' \
        | column -t -s (printf '\t') \
        | env FIFO_UEBERZUG="$FIFO_UEBERZUG" fzf --ansi --reverse \
            --prompt="🎵 Chọn bài bằng Lên/Xuống: " \
            --preview "$preview_script {}" \
            --preview-window "up:85%:border-bottom" \
            --info=hidden)

    # 4. Dọn dẹp
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
        set -l video_title (echo $selected | awk -F '\\|' '{print $1}' | xargs)
        
        echo "▶️ Đang phát bài: $video_title"
        # --no-video để tối ưu băng thông phát nhạc
        mpv --no-video "$video_url"
    else
        echo "Đã hủy chọn bài."
    end
end
