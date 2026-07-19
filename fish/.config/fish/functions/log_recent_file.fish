function log_recent_file -d "Ghi log đường dẫn file vào lịch sử nvim_recent"
    set -l target_file $argv[1]
    test -z "$target_file"; and return 1

    set target_file (realpath "$target_file" 2>/dev/null)
    if test -n "$target_file"; and test -f "$target_file"
        set -l timestamp (date +%s)
        set -l log_file "$HOME/.cache/nvim_recent.log"
        
        # Tạo một file tạm ẩn trên hệ thống
        set -l tmp_file (mktemp)

        # 1. Ghi mốc thời gian mới nhất lên đầu file tạm
        echo "$timestamp $target_file" > "$tmp_file"

        # 2. Lọc lịch sử cũ và ĐẨY THẲNG vào file tạm (không đưa vào biến Fish)
        if test -f "$log_file"
            grep -v -F "$target_file" "$log_file" >> "$tmp_file" 2>/dev/null
        end

        # 3. Ghi đè file tạm thành file log chính thức (cực nhanh và an toàn)
        mv "$tmp_file" "$log_file"
    end
end
