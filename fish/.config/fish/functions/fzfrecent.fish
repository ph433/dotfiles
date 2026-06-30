function fzfrecent -d "Tìm file dựa trên lịch sử mở trong Neovim (Dashboard Top 10)"
    set log_file "$HOME/.cache/nvim_recent.log"

    if not test -f "$log_file"
        echo "Chưa có dữ liệu lịch sử file."
        return 1
    end

    # 1. Sắp xếp lịch sử theo thời gian mới nhất (chưa giới hạn 10)
    set -l sorted_log (awk '{time=$1; sub(/^[0-9]+ /, ""); map[$0]=time} END {for (p in map) print map[p] " " p}' $log_file | sort -nr)
    
    # 2. Lọc lấy tối đa 10 file VẪN CÒN TỒN TẠI trên ổ cứng
    set -l top10
    for entry in $sorted_log
        # Tách lấy phần đường dẫn (bỏ timestamp ở đầu để check path)
        set -l file_path (string replace -r '^[0-9]+ ' '' -- "$entry")
        
        # Nếu file tồn tại thì mới đưa vào mảng top10
        if test -f "$file_path"
            set -a top10 "$entry"
            # Dừng vòng lặp khi đã gom đủ 10 file hợp lệ
            if test (count $top10) -ge 10
                break
            end
        end
    end

    # Thoát nếu tất cả các file trong lịch sử đều đã bị xoá
    if test -z "$top10"
        echo "Không có file nào trong lịch sử còn tồn tại."
        return 1
    end

    # GHI ĐÈ LẠI LOG (Hành động này cũng đóng vai trò tự động dọn rác các đường dẫn đã bị rm)
    printf "%s\n" $top10 > $log_file

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
        
        # Dùng %10s để căn lề phải cột thời gian, giúp chữ số thẳng hàng với nhau
        printf "%d │ %10s │ %s\n", NR-1, ago, $0
    }')

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

    # Gán Ctrl-Space chạy `execute` ngầm. 
    set binds "$binds,ctrl-space:execute(command -v bat >/dev/null && bat --paging=always --color=always {3} || less -R {3})"

    # FZF Menu
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

    # Xử lý output trả về
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
            commandline -i (string escape "$target_path")" "
	    __fzf_score_file "$target_path"
	    log_recent_file "$target_path"
        case enter
            nvim "$target_path"
    end
    
    # Refresh lại dòng lệnh để hiển thị đường dẫn vừa dán ngay lập tức
    commandline -f repaint 2>/dev/null
end
