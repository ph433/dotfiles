# 1. Xác định thư mục thật của dotfiles/fzf
DIR="$(dirname "$(readlink -f "$BASH_SOURCE")")"

# 2. Nạp phím tắt từ folder vendor (nằm cùng chỗ với file này)
if [ -d "$DIR/vendor" ]; then
    source "$DIR/vendor/key-bindings.bash"
    source "$DIR/vendor/completion.bash"
fi

# 3. Nạp cấu hình cá nhân
if [ -f "$DIR/fzf.config.bash" ]; then
    source "$DIR/fzf.config.bash"
fi