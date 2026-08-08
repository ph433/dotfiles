function fzfrecent -d "Tìm file dựa trên lịch sử mở trong Neovim (Dashboard Top 10)"
    # 1. Lấy danh sách 10 file gần nhất hợp lệ (dạng thô: <timestamp> <path>)
    set -l top10 (_fzfrecent_get_top10)
    if test $status -ne 0
        echo "Chưa có dữ liệu hoặc không có file nào trong lịch sử còn tồn tại."
        return 1
    end

    # 2. Chuyển đổi mảng $top10 thành chuỗi hiển thị UI (đánh số 0-9 & relative time)
    set -l list (_fzfrecent_format_list $top10)

    # 3. Hiển thị FZF Menu
    set -l fzf_out (printf "%s\n" $list | string split \n | fzf \
        --prompt="🕒 Nvim Recent (0-9 nhảy | Ctrl-Space xem chi tiết)> " \
        --delimiter=' │ ' \
        --nth=2 \
        --tiebreak=index \
        --preview="bat --color=always {2} 2>/dev/null || cat {2}" \
        --preview-window="bottom:70%" \
        --expect=right,enter,insert \
        --layout=reverse \
        --height=100%)

    # 4. Xử lý phím bấm và kết quả trả về từ FZF
    set -l key $fzf_out[1]
    set -l selected_line $fzf_out[2]

    if test -z "$selected_line"
        return
    end

    set -l target_path (echo "$selected_line" | awk -F ' │ ' '{print $2}')

    switch "$key"
        case right
            commandline -i (string escape "$target_path")" "
            # log_recent_file "$target_path"
            # fish -c "__fzf_score_file '$target_path'" >/dev/null 2>&1 &
            fish -c "log_recent_file '$target_path'; __fzf_score_file '$target_path'" >/dev/null 2>&1 &
        case enter
            nvim "$target_path"
        case ins insert
            set -l dir_path (dirname -- "$target_path")
            if test -d "$dir_path"
                cd "$dir_path"
            end
    end   

    commandline -f repaint 2>/dev/null
end
