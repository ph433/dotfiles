function _fzfrecent_format_list -d "Định dạng danh sách 0-9 kèm relative time cho FZF"
    set -l top10 $argv
    test -n "$top10"; or return 1

    set -l current_time (date +%s)
    printf "%s\n" $top10 | awk -v now="$current_time" '{
        time=$1; 
        
        # Lấy phần đường dẫn file bằng cách loại bỏ timestamp ở đầu
        path = $0;
        sub(/^[0-9]+ /, "", path); 
        
        diff = now - time;
        if (diff < 0) diff = 0;
        
        if (diff < 60) { raw_ago = diff "s ago" }
        else if (diff < 3600) { raw_ago = int(diff/60) "m ago" }
        else if (diff < 86400) { raw_ago = int(diff/3600) "h ago" }
        else if (diff < 604800) { raw_ago = int(diff/86400) "d ago" }
        else if (diff < 2592000) { raw_ago = int(diff/604800) "w ago" }
        else if (diff < 31536000) { raw_ago = int(diff/2592000) "mo ago" }
        else { raw_ago = int(diff/31536000) "y ago" }
        
        # Căn lề phải độ rộng 8 ký tự cho chuỗi chưa có màu (gọn đẹp hơn %10s)
        ago = sprintf("%8s", raw_ago);

        # Nếu muốn bọc màu ANSI (ví dụ: màu xám tối \033[1;30m), bọc SAU KHI đã sprintf:
        # ago = "\033[1;30m" ago "\033[0m";

        printf "%s │ %s\n", ago, path
    }'
end
