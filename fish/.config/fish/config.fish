fish_add_path $HOME/.cargo/bin $HOME/.local/bin $HOME/.fzf/bin

if status is-interactive
    alias v=nvim
    
    set -g fish_greeting ""
    set -gx fzf_fd_opts --type=d --hidden --follow --exclude=.git --color=always
    
    # Nạp LS_COLORS cho phiên tương tác
    if type -q dircolors
        eval (dircolors -c)
    end
end

function __log_recent_dir --on-variable PWD
    # Tránh kích hoạt log khi đang ở trong subshell hoặc các lệnh thay đổi tạm thời
    if status --is-command-substitution
        return
    end

    # Nếu thư mục hiện tại là $HOME thì bỏ qua không ghi log
    if test "$PWD" = "$HOME"
        return
    end

    # Kiểm tra xem hàm log_recent_dir có đang bận xử lý hay không
    if set -q __is_logging_dir
        return
    end

    # Đặt cờ khóa (Lock) trước khi gọi hàm xử lý
    set -g __is_logging_dir 1

    log_add.sh "$HOME/.cache/dir_recent.log" "$PWD"
    # ~/dwm-flexipatch/dwm_status_update.sh &
    # Xóa cờ khóa sau khi xử lý xong
    set -e __is_logging_dir
end

function log_recent_files --on-event fish_postexec
    # 1. Tách lấy tên lệnh và các tham số
    set -l tokens (string split ' ' $argv[1])
    if test (count $tokens) -eq 0
        return
    end
    set -l cmd $tokens[1]

    # 2. Danh sách các lệnh cần theo dõi
    set -l track_cmds cat bat less more vis nano touch ls eza mkdir
    
    if contains $cmd $track_cmds
        set -l args $tokens[2..-1]
        
        for arg in $args
            # Bỏ qua các option (bắt đầu bằng dấu -)
            if string match -q -- '-*' $arg
                continue
            end

            # Mở rộng dấu ~ thành $HOME
            set -l expanded_arg (string replace -r '^~' $HOME -- $arg)

            # Biến lưu đường dẫn file log đích
            set -l log_file ""
            set -l is_valid 0

            # 3. Phân nhánh kiểm tra và chọn file log
            if test "$cmd" = "mkdir"
                if test -d $expanded_arg
                    set is_valid 1
                    set log_file "$HOME/.cache/dir_recent.log"
                end
            else
                if test -f $expanded_arg
                    set is_valid 1
                    set log_file "$HOME/.cache/nvim_recent.log"
                end
            end

            # 4. Ghi vào file log tương ứng
            if test $is_valid -eq 1
                set -l full_path (realpath -s $expanded_arg)
                set -l timestamp (date +%s)
                
                echo "$timestamp $full_path" >> $log_file
            end
        end        
    end
end
