if status is-interactive
    # Các hàm wrapper cho lệnh ngắn (mở app cực nhanh)
    function v --wraps nvim; nvim $argv; end
    function g --wraps git; git $argv; end
    function cat --wraps bat; bat $argv; end
    function ls --wraps eza; eza --icons --group-directories-first $argv; end
    function lt --wraps eza; eza --tree --level=2 --icons --group-directories-first $argv; end
    function find --wraps fd; fd $argv; end

    # Tạo thư mục cache nếu chưa có
    if not test -d ~/.cache/fish
        mkdir -p ~/.cache/fish
    end

    # 1. Zoxide Cache
    if not test -f ~/.cache/fish/zoxide.fish
        zoxide init fish > ~/.cache/fish/zoxide.fish
    end
    source ~/.cache/fish/zoxide.fish

    # # 2. Atuin Cache
    # if not test -f ~/.cache/fish/atuin.fish
    #     atuin init fish > ~/.cache/fish/atuin.fish
    # end
    # # set -q ATUIN_SESSION; or set -gx ATUIN_SESSION (command atuin uuid 2>/dev/null)
    # source ~/.cache/fish/atuin.fish

    # 3. Starship Cache (Tự động sinh code tĩnh nếu lỡ bị xóa)
    if not test -f ~/.cache/fish/starship.fish
        starship init fish --print-full-init > ~/.cache/fish/starship.fish
    end
    source ~/.cache/fish/starship.fish
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

    log_recent_dir "$PWD"
    # ~/dwm-flexipatch/dwm_status_update.sh &
    # Xóa cờ khóa sau khi xử lý xong
    set -e __is_logging_dir
end
