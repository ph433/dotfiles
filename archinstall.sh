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
    firefox \
    yt-dlp

SUCKLESS_DIR="$HOME/.config/suckless"
DWM_DIR="$HOME/dwm-flexipatch"
REPOS=("dmenu" "st")
PACKAGES=("alacritty" "fish" "nvim" "suckless" "dwm_custom" "flameshot" "copyq" "env" "eza" "fcitx5" "mpv" "delta" "services" "kanata")

mkdir -p "$SUCKLESS_DIR"
cd "$SUCKLESS_DIR" && git clone --depth 1 https://git.suckless.org/dmenu && git clone --depth 1 https://git.suckless.org/slstatus

if [ ! -d "$DWM_DIR" ]; then
    echo "--> Tiến hành Shallow Clone dwm-flexipatch"
    git clone --depth 1 https://github.com/bakkeby/dwm-flexipatch.git "$DWM_DIR"
else
    echo "--> [!] Thư mục dwm-flexipatch đã tồn tại, bỏ qua bước clone."
fi

#STOW
cd $HOME/dotfiles

for pkg in "${PACKAGES[@]}"; do
        stow --adopt --no-folding -v "$pkg"
done

cd $HOME/dotfiles
rm -f $HOME/.config/atuin/themes/mycolor.toml $HOME/.config/atuin/config.toml && stow --no-folding -v atuin

cd $HOME/dotfiles
git restore .

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
