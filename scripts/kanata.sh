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
UDEV_SRC="$HOME/dotfiles/kanata/99-kanata.rules"
UDEV_DST="/etc/udev/rules.d/99-kanata.rules"

# Tạo nhóm quyền và thêm user trước
sudo groupadd --force uinput
sudo usermod -aG input $USER
sudo usermod -aG uinput $USER

# Kiểm tra và copy file thật thay vì dùng liên kết mềm (symlink)
if [ -f "$UDEV_SRC" ]; then
    # Copy file quy tắc thật vào thẳng /etc để udev nạp được lúc boot
    sudo cp "$UDEV_SRC" "$UDEV_DST"
else
    echo "    [!] Không tìm thấy $UDEV_SRC, tự động tạo file udev mặc định..."
    echo 'KERNEL=="uinput", GROUP="uinput", MODE="0660", OPTIONS+="static_node=uinput"' | sudo tee "$UDEV_DST" > /dev/null
fi

# Ép hệ thống nạp lại cấu hình udev ngay lập tức
sudo udevadm control --reload-rules && sudo udevadm trigger
echo "   [+] Đã cấu hình xong udev và nhóm quyền."

# 3. STOW - Liên kết file cấu hình config.kbd ra $HOME
echo "--> 3. Liên kết tệp cấu hình config.kbd bằng GNU Stow..."
cd "$HOME/dotfiles"

# Dọn dẹp sạch thư mục cấu hình đích cũ để Stow làm việc chuẩn xác
rm -rf "$HOME/.config/kanata"
mkdir -p "$HOME/.config"

# Dùng stow thường (không cần --adopt vì thư mục đích đã trống)
stow --no-folding -v kanata

# 4. KÍCH HOẠT SERVICE - Chạy ngầm theo User
echo "--> 4. Kích hoạt Kanata Systemd User Service..."
# Reload lại systemd daemon của user để nhận diện service
systemctl --user daemon-reload

# Mẹo nhỏ: Ép systemd chạy service bằng quyền nhóm uinput mới ngay trong phiên này
sg uinput -c "systemctl --user enable --now kanata.service" || systemctl --user enable --now kanata.service

echo "=================================================="
echo " 🎉 CÀI ĐẶT KANATA HOÀN TẤT!"
echo " ⚠️  LƯU Ý: Vì bạn đã reboot trước đó, lần này script sẽ tự kích hoạt service ăn ngay luôn!"
echo "=================================================="
