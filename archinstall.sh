#!/bin/bash

# Thoát script ngay lập tức nếu có bất kỳ lệnh nào bị lỗi
set -e

echo "=================================================="
echo "   BẮT ĐẦU CÀI ĐẶT TỰ ĐỘNG ARCH LINUX + DWM"
echo "=================================================="

SUCKLESS_DIR="$HOME/.suckless"
DWM_DIR="$HOME/dwm-flexipatch"
PACKAGES=("alacritty" "fish" "nvim" "suckless" "dwm_custom" "flameshot" "copyq" "env" "eza" "fcitx5" "mpv" "delta" "services" "kanata" "starship")

mkdir -p "$SUCKLESS_DIR"
cd "$SUCKLESS_DIR" && git clone --depth 1 https://git.suckless.org/dmenu && git clone --depth 1 https://git.suckless.org/slstatus
git clone --depth 1 https://github.com/bakkeby/dwm-flexipatch.git "$DWM_DIR"

#STOW
cd $HOME/dotfiles

for pkg in "${PACKAGES[@]}"; do
        stow --adopt --no-folding -v "$pkg"
done

cd $HOME/dotfiles
rm -f $HOME/.config/atuin/themes/mycolor.toml $HOME/.config/atuin/config.toml && stow --no-folding -v atuin

cd $HOME/dotfiles
git restore .

cd "$SUCKLESS_DIR/dmenu" && sudo make clean install
cd "$SUCKLESS_DIR/slstatus" && sudo make clean install
cd "$DWM_DIR" && sudo make clean install && cd "$HOME"

bash "$HOME/dotfiles/scripts/kanata.sh"
bash "$HOME/dotfiles/scripts/setup_fonts.sh"

chsh -s /usr/bin/fish

mkdir -p $HOME/Pictures

echo "=================================================="
echo " 🎉 CÀI ĐẶT HOÀN TẤT!"
echo "=================================================="
