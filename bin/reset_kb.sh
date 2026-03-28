#!/bin/bash

# Khai báo để Robot nhìn thấy màn hình
export DISPLAY=:0
export XAUTHORITY=$HOME/.Xauthority

reset_to_us() {
    # Kiểm tra thực tế bằng xkb
    layout=$(setxkbmap -query | grep layout | awk '{print $2}')
    
    if [ "$layout" != "us" ]; then
        echo "--- [$(date +%H:%M:%S)] PHÁT HIỆN LAYOUT $layout! Đang vả về US ---"
        setxkbmap us
        # Thêm các lệnh reset phím khác của bạn vào đây
    fi
}

# Chạy lần đầu khi vừa mở Robot
reset_to_us

# Dùng chính cái lệnh đang chạy ngon ở Terminal bên phải của bạn
xinput test-xi2 --root | grep --line-buffered -E "HierarchyChanged|DeviceChanged" | while read -r line; do
    # Đợi 0.5s cho hệ thống nạp xong phím rồi mới check
    sleep 0.5
    reset_to_us
done