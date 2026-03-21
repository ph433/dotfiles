#!/usr/bin/env bash

echo "🚀 Bắt đầu thiết lập Kanata (User Mode) từ Dotfiles..."

# --- 1. THIẾT LẬP QUYỀN THIẾT BỊ (Cần sudo 1 lần duy nhất) ---
echo "1. Đang cấu hình quyền truy cập thiết bị..."
sudo groupadd -f uinput
sudo usermod -aG input "$USER"
sudo usermod -aG uinput "$USER"

# Quan trọng: Cần udev rules để User có quyền đọc/ghi vào phím mà không cần sudo
# Giả sử file này bạn để ở: ~/dotfiles/kanata/99-input.rules
sudo ln -sf "$HOME/dotfiles/kanata/99-input.rules" /etc/udev/rules.d/99-input.rules

# --- 2. TẠO CẤU TRÚC THƯ MỤC "VỎ" (Để Stow không link nguyên khối) ---
echo "2. Đang tạo các thư mục cấu hình..."
mkdir -p ~/.config/kanata
mkdir -p ~/.config/systemd/user

# --- 3. LIÊN KẾT (STOW) ---
echo "3. Đang liên kết cấu hình bằng Stow..."
chmod +x "$HOME/dotfiles/bin/kanata"
cd "$HOME/dotfiles"
stow -R kanata  # Dùng -R (Restow) để làm mới các link cũ nếu có

# --- 4. KÍCH HOẠT DỊCH VỤ (USER MODE - KHÔNG SUDO) ---
echo "4. Đang thiết lập Systemd User Service..."

# Nạp lại danh sách service của User
systemctl --user daemon-reload

# Kích hoạt và chạy ngay lập tức
systemctl --user enable --now kanata.service

echo "--------------------------------------------------"
echo "✅ Thiết lập hoàn tất!"
echo "👉 Từ giờ hãy dùng lệnh: systemctl --user restart kanata"
echo "⚠️  LƯU Ý: Nếu đây là lần đầu, bạn PHẢI Restart máy để quyền nhóm có hiệu lực."
echo "--------------------------------------------------"