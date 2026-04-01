#!/usr/bin/env bash

# Thoát ngay nếu có lệnh lỗi
set -e

DOTFILES="$HOME/dotfiles"
cd "$DOTFILES"

# --- 0. KHAI BÁO DANH SÁCH PHẦN MỀM ---
PKGS_SYSTEM=(copyq curl fzf gettext)
PKGS_FCITX5=(
    fcitx5 fcitx5-bamboo fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 
    fcitx5-frontend-qt5 kde-config-fcitx5
)

echo "--------------------------------------------------"
echo "🔧 STEP A: THIẾT LẬP HỆ THỐNG CỐT LÕI"
echo "--------------------------------------------------"

# --- 1. CÀI ĐẶT PHẦN MỀM ---
echo "Step 1: Cài đặt phần mềm hệ thống & bộ gõ..."
sudo apt update
sudo apt install -y "${PKGS_SYSTEM[@]}" "${PKGS_FCITX5[@]}"

# --- 2. CẤU HÌNH QUYỀN (KANATA) ---
echo "Step 2: Cấp quyền uinput cho Kanata..."
if [ -d "$DOTFILES/bin" ]; then
    chmod +x "$DOTFILES/bin/"*
fi

sudo groupadd -f uinput
sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"

if [ -f "$DOTFILES/kanata/99-input.rules" ]; then
    sudo cp "$DOTFILES/kanata/99-input.rules" /etc/udev/rules.d/
    sudo udevadm control --reload-rules && sudo udevadm trigger
fi

# --- 3. DỌN DẸP & STOW ---
echo "Step 3: Dọn dẹp và liên kết Dotfiles (Stow)..."
FILES_TO_REMOVE=(
    "$HOME/.bashrc"
    "$HOME/.bash_aliases"
    "$HOME/.xprofile"

    "$HOME/.config/fcitx5/profile"
    "$HOME/.config/copyq"
)

for item in "${FILES_TO_REMOVE[@]}"; do rm -rf "$item" || true; done

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.config/kanata"
mkdir -p "$HOME/.config/fcitx5"
mkdir -p "$HOME/.config/copyq"

stow -Rv fzf kanata fcitx5 copyq bash services

# --- 4. KÍCH HOẠT DỊCH VỤ ---
echo "Step 4: Kích hoạt dịch vụ hệ thống..."
systemctl --user daemon-reload
systemctl --user enable --now kanata.service
systemctl --user enable --now reset-kb.service

# STEP 5: KÍCH HOẠT HỆ THỐNG (LẦN ĐẦU)
echo "Step 5: Đang kích hoạt Fcitx5 và CopyQ để tự sinh cấu hình..."

(
    sleep 3
    fcitx5 -rd
    copyq
) &

echo "--------------------------------------------------"
echo "✅ TẤT CẢ ĐÃ HOÀN TẤT!"
echo "🚀 Mẹo: Bạn có thể bắt đầu gõ tiếng Việt và dùng Clipboard ngay bây giờ."
echo "⚠️  Lưu ý: Hãy Restart máy một lần để các biến môi trường (.xprofile) có hiệu lực toàn diện."
echo "--------------------------------------------------"