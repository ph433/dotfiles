#!/bin/bash

URL="https://www.youtube.com"
CONFIG_FILE="$HOME/.config/qutebrowser-yt/config.py"

# Bắt buộc mở một cửa sổ mới (-t w) dùng config riêng (-C) 
# nhưng vẫn giữ nguyên thư mục Data/Cookie mặc định
qutebrowser -C "$CONFIG_FILE" --target window "$URL"
