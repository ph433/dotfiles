#!/bin/bash

# Thoát script ngay lập tức nếu có bất kỳ lệnh nào bị lỗi
set -e

echo "=================================================="
echo "   BẮT ĐẦU CÀI ĐẶT TỰ ĐỘNG ARCH LINUX + DWM"
echo "=================================================="

sudo pacman -Syu --noconfirm \
    xorg-server \
    xorg-xinit \
    base-devel \
    git \
    libx11 \
    libxinerama \
    libxft \
    imlib2 \
    stow \
    alacritty \
    eza \
    fd \
    ripgrep \
    bat \
    fish \
    zoxide \
    atuin \
    neovim \
    starship \
    yazi \
    flameshot \
    copyq \
    tree \
    fzf \
    git-delta \
    mpv \
    yt-dlp

SUCKLESS_DIR="$HOME/.config/suckless"
DWM_DIR="$HOME/dwm-flexipatch"
REPOS=("dmenu" "st")
PACKAGES=("alacritty" "fish" "nvim" "suckless" "dwm_custom" "flameshot" "copyq" "env" "eza" "fcitx5" "mpv" "delta" "service" "kanata")

mkdir -p "$SUCKLESS_DIR"
cd "$SUCKLESS_DIR"

for repo in "${REPOS[@]}"; do
    if [ -d "$repo" ]; then
        echo "   [!] Thư mục $repo đã tồn tại"
    else
        echo "   [+] Đang clone $repo từ suckless.org..."
        git clone --depth 1 "https://git.suckless.org/$repo"
    fi
done

if [ ! -d "$DWM_DIR" ]; then
    echo "--> Tiến hành Shallow Clone dwm-flexipatch"
    git clone --depth 1 https://github.com/bakkeby/dwm-flexipatch.git "$DWM_DIR"
else
    echo "--> [!] Thư mục dwm-flexipatch đã tồn tại, bỏ qua bước clone."
fi

#STOW
cd $HOME/dotfiles


echo "--> Bắt đầu liên kết dotfiles với --no-folding..."

for pkg in "${PACKAGES[@]}"; do
    if [ -d "$pkg" ]; then
        # Tự động tìm và xóa file lẻ trùng ngoài $HOME để tránh bị xung đột (nếu có)
        stow -n -v "$pkg" 2>&1 | grep "conflict" | awk '{print $NF}' | while read -r conflicted_file; do
            TARGET_PATH="$HOME/$conflicted_file"
            if [ -e "$TARGET_PATH" ] || [ -L "$TARGET_PATH" ]; then
                rm -rf "$TARGET_PATH"
            fi
        done
        
        # Stow tự tạo thư mục thật và link file lẻ, không cần mkdir trước
        stow --no-folding -v "$pkg"
    fi
done

cd $HOME/dotfiles
rm -f $HOME/.config/atuin/themes/mycolor.toml $HOME/.config/atuin/config.toml && stow --no-folding -v atuin

cd "$SUCKLESS_DIR"
for repo in "${REPOS[@]}"; do
    cd "$repo"
    sudo make clean install
    cd "$SUCKLESS_DIR"
done

cd "$DWM_DIR" && sudo make clean install && cd "$HOME"

bash "$HOME/dotfiles/scripts/kanata.sh"
bash "$HOME/dotfiles/scripts/setup_fonts.sh"

echo "=================================================="
echo " 🎉 CÀI ĐẶT HOÀN TẤT!"
echo "=================================================="
