#!/usr/bin/env bash

# Thoát ngay nếu có lệnh lỗi
set -e

DOTFILES="$HOME/dotfiles"
cd "$DOTFILES"

# --- 0. KHAI BÁO DANH SÁCH PHẦN MỀM ---
PKGS_SYSTEM=(
    stow fzf copyq flameshot curl git gettext
)

PKGS_FCITX5=(
    fcitx5 fcitx5-bamboo fcitx5-frontend-gtk2 fcitx5-frontend-gtk3 
    fcitx5-frontend-qt5 kde-config-fcitx5
)

echo "--------------------------------------------------"
echo "🔧 BẮT ĐẦU THIẾT LẬP HỆ THỐNG TỪ DOTFILES"
echo "--------------------------------------------------"

# --- 1. KHU VỰC CÀI ĐẶT (INSTALLATION) ---
echo "Step 1: Chuẩn bị nguồn và cài đặt phần mềm..."

# Chuẩn bị cho VS Code (Thêm repo trước khi update)
if ! command -v code >/dev/null 2>&1; then
    echo "🔵 Đang chuẩn bị nguồn cho VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
fi

# Một lần update duy nhất cho tất cả
sudo apt update
sudo apt install -y "${PKGS_SYSTEM[@]}" "${PKGS_FCITX5[@]}" code

# Đồng bộ VS Code Extensions
EXT_FILE="$DOTFILES/vscode_extensions.txt"
if [ -f "$EXT_FILE" ]; then
    echo "📦 Đang cài đặt VS Code extensions..."
    cat "$EXT_FILE" | xargs -L 1 code --install-extension
fi

# --- 2. CẤU HÌNH QUYỀN & THIẾT BỊ ---
echo "Step 2: Cấp quyền thực thi và cấu hình udev..."

# Cấp quyền cho bin trong dotfiles (Để gọi lệnh trực tiếp)
if [ -d "$DOTFILES/bin" ]; then
    chmod +x "$DOTFILES/bin/"*
fi

# Quyền cho Kanata
sudo groupadd -f uinput
sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"

if [ -f "$DOTFILES/kanata/99-input.rules" ]; then
    sudo cp "$DOTFILES/kanata/99-input.rules" /etc/udev/rules.d/
    sudo udevadm control --reload-rules
    sudo udevadm trigger
fi

# --- 3. DỌN DẸP & LIÊN KẾT (STOW) ---
echo "Step 3: Dọn dẹp và chạy GNU Stow..."

# Xóa file/folder cũ để tránh xung đột với Symlink
FILES_TO_REMOVE=(
    "$HOME/.bashrc"
    "$HOME/.bash_aliases"
    "$HOME/.xprofile"
    "$HOME/.config/fcitx5"
    "$HOME/.config/autostart"
    "$HOME/.config/Code/User/settings.json"
    "$HOME/.config/Code/User/keybindings.json"
)
for item in "${FILES_TO_REMOVE[@]}"; do rm -rf "$item"; done

# Đảm bảo thư mục cha tồn tại
mkdir -p "$HOME/.config"

# Chạy Stow (Hãy đảm bảo cấu trúc thư mục trong dotfiles đã khớp)
cd "$DOTFILES"
stow -Rv fzf
stow -Rv kanata
stow -Rv fcitx5
stow -Rv autostart
stow -Rv vscode
stow -Rv bash
# stow -Rv vscode (Nếu bạn đã đưa settings.json vào dotfiles)

# --- 4. KÍCH HOẠT DỊCH VỤ & AUTOSTART ---
echo "Step 4: Kích hoạt dịch vụ và ứng dụng khởi động..."

# Kanata service
systemctl --user daemon-reload
systemctl --user enable --now kanata.service
systemctl --user enable --now reset-kb.service

echo "--------------------------------------------------"
echo "✅ HOÀN TẤT! Mọi thứ đã sẵn sàng."
echo "⚠️  LƯU Ý: Bạn CẦN RESTART máy để quyền uinput và bộ gõ có hiệu lực."
echo "--------------------------------------------------"