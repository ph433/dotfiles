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

    # 2. Tạo script Preview (Đã fix lỗi Bash không hiểu dấu Tab)
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

half_w=$((w / 2))
pad_len=$((half_w + 2))
pad=$(printf "%*s" "$pad_len" "")

echo ""

if [[ -n "$vid_id" && -p "$FIFO_UEBERZUG" ]]; then
    img_path="'$tmp_dir'/${vid_id}.jpg"
    current_vid_file="'$tmp_dir'/current_vid"
    echo "$vid_id" > "$current_vid_file"

    # FIX LỖI N/A: Khai báo phím Tab chuẩn cho Bash để chẻ cột chính xác
    TAB=$(printf "\t")
    IFS="$TAB" read -r m_id m_title m_channel m_time m_views < <(grep -m 1 "^${vid_id}" "'$tmp_dir'/metadata.tsv" 2>/dev/null)

    if [[ -n "$m_title" ]]; then
        echo "$m_title" | fold -s -w $((w - pad_len - 2)) | while read -r t_line; do
            echo -e "${pad}${C_CYAN}${t_line}${C_RESET}"
        done
    else
        echo -e "${pad}${C_CYAN}Đang tải dữ liệu...${C_RESET}"
    fi
    echo ""

    print_info() {
        local label=$(printf "%-9s" "$1")
        echo -e "${pad}${C_BLUE}${label}${C_RESET} ${3}${2}${C_RESET}"
    }

    print_info "Channel" "${m_channel:-N/A}" "$C_YELLOW"
    print_info "Duration" "${m_time:-N/A}" "$C_YELLOW"
    print_info "Views" "${m_views:-N/A}" "$C_MAG"
    print_info "Link" "youtu.be/${vid_id}" "$C_RESET"

    for (( i=0; i<h; i++ )); do echo ""; done

    draw_image() {
        if [[ "$(cat "$current_vid_file" 2>/dev/null)" == "$vid_id" ]]; then
            printf "{\"action\": \"add\", \"identifier\": \"fzf_preview\", \"x\": %d, \"y\": %d, \"width\": %d, \"height\": %d, \"scaler\": \"fit_contain\", \"path\": \"%s\"}\n" "$x" "$y" "$half_w" "$h" "$img_path" > "$FIFO_UEBERZUG"
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

    echo "🔍 Đang cào dữ liệu và tải ngầm ảnh bìa FULL HD..."

    # 3. Lấy data và nạp vào FZF
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
                id = $6
                title_full = $1
                channel_full = $2
                
                m = int($3 / 60)
                s = int($3 % 60)
                time = sprintf("%d:%02d", m, s)
                views = commas($4)

                # FIX LỖI N/A: Ép AWK xả dữ liệu ra file ngay lập tức bằng fflush
                meta_file = tmp "/metadata.tsv"
                printf "%s\t%s\t%s\t%s\t%s\n", id, title_full, channel_full, time, views >> meta_file
                fflush(meta_file)

                system("(curl -s -f \"https://img.youtube.com/vi/" id "/maxresdefault.jpg\" -o \"" tmp "/" id ".jpg\" || curl -s -f \"https://img.youtube.com/vi/" id "/hqdefault.jpg\" -o \"" tmp "/" id ".jpg\") >/dev/null 2>&1 &")

                title_trunc = length($1) > 55 ? substr($1, 1, 52) "..." : $1
                channel_trunc = length($2) > 20 ? substr($2, 1, 17) "..." : $2
                
                print title_trunc, "|", channel_trunc, "|", time, "|", views, "|", $5
            }
        ' \
        | column -t -s (printf '\t') \
        | env FIFO_UEBERZUG="$FIFO_UEBERZUG" fzf --ansi --reverse --prompt="🎵 Chọn bài để quẩy: " \
            --preview "$preview_script {}" \
            --preview-window "up:60%")

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
        mpv --no-video "$video_url"
    else
        echo "Đã hủy chọn bài."
    end
end
