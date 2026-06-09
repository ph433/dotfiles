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

    # 2. Tạo script Preview (Chỉ tập trung vẽ Thumbnail kích thước lớn)
    set -l preview_script "$_t_tmp_dir/preview.sh"
    echo '#!/usr/bin/env bash
line="$1"

url=$(echo "$line" | awk "{print \$NF}")
vid_id=$(echo "$url" | sed -E "s/.*(v=|youtu\.be\/)([^&?]+).*/\2/")

x=${FZF_PREVIEW_LEFT:-0}
y=${FZF_PREVIEW_TOP:-0}
w=${FZF_PREVIEW_COLUMNS:-0}
h=${FZF_PREVIEW_LINES:-0}

if [[ -n "$vid_id" && -p "'$FIFO_UEBERZUG'" ]]; then
    img_path="'$_t_tmp_dir'/${vid_id}.jpg"
    current_vid_file="'$_t_tmp_dir'/current_vid"
    echo "$vid_id" > "$current_vid_file"

    # Đọc thông tin hiển thị dạng text ở phía trên ảnh trong khung preview
    TAB=$(printf "\t")
    IFS="$TAB" read -r m_id m_title m_channel m_time m_views < <(grep -m 1 "^${vid_id}" "'$_t_tmp_dir'/metadata.tsv" 2>/dev/null)

    C_CYAN="\033[1;36m"
    C_YELLOW="\033[1;33m"
    C_RESET="\033[0m"

    if [[ -n "$m_title" ]]; then
        echo -e " ${C_CYAN}▶ Channel:${C_RESET} ${m_channel:-N/A}  |  ${C_YELLOW}👁 Views:${C_RESET} ${m_views:-N/A}"
    else
        echo -e " ${C_CYAN}Đang tải thumbnail chất lượng cao...${C_RESET}"
    fi
    echo "" # Tạo khoảng trống ngăn cách dòng chữ và ảnh

    # Tính toán kích thước phóng to tối đa theo chiều rộng khung preview dưới
    img_h=$(( h - 3 )) 
    if [[ $img_h -lt 5 ]]; then img_h=5; fi
    
    # Tỷ lệ 16:9 phóng to vừa vặn bề ngang khung hình fzf
    img_w=$(( w - 4 ))
    img_x=$(( x + 2 ))
    img_y=$(( y + 2 ))             

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

    # 3. Bộ lọc fzf (Đẩy thông tin chi tiết: Thời lượng, Kênh lên nửa trên)
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

                # Cắt gọn bớt tiêu đề để nhường chỗ hiển thị tên Kênh và Thời lượng ở nửa trên
                title_trunc = length($1) > 45 ? substr($1, 1, 42) "..." : $1
                channel_trunc = length(channel_full) > 20 ? substr(channel_full, 1, 17) "..." : channel_full
                
                # Cấu trúc hiển thị dòng tìm kiếm: Tiêu đề | Kênh | Thời lượng
                print title_trunc "\t[\033[1;33m" channel_trunc "\033[0m]\t\033[1;36m" time "\033[0m\t" $5
            }
        ' \
        | column -t -s (printf '\t') \
        | env FIFO_UEBERZUG="$FIFO_UEBERZUG" fzf --ansi --reverse \
            --prompt="🎵 Tìm kiếm: " \
            --header="Danh sách bài hát kết quả (Tiêu đề | Kênh | Thời lượng):" \
            --preview "$preview_script {}" \
            --preview-window "down:60%:border-top" \
            --with-nth="1..-2" \
            --info=inline)

    # 4. Dọn dẹp thủ công NGAY SAU KHI fzf TẮT
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

