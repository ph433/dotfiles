function log_recent_file -d "Ghi log đường dẫn file vào lịch sử nvim_recent"
    # Lấy tham số đầu tiên truyền vào làm đường dẫn file
    set -l target_file $argv[1]
    
    if test -z "$target_file"
        return 1
    end

    # Chuyển thành đường dẫn tuyệt đối (bỏ qua lỗi nếu có)
    set target_file (realpath "$target_file" 2>/dev/null)

    # Kiểm tra an toàn: Phải có đường dẫn VÀ đường dẫn đó phải là một FILE thực sự tồn tại
    if test -n "$target_file"; and test -f "$target_file"
        set -l timestamp (date +%s)
        set -l log_file "$HOME/.cache/nvim_recent.log"
        
        # Ghi vào file nhật ký
        echo "$timestamp $target_file" >> "$log_file"
    end
end
