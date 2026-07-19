function fzfrecentdir -d "Tìm thư mục dựa trên lịch sử di chuyển (Top 10)"
    set log_file "$HOME/.cache/dir_recent.log"

    if not test -f "$log_file"
        echo "Chưa có dữ liệu lịch sử thư mục. Hãy cd vài nơi để tạo log!"
        return 1
    end

    # Lọc lấy tối đa 10 thư mục mới nhất (Loại bỏ trùng lặp)
    set -l top10 (awk '{time=$1; sub(/^[0-9]+ /, ""); map[$0]=time} END {for (p in map) print map[p] " " p}' $log_file | sort -nr | head -n 10)
    
    # Ghi đè lại log để dọn dẹp file, tránh log bị phình to vô hạn
    if test -n "$top10"
        # Thêm [-1..1] để ghi vào file theo chiều đảo ngược (mới nhất ở dưới cùng)
        printf "%s\n" $top10[-1..1] > $log_file
    end

    # Tạo danh sách đánh số 0-9 và tính toán thời gian (relative time)
    set -l current_time (date +%s)
    set -l list (printf "%s\n" $top10 | awk -v now="$current_time" '{
        time=$1; 
        sub(/^[0-9]+ /, ""); 
        
        diff = now - time;
        if (diff < 0) diff = 0; # Dự phòng lệch đồng hồ hệ thống
        
        if (diff < 60) { ago = diff "s ago" }
        else if (diff < 3600) { ago = int(diff/60) "m ago" }
        else if (diff < 86400) { ago = int(diff/3600) "h ago" }
        else if (diff < 604800) { ago = int(diff/86400) "d ago" }
        else if (diff < 2592000) { ago = int(diff/604800) "w ago" }
        else if (diff < 31536000) { ago = int(diff/2592000) "mo ago" }
        else { ago = int(diff/31536000) "y ago" }
        
        # Căn lề phải cột thời gian
        printf "%d │ %10s │ %s\n", NR-1, ago, $0
    }')

    # Cấu hình chuỗi phím tắt nhảy con trỏ
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

    # Mở bảng chi tiết: Dùng eza hoặc ls -lA để xem chi tiết bên trong thư mục
    set binds "$binds,ctrl-space:execute(command -v eza >/dev/null && eza -l --color=always {3} | less -R || ls -lA --color=always {3} | less -R)"

    # Gọi FZF với cửa sổ Preview hiển thị nhanh nội dung thư mục
    set -l fzf_out (printf "%s\n" $list | fzf \
        --prompt="📁 Dir Recent (0-9 nhảy | Ctrl-Space xem chi tiết)> " \
        --delimiter=' │ ' \
        --nth=3 \
        --tiebreak=index \
        --preview="command -v eza >/dev/null && eza -1 --icons --color=always {3} 2>/dev/null || ls -A --color=always {3} 2>/dev/null" \
        --preview-window="bottom:70%" \
        --expect=right,enter \
        --bind="$binds" \
        --layout=reverse \
        --height=100%)

    # Xử lý kết quả trả về
    set -l key $fzf_out[1]
    set -l selected_line $fzf_out[2]

    if test -z "$selected_line"
        return
    end

    # Tách lấy cột đường dẫn
    set -l target_path (echo "$selected_line" | awk -F ' │ ' '{print $3}')

    # Điều hướng hành động
    switch "$key"
        case right
            commandline -i (string escape "$target_path")" "
	    log_recent_dir "$target_path"
	    ~/dwm-flexipatch/dwm_status_update.sh &
        case enter
            cd "$target_path"
    end
    
    # Refresh lại giao diện dòng lệnh
    commandline -f repaint 2>/dev/null
end
