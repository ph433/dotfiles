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

# Xử lý cho phím mũi tên Phải (Right Arrow)
function _right_or_fzf_recent
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        fzfrecentdir
        commandline -f repaint
    else
        # Hành vi mặc định: di chuyển con trỏ sang phải
        commandline -f forward-char
    end
end

# Xử lý cho phím mũi tên Trái (Left Arrow)
function _left_or_fzf_find
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        fzfrecent
        commandline -f repaint
    else
        # Hành vi mặc định: di chuyển con trỏ sang trái
        commandline -f backward-char
    end
end

# Xử lý cho phím Enter (đã làm ở bước trước)
function _enter_or_fzf_zoxide
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        __fzf_zoxide_custom
        commandline -f repaint
    else
        commandline -f execute
    end
end

function fish_user_key_bindings
    # Gán phím Enter
    bind \r _enter_or_fzf_zoxide
    
    # Gán phím Right (\e[C) và Left (\e[D)
    bind \e\[C _right_or_fzf_recent
    bind \e\[D _left_or_fzf_find
end
