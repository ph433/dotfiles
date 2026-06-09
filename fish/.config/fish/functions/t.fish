function t
    if test (count $argv) -eq 0
        echo "Nhập tên bài hát nữa bạn ơi! Ví dụ: t lofi chill"
        return
    end

    echo "🔍 Đang khởi tạo bộ xem trước..."

    set -l search_query (string join " " $argv)

    # 1. Khởi tạo thư mục tạm và FIFO
    set -g _t_tmp_dir (mktemp -d)
    set -l FIFO_UEBERZUG "$_t_tmp_dir/fzf-ueberzug-pipe"
    mkfifo "$FIFO_UEBERZUG"

    # Định nghĩa hàm tự động dọn dẹp
    function _t_cleanup --on-event fish_prompt --on-signal INT
        if set -q _t_ueberzug_pid; and test -n "$_t_ueberzug_pid"
            kill $_t_ueberzug_pid 2>/dev/null
        end
        if set -q _t_sleep_pid; and test -n "$_t_sleep_pid"
            kill $_t_sleep_pid 2>/dev/null
        end
        if set -q _t_tmp_dir; and test -d "$_t_tmp_dir"
            rm -rf "$_t_tmp_dir"
        end
        
        set -e _t_ueberzug_pid 2>/dev/null
        set -e _t_sleep_pid 2>/dev/null
        set -e _t_tmp_dir 2>/dev/null
        functions -e _t_cleanup 2>/dev/null
    end

    # 🛠 FIX DEADLOCK: Giao việc kết nối I/O của FIFO cho `sh` xử lý ngầm. 
    # Thay sleep infinity bằng tail -f /dev/null để tương thích đa nền tảng hơn.
    sh -c '
        tail -f /dev/null > "$1" &
        p1=$!
        ueberzugpp layer --parser json --output x11 < "$1" >/dev/null 2>&1 &
        p2=$!
        echo "$p1 $p2"
    ' _ "$FIFO_UEBERZUG" | read -l t_sleep_pid t_ub_pid
    
    set -g _t_sleep_pid $t_sleep_pid
    set -g _t_ueberzug_pid $t_ub_pid

    # 2. Tạo script Preview
    set -l preview_script "$_t_tmp_dir/preview.sh"
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
C_GREEN="\033[1;32m"
C_RESET="\033[0m"

echo "" # Padding top

if [[ -n "$vid_id" && -p "'$FIFO_UEBERZUG'" ]]; then
    img_path="'$_t_tmp_dir'/${vid_id}.jpg"
    current_vid_file="'$_t_tmp_dir'/current_vid"
    echo "$vid_id" > "$current_vid_file"

    TAB=$(printf "\t")
    IFS="$TAB" read -r m_id m_title m_channel m_time m_views < <(grep -m 1 "^${vid_id}" "'$_t_tmp_dir'/metadata.tsv" 2>/dev/null)

    if [[ -n "$m_title" ]]; then
        echo -e " ${C_CYAN}▶ Tiêu đề:${C_RESET} ${m_title}"
        echo -e " ${C_YELLOW}👤 Kênh:   ${C_RESET} ${m_channel:-N/A}"
        echo -e " ${C_MAG}👁 Lượt xem:${C_RESET} ${m_views:-N/A} views"
        echo -e " ${C_BLUE}⏱ Thời lượng:${C_RESET} ${m_time:-N/A}"
        echo -e " ${C_GREEN}🔗 Link:   ${C_RESET} youtu.be/${vid_id}"
    else
        echo -e " ${C_CYAN}Đang tải dữ liệu...${C_RESET}"
    fi

    img_h=$(( h - 2 ))
    if [[ $img_h -lt 5 ]]; then img_h=5; fi
    img_w=$(( img_h * 7 / 2 )) 
    img_x=$(( x + w - img_w - 2 ))
    img_y=$(( y + 1 ))             

    draw_image() {
        if [[ "$(cat "$current_vid_file" 2>/dev/null)" == "$vid_id" ]]; then
            printf "{\"action\": \"add\", \"identifier\": \"fzf_preview\", \"x\": %d, \"y\": %d, \"width\": %d, \"height\": %d, \"scaler\": \"fit_contain\", \"path\": \"%s\"}\n" "$img_x" "$img_y" "$img_w" "$img_h" "$img_path" > "'$FIFO_UEBERZUG'" &
        fi
    }

    if [[ -f "$img_path" ]]; then
        draw_image
    else
        (
            curl -s -f "https://img.youtube.com/vi/${vid_id}/maxresdefault.jpg" -o "$img_path" || \
            curl -s -f "https://img.youtube.com/vi/${vid_id}/hqdefault.jpg" -o "$img_path"
            draw_image
        ) >/dev/null 2>&1 &
    fi
else
    if [[ -p "'$FIFO_UEBERZUG'" ]]; then
        printf "{\"action\": \"remove\", \"identifier\": \"fzf_preview\"}\n" > "'$FIFO_UEBERZUG'" &
    fi
fi
' > "$preview_script"
    chmod +x "$preview_script"

    echo "⚡ Đang truy xuất siêu tốc từ YouTube..."

    # 3. Bộ lọc fzf tối giản
    set -l selected (yt-dlp "ytsearch10:$search_query" \
        --flat-playlist \
        --playlist-end 10 \
        --dump-json \
        --no-check-certificates \
        --ignore-errors 2>/dev/null \
        | jq --unbuffered -r '[
            (.title // "Không rõ"), 
            (.channel // .uploader // "Không rõ"), 
            (.duration // 0), 
            (.view_count // 0), 
            .url,
            .id
          ] | @tsv' \
        | awk -F '\t' -v OFS='\t' -v tmp="$_t_tmp_dir" '
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

                system("(curl -s -f \"https://img.youtube.com/vi/" id "/maxresdefault.jpg\" -o \"" tmp "/" id ".jpg\" || curl -s -f \"https://img.youtube.com/vi/" id "/hqdefault.jpg\" -o \"" tmp "/" id ".jpg\") >/dev/null 2>&1 &")

                title_trunc = length($1) > 65 ? substr($1, 1, 62) "..." : $1
                
                print title_trunc "\t|\t" time "\t" $5
            }
        ' \
        | column -t -s (printf '\t') \
        | env FIFO_UEBERZUG="$FIFO_UEBERZUG" fzf --ansi --reverse \
            --prompt="🎵 Chọn bài bằng Lên/Xuống: " \
            --preview "$preview_script {}" \
            --preview-window "down:35%:border-top" \
            --with-nth="1..-2" \
            --info=hidden)

    # 4. Dọn dẹp thủ công NGAY SAU KHI fzf TẮT
    # 🛠 FIX DEADLOCK: Cô lập việc ghi FIFO khi dọn dẹp khỏi Fish
    if test -p "$FIFO_UEBERZUG"
        sh -c 'printf "{\"action\": \"remove\", \"identifier\": \"fzf_preview\"}\n" > "$1" 2>/dev/null &' _ "$FIFO_UEBERZUG"
    end

    if set -q _t_ueberzug_pid; and test -n "$_t_ueberzug_pid"
        kill $_t_ueberzug_pid 2>/dev/null
    end
    if set -q _t_sleep_pid; and test -n "$_t_sleep_pid"
        kill $_t_sleep_pid 2>/dev/null
    end

    # 5. Xử lý chơi nhạc
    if test -n "$selected"
        set -l video_url (echo $selected | awk '{print $NF}')
        set -l video_title (echo $selected | awk -F '\\|' '{print $1}' | xargs)
        
        echo "▶️ Đang phát bài: $video_title"
        mpv --no-video "$video_url"
    else
        echo "Đã hủy chọn bài."
    end
    
    # Xóa file rác
    if set -q _t_tmp_dir; and test -d "$_t_tmp_dir"
        rm -rf "$_t_tmp_dir"
    end
end
