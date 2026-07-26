function log_recent_dir -d "Ghi log đường dẫn thư mục vào lịch sử"
    set -l target_dir $argv[1]
    test -z "$target_dir"; and return

    if test -d "$target_dir"
        # 1. Lấy timestamp an toàn (tương thích mọi bản Fish)
        set -l timestamp (date +%s)
        set -l log_file "$HOME/.cache/dir_recent.log"

        # 2. Ghi log
        echo "$timestamp $target_dir" >> "$log_file"
    end
end
