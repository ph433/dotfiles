fish_add_path -g $HOME/.cargo/bin $HOME/.local/bin $HOME/.fzf/bin

if status is-interactive
    abbr -a v nvim
    
    set -g fish_greeting ""
    set -gx fzf_fd_opts --type=d --hidden --follow --exclude=.git --color=always
    
    type -q zoxide; and zoxide init fish | source
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
