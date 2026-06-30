function log_recent_dir -d "Ghi log đường dẫn thư mục vào lịch sử"
    # Lấy tham số đầu tiên truyền vào làm đường dẫn
    set -l target_dir $argv[1]
    
    # Nếu không truyền tham số nào, tự động lấy thư mục hiện tại (PWD)
    if test -z "$target_dir"
        set target_dir $PWD
    end

    # Chuyển thành đường dẫn tuyệt đối (bỏ qua lỗi nếu có)
    set target_dir (realpath "$target_dir" 2>/dev/null)

    # Kiểm tra: Phải có đường dẫn VÀ đường dẫn đó phải là một thư mục tồn tại
    if test -n "$target_dir"; and test -d "$target_dir"
        set -l timestamp (date +%s)
        set -l log_file "$HOME/.cache/dir_recent.log"
        
        # Ghi vào file
        echo "$timestamp $target_dir" >> "$log_file"
    end
end
