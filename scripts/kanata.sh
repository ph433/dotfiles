#!/bin/bash

# Thoát script ngay lập tức nếu có bất kỳ lệnh nào bị lỗi
set -e

echo "=================================================="
echo "    BẮT ĐẦU CÀI ĐẶT VÀ CẤU HÌNH KANATA"
echo "=================================================="

# 1. Cài đặt Kanata từ AUR (Bản tiền biên dịch -bin cho nhanh)
if ! command -v kanata &> /dev/null; then
    echo "--> 1. Đang tải và cài đặt kanata-bin từ AUR..."
    CD_BAK=$(pwd)
    cd /tmp
    
    # Clone và build gói AUR thủ công
    git clone --depth 1 https://aur.archlinux.org/kanata-bin.git
    cd kanata-bin
    makepkg -si --noconfirm
    
    # Quay lại thư mục ban đầu
    cd "$CD_BAK"
else
    echo "--> [!] Kanata đã được cài đặt trên hệ thống."
fi

# 2. Cấu hình Udev Rules (Cấp quyền đọc bàn phím)
echo "--> 2. Thiết lập quy tắc udev cấp quyền hệ thống..."
UDEV_SRC="$HOME/dotfiles/kanata/99-input.rules"
UDEV_DST="/etc/udev/rules.d/99-input.rules"

if [ -f "$UDEV_SRC" ]; then
    # Tạo liên kết mềm tuyệt đối từ dotfiles vào thẳng /etc
    sudo ln -sf "$UDEV_SRC" "$UDEV_DST"
    
    # Ép hệ thống nạp lại cấu hình udev ngay lập tức
    sudo udevadm control --reload-rules && sudo udevadm trigger
    
    # Thêm user vào các nhóm quyền cần thiết (input, uinput)
    sudo groupadd --force uinput
    sudo usermod -aG input $USER
    sudo usermod -aG uinput $USER
    echo "   [+] Đã cấu hình xong udev và nhóm quyền."
else
    echo "   [!] Cảnh báo: Không tìm thấy file $UDEV_SRC để liên kết!"
fi

# 3. STOW - Liên kết file cấu hình config.kbd ra $HOME
echo "--> 3. Liên kết tệp cấu hình config.kbd bằng GNU Stow..."
cd "$HOME/dotfiles"

# Xóa file trùng cũ ngoài $HOME nếu có trước khi Stow (Giống cách làm với Atuin)
rm -f "$HOME/.config/kanata/config.kbd"

# Stow tự tạo thư mục thật ngoài $HOME/.config/kanata và thả symlink vào
stow --no-folding -v kanata

# 4. KÍCH HOẠT SERVICE - Chạy ngầm theo User
echo "--> 4. Kích hoạt Kanata Systemd User Service..."
# Reload lại systemd daemon của user để nó nhận diện service từ kanata-bin
systemctl --user daemon-reload
systemctl --user enable --now kanata.service

echo "=================================================="
echo " 🎉 CÀI ĐẶT KANATA HOÀN TẤT!"
echo " ⚠️  LƯU Ý: Hãy Log out hoặc khởi động lại máy để quyền uinput ăn vào User nhé."
echo "=================================================="
