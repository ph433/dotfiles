function fzfrecentdir -d "Tìm thư mục dựa trên lịch sử di chuyển (Top 10)"

    set -l log_file "$HOME/.cache/nvim_recent.log"
    test -f "$log_file"; or return 1
    
    # 1. Lấy danh sách 10 thư mục gần nhất hợp lệ
    set -l top_files (_fzfrecent_get_top_generic "$HOME/.cache/dir_recent.log")
    if test (count $top_files) -eq 0
        echo "Chưa có dữ liệu hoặc không có file nào trong lịch sử còn tồn tại."
        return 1
    end

    # 2. Tái sử dụng hàm format chung
    set -l list (_fzfrecent_format_list $top_files)

    # 3. Hiển thị FZF Menu với preview danh sách file trong thư mục (Thêm cờ -m / --multi)
    set -l fzf_out (printf "%s\n" $list | fzf \
        -m \
        --prompt="📁 Dir Recent (Tab chọn nhiều | Ctrl-Space xem chi tiết)> " \
        --delimiter=' │ ' \
        --nth=2 \
        --tiebreak=index \
        --preview="command -v eza >/dev/null && eza -1 --icons --color=always {2} 2>/dev/null || ls -A --color=always {2} 2>/dev/null" \
        --preview-window="bottom:70%" \
        --expect=right,enter \
        --bind="ctrl-x:reload(fish -c '_fzfrecent_feed \"$log_file\"')" \
        --layout=reverse \
        --height=100%)

    # 4. Xử lý phím bấm và kết quả trả về từ FZF
    set -l key $fzf_out[1]

    # Lấy toàn bộ các dòng được chọn (từ phần tử thứ 2 trở đi)
    set -l selected_lines $fzf_out[2..-1]

    if test -z "$selected_lines"
        return
    end

    # Tách lấy danh sách target_path cho tất cả các thư mục đã chọn
    set -l target_paths
    for line in $selected_lines
        set -a target_paths (echo "$line" | awk -F ' │ ' '{print $2}')
    end

    switch "$key"
        case right
            # Chèn tất cả các đường dẫn thư mục đã chọn vào commandline
            set -l escaped_paths
            for path in $target_paths
                set -a escaped_paths (string escape -- "$path")
            end
            commandline -i (string join " " $escaped_paths)" "

            # Ghi log background cho tất cả các thư mục đã chọn
            for path in $target_paths
                fish -c "log_recent_dir '$path'" >/dev/null 2>&1 &
            end

        case enter
            # Chỉ `cd` vào thư mục ĐẦU TIÊN trong danh sách chọn
            cd "$target_paths[1]"
    end

    commandline -f repaint 2>/dev/null
end
