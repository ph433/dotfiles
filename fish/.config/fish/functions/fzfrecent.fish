function fzfrecent -d "Tìm file dựa trên lịch sử mở trong Neovim (Dashboard Top 10)"
    set log_file "$HOME/.cache/nvim_recent.log"

    if not test -f "$log_file"
        echo "Chưa có dữ liệu lịch sử file."
        return 1
    end

    # Lọc lấy tối đa 10 file mới nhất
    set -l top10 (awk '{time=$1; sub(/^[0-9]+ /, ""); map[$0]=time} END {for (p in map) print map[p] " " p}' $log_file | sort -nr | head -n 10)
    
    # GHI ĐÈ LẠI LOG
    if test -n "$top10"
        printf "%s\n" $top10 > $log_file
    end

    # Tạo danh sách đánh số 0-9
    set -l list (printf "%s\n" $top10 | awk '{time=$1; sub(/^[0-9]+ /, ""); printf "%d │ %-16s │ %s\n", NR-1, strftime("%Y-%m-%d %H:%M", time), $0}')

    # Cấu hình chuỗi phím tắt để nhảy con trỏ
    set -l binds "0:first"
    set binds "$binds,1:first+down"
    set binds "$binds,2:first+down+down"
    set binds "$binds,3:first+down+down+down"
    set binds "$binds,4:first+down+down+down+down"
    set binds "$binds,5:first+down+down+down+down+down"
    set binds "$binds,6:first+down+down+down+down+down+down"
    set binds "$binds,7:first+down+down+down+down+down+down+down"
    set binds "$binds,8:first+down+down+down+down+down+down+down+down"
    set binds "$binds,9:first+down+down+down+down+down+down+down+down+down"

    # THÊM MỚI: Gán Ctrl-Space chạy `execute` ngầm. 
    # Lưu ý: fzf chạy execute bằng môi trường /bin/sh (POSIX), nên cú pháp ở đây là của Bash/SH chứ không phải Fish
    set binds "$binds,ctrl-space:execute(command -v bat >/dev/null && bat --paging=always --color=always {3} || less -R {3})"

    # FZF Menu
    # Đã gỡ ctrl-space khỏi --expect
    set -l fzf_out (printf "%s\n" $list | fzf \
        --prompt="🕒 Nvim Recent (0-9 nhảy | Ctrl-Space xem chi tiết)> " \
        --delimiter=' │ ' \
        --nth=3 \
        --tiebreak=index \
        --preview="bat --color=always {3} 2>/dev/null || cat {3}" \
        --preview-window="bottom:70%" \
        --expect=right,enter \
        --bind="$binds" \
        --layout=reverse \
        --height=100%)

    # Xử lý output trả về (giờ chỉ còn right và enter)
    set -l key $fzf_out[1]
    set -l selected_line $fzf_out[2]

    # Nếu thoát bằng Esc
    if test -z "$selected_line"
        return
    end

    # Tách lấy cột đường dẫn
    set -l target_path (echo "$selected_line" | awk -F ' │ ' '{print $3}')

    # Điều hướng hành động
    switch "$key"
        case right
            # Phím Right: Dán trực tiếp đường dẫn ra dòng lệnh (prompt)
            commandline -i (string escape "$target_path")" "
            
            # Bắn vào log recent: Ghi thời gian hiện tại và đường dẫn vào log
            set -l timestamp (date +%s)
            echo "$timestamp $target_path" >> "$HOME/.cache/nvim_recent.log"
            
        case enter
            # Phím Enter: Mở nvim
            nvim "$target_path"
    end
    
    # Refresh lại dòng lệnh để hiển thị đường dẫn vừa dán ngay lập tức
    commandline -f repaint 2>/dev/null
end
