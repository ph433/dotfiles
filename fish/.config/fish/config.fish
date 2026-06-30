if status is-interactive
    # --- Biệt danh (Aliases & Abbreviations) ---
    alias cat="bat"
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -lah --icons --group-directories-first"
    alias lt="eza --tree --level=2 --icons --group-directories-first"
    # alias lta="eza --tree --level=2 --icons --group-directories-first -a --color=always"
    
    # alias grep="rg"
    alias find="fd"
    alias g="git"
    alias v="nvim"

    # --- Khởi tạo ứng dụng (App Inits) ---
    zoxide init fish | source
    atuin init fish | source
    starship init fish | source
end

function __log_recent_dir --on-variable PWD
    # Tránh kích hoạt log khi đang ở trong subshell hoặc các lệnh thay đổi tạm thời
    if status --is-command-substitution
        return
    end

    # Kiểm tra xem hàm log_recent_dir có đang bận xử lý hay không
    if set -q __is_logging_dir
        return
    end

    # Đặt cờ khóa (Lock) trước khi gọi hàm xử lý
    set -g __is_logging_dir 1

    log_recent_dir

    # Xóa cờ khóa sau khi xử lý xong
    set -e __is_logging_dir
end

