#!/usr/bin/env bash

set -e
DOTFILES="$HOME/dotfiles"

echo "--------------------------------------------------"
echo "💻 STEP B: THIẾT LẬP VISUAL STUDIO CODE"
echo "--------------------------------------------------"

# --- 1. CÀI ĐẶT VS CODE ---
if ! command -v code >/dev/null 2>&1; then
    echo "🔵 Đang thêm Repo và cài đặt VS Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    sudo apt update && sudo apt install -y code
fi

# --- 2. LIÊN KẾT CẤU HÌNH ---
echo "🔗 Đang liên kết cấu hình (settings.json, keybindings.json)..."
# Xóa config cũ để tránh xung đột Stow
rm -rf "$HOME/.config/Code/User/settings.json" || true
rm -rf "$HOME/.config/Code/User/keybindings.json" || true

cd "$DOTFILES"
stow -Rv vscode

# --- 3. CÀI ĐẶT EXTENSIONS ---
EXT_FILE="$DOTFILES/vscode_extensions.txt"
if [ -f "$EXT_FILE" ]; then
    echo "📦 Đang cài đặt Extensions từ danh sách..."
    while read -r ext; do
        [ -z "$ext" ] && continue
        echo "Installing: $ext"
        code --install-extension "$ext" --force
    done < "$EXT_FILE"
fi

echo "✅ VS Code đã sẵn sàng!"