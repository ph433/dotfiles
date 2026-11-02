function log_recent_files --on-event fish_postexec
    # 1. Tách lấy tên lệnh (từ đầu tiên) và các tham số
    set -l tokens (string split ' ' $argv[1])
    if test (count $tokens) -eq 0
        return
    end
    set -l cmd $tokens[1]

    # 2. Danh sách các lệnh cần theo dõi (bạn có thể thêm bớt tùy ý)
    set -l track_cmds cat bat less more vis nano touch code micro ls eza
    
    if contains $cmd $track_cmds
        # Lấy tất cả các tham số (bỏ qua tên lệnh)
        set -l args $tokens[2..-1]
        
        for arg in $args
            # Bỏ qua các option (bắt đầu bằng dấu -)
            if string match -q -- '-*' $arg
                continue
            end
            
            # Nếu file/thư mục tồn tại
            if test -f $arg
                # Lấy full path, giữ nguyên symlink (-s)
                set -l full_path (realpath -s $arg)
                set -l timestamp (date +%s)
                
                # Ghi vào file (thay đổi đường dẫn file log của bạn ở đây)
                echo "$timestamp $full_path" >> ~/.cache/nvim_recent.log
            end
        end
    end
end
