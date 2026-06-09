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

    # 🛠 FIX DEADLOCK
    sh -c '
        tail -f /dev/null > "$1" &
        p1=$!
        ueberzugpp layer --parser json --output x11 < "$1" >/dev/null 2>&1 &
        p2=$!
        echo "$p1 $p2"
    ' _ "$FIFO_UEBERZUG" | read -l t_sleep_pid t_ub_pid
    
    set -g _t_sleep_pid $t_sleep_pid
    set -g _t_ueberzug_pid $t_ub_pid

    # 2. Tạo script Preview (Đã cấu trúc căn giữa 100%)
    set -l preview_script "$_t_tmp_dir/preview.sh"
    echo '#!/usr/bin/env bash
line="$1"

url=$(echo "$line" | awk "{print \$NF}")
vid_id=$(echo "$url" | sed -E "s/.*(v=|youtu\.be\/)([^&?]+).*/\2/")

# Lấy kích thước an toàn
tty_lines=$(tput lines < /dev/tty 2>/dev/null || echo 24)
tty_cols=$(tput cols < /dev/tty 2>/dev/null || echo 80)

if [[ -n "$vid_id" && -p "'$FIFO_UEBERZUG'" ]]; then
    img_path="'$_t_tmp_dir'/${vid_id}.jpg"
    current_vid_file="'$_t_tmp_dir'/current_vid"
    echo "$vid_id" > "$current_vid_file"

    # TRÍCH XUẤT THÔNG TIN
    TAB=$(printf "\t")
    line_data=$(grep -m 1 "^${vid_id}${TAB}" "'$_t_tmp_dir'/metadata.tsv" 2>/dev/null)
    
    t_title="Không rõ"
    t_chan="Không rõ"
    t_time="0:00"
    t_views="0"
    if [[ -n "$line_data" ]]; then
        IFS="$TAB" read -r _ t_title t_chan t_time t_views <<< "$line_data"
    fi

    # LẤY TỌA ĐỘ VÀ KÍCH THƯỚC KHUNG PREVIEW
    prev_x=${FZF_PREVIEW_LEFT:-0}
    prev_y=${FZF_PREVIEW_TOP:-$(( tty_lines - (tty_lines * 60 / 100) ))}
    prev_w=${FZF_PREVIEW_COLUMNS:-$tty_cols}
    prev_h=${FZF_PREVIEW_LINES:-$(( (tty_lines * 60 / 100) - 1 ))}

    # CHIA KHU VỰC: Ảnh chiếm 65% phía trên
    img_area_h=$(( prev_h * 65 / 100 ))

    # TÍNH TOÁN CĂN GIỮA ẢNH THEO TỶ LỆ CHUẨN (~16:9 quy đổi theo pixel terminal)
    ideal_w=$(( img_area_h * 35 / 10 ))
    [[ $ideal_w -gt $prev_w ]] && ideal_w=$prev_w

    img_x=$(( prev_x + (prev_w - ideal_w) / 2 ))
    img_y=$prev_y
    img_w=$ideal_w
    img_h=$img_area_h

    # Đẩy lề chữ xuống dưới ảnh
    for ((i=0; i<img_area_h; i++)); do
        echo ""
    done
    
    # HÀM CĂN GIỮA TEXT
    print_centered() {
        local color="$1"
        local prefix="$2"
        local content="$3"
        # Tính toán độ dài chuỗi để căn lề dựa vào độ rộng terminal
        local raw_len=$((${#prefix} + ${#content} + 1))
        local pad=$(( (prev_w - raw_len) / 2 ))
        [[ $pad -lt 0 ]] && pad=0
        printf "%${pad}s\033[%sm%s\033[0m %s\n\n" "" "$color" "$prefix" "$content"
    }

    # IN THÔNG TIN CĂN ĐỀU GIỮA MÀN HÌNH
    print_centered "38;5;114" "🎵 Bài hát:" "$t_title"
    print_centered "38;5;39"  "👤 Kênh:" "$t_chan"
    print_centered "38;5;43"  "⏳ Thời lượng:" "$t_time"
    print_centered "38;5;176" "👁 Lượt xem:" "$t_views"

    # VẼ ẢNH
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

    # 3. Bộ lọc fzf
    set -l selected (yt-dlp "ytsearch20:$search_query" \
        --flat-playlist \
        --playlist-end 20 \
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

        title_trunc = length($1) > 55 ? substr($1, 1, 52) "..." : $1
        channel_trunc = length($2) > 20 ? substr($2, 1, 17) "..." : $2
        idx = sprintf("%02d", NR)

        printf "\033[1;31m%s.\033[0m \033[1;32m%s\033[0m\t\033[1;33m%s\033[0m\t\033[1;36m%s\033[0m\t👁 \033[1;35m%s\033[0m\t%s\n", idx, title_trunc, "["channel_trunc"]", time, views, $5
        }
        ' \
            | column -t -s (printf '\t') \
        | env FIFO_UEBERZUG="$FIFO_UEBERZUG" fzf --ansi --reverse \
            --prompt="🎵 Tìm kiếm (Top 20): " \
            --color="border:-1" \
        --preview "$preview_script {}" \
        --preview-window "bottom:60%:border-none:noinfo" \
            --with-nth="1..-2" \
            --info=inline-right)

    # 4. Dọn dẹp thủ công
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
        set -l video_title (echo $selected | awk -F '  +' '{print $1}' | xargs)
        
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
