if status is-interactive
    # Các hàm wrapper cho lệnh ngắn (mở app cực nhanh)
    function v --wraps nvim; nvim $argv; end
    function g --wraps git; git $argv; end
    function cat --wraps bat; bat $argv; end
    function ls --wraps eza; eza --icons --group-directories-first $argv; end
    function lt --wraps eza; eza --tree --level=2 --icons --group-directories-first $argv; end
    function find --wraps fd; fd $argv; end
    # abbr -a debug_vars --position anywhere 'for _v in (set -l | string match -rv \'^(_.*|argv)$\' | string replace -r \'\s.*$\' \'\'); set -l _sc (set -S $_v 2>/dev/null | string match -m1 \'*scope*\' | string replace -r \'^[^:]*:\s*\' \'\' | string replace -a "\x27" ""); set -l _c (count $$_v); set -l _t "List ($_c elements)"; set -l _f ""; if test $_c -eq 0; set _t "Empty"; set _f "(empty)"; else if test $_c -eq 1; set _t "String / Single"; set _f (string trim -c "\x27\x22" -- "$$_v"); else; set -l _i 1; set -l _parts; for _it in $$_v; set -l _clean (string trim -c "\x27\x22" -- "$_it"); if string match -q "*|*" -- "$_clean"; set -l _split (string split -m1 "|" -- "$_clean"); set -l _tm (string trim -- "$_split[1]"); set -l _pt (string trim -l -- "$_split[2]"); set -a _parts (printf "\\033[0;33m[%2d]\\033[0m  %8s | %s" $_i "$_tm" "$_pt"); else; set -a _parts (printf "\\033[0;33m[%2d]\\033[0m  %s" $_i "$_clean"); end; set _i (math $_i + 1); end; set _f (string join \'\\n\' -- $_parts); end; printf "%s\t%s\t%s\t%s\t%s\n" "$_v" "$_sc" "$_t" "$_c" "$_f"; end | fzf --delimiter=\'\t\' --with-nth=1 --ansi --preview=\'printf "\\033[1;36mVariable:\\033[0m \\\$%s\\n\\033[1;35mScope:\\033[0m    %s\\n\\033[1;34mType:\\033[0m     %s\\n\\033[1;33mLength:\\033[0m   %s\\n\\n\\033[1;32mValue:\\033[0m\\n%b\\n" {1} {2} {3} {4} {5}\' --preview-window=\'right:65%:wrap\' --prompt="Local Vars > "'
    abbr -a debug_vars --position anywhere 'eval (string collect < ~/.config/fish/functions/__debug_vars.fish)'
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
