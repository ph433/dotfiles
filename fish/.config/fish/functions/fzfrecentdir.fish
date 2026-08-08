function fzfrecentdir -d "Tìm thư mục dựa trên lịch sử di chuyển (Top 10)"
    # 1. Lấy danh sách 10 thư mục gần nhất hợp lệ
    set -l top10 (_fzfrecentdir_get_top10)
    if test $status -ne 0
        echo "Chưa có dữ liệu hoặc không có thư mục nào trong lịch sử còn tồn tại."
        return 1
    end

    # 2. Tái sử dụng hàm format chung
    set -l list (_fzfrecent_format_list $top10)

    # 4. Hiển thị FZF Menu với preview danh sách file trong thư mục
    set -l fzf_out (printf "%s\n" $list | string split \n | fzf \
        --prompt="📁 Dir Recent (0-9 nhảy | Ctrl-Space xem chi tiết)> " \
        --delimiter=' │ ' \
        --nth=3 \
        --tiebreak=index \
        --preview="command -v eza >/dev/null && eza -1 --icons --color=always {2} 2>/dev/null || ls -A --color=always {2} 2>/dev/null" \
        --preview-window="bottom:70%" \
        --expect=right,enter \
        --layout=reverse \
        --height=100%)

    # 5. Xử lý phím bấm và kết quả trả về từ FZF
    set -l key $fzf_out[1]
    set -l selected_line $fzf_out[2]

    if test -z "$selected_line"
        return
    end

    set -l target_path (echo "$selected_line" | awk -F ' │ ' '{print $2}')

    switch "$key"
        case right
            commandline -i (string escape "$target_path")" "
            # log_recent_dir "$target_path"
            fish -c "log_recent_dir '$target_path'" >/dev/null 2>&1 &
        case enter
            cd "$target_path"
    end

    commandline -f repaint 2>/dev/null
end
