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

# Xử lý cho phím Home
function _home_or_fzf_search_dir
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        __fzf_find_files_custom
        commandline -f repaint
    else
        commandline -f beginning-of-line
    end
end

# Xử lý cho phím End
function _end_or_fzf_find
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        __fzf_search_directory_custom
        commandline -f repaint
    else
        commandline -f end-of-line
    end
end

# Xử lý cho phím Space (Khoảng trắng)
function _space_or_fzf_recent
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        __fzf_file_recent
        commandline -f repaint
    else
        # Thêm dấu cách bình thường nếu dòng lệnh đang có chữ
        commandline -i ' '
    end
end

# Xử lý cho phím Esc
function _esc_or_become_ll
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        # Thay thế dòng lệnh bằng 'll' và thực thi ngay lập tức
        commandline -r 'll'
        commandline -f execute
    else
        # Nếu dòng lệnh đang có chữ, giữ nguyên hành vi hủy/thoát mặc định của Esc
        commandline -f cancel
    end
end


# Xử lý cho phím Esc
function _esc_or_become_lta
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        # Thay thế dòng lệnh bằng 'll' và thực thi ngay lập tức
        commandline -r 'lta'
        commandline -f execute
    else
        # Nếu dòng lệnh đang có chữ, giữ nguyên hành vi hủy/thoát mặc định của Esc
        commandline -f cancel
    end
end

# Xử lý nâng cao cho Backspace (hoặc Ctrl+Z)
function _backspace_toggle_home
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        # Kiểm tra xem thư mục hiện tại có phải là Home hay không
        if test "$PWD" = "$HOME"
            # Nếu đang ở Home, quay lại thư mục trước đó (tương đương cd -)
            cd -
        else
            # Nếu đang ở thư mục khác, đi về Home
            cd ~
        end
        commandline -f repaint
    else
        # Nếu đang có chữ, xóa ký tự như bình thường
        commandline -f backward-delete-char
    end
end

function fish_user_key_bindings
    bind \r _enter_or_fzf_zoxide
    bind \e\[C _right_or_fzf_recent
    bind \e\[D _left_or_fzf_find
    bind \e\[H _home_or_fzf_search_dir
    bind \e\[F _end_or_fzf_find
    bind ' ' _space_or_fzf_recent
    bind \e _esc_or_become_ll
    bind \x7f _backspace_toggle_home
    bind \e\[3~ _esc_or_become_lta
end
