#!/bin/bash

# Tạo thư mục chứa font nếu chưa có
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

echo " đang tải JetBrainsMono Nerd Font..."

# Tải bản nén từ GitHub
curl -L https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz -o /tmp/JetBrainsMono.tar.xz

# Giải nén thẳng vào thư mục font
tar -xvf /tmp/JetBrainsMono.tar.xz -C "$FONT_DIR"

# Dọn dẹp file tạm và cập nhật cache hệ thống
rm /tmp/JetBrainsMono.tar.xz
fc-cache -fv

echo " Cài đặt Font thành công!"
