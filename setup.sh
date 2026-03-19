#!/usr/bin/env bash

# 1. Cấp quyền chạy cho file kanata
chmod +x ~/dotfiles/bin/kanata

# 2. Dùng Stow để liên kết cấu hình phím
stow kanata

# 3. Tạo liên kết file Service vào hệ thống
sudo ln -sf ~/dotfiles/kanata/systemd/kanata.service /etc/systemd/system/kanata.service

# 4. Kích hoạt dịch vụ
sudo systemctl daemon-reload
sudo systemctl enable --now kanata.service

echo "✅ Đã xong! Kanata đã sẵn sàng phục vụ."
