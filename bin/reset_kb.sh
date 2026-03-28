#!/bin/bash

# 0. Khai báo môi trường để Robot thấy phím
export DISPLAY=:0
export XAUTHORITY=$HOME/.Xauthority

reset_to_us() {
    # 1. Nạp "Hiến pháp" từ hệ thống
    if [ -f /etc/default/keyboard ]; then
        source /etc/default/keyboard
    fi

    # 2. Lấy layout hiện tại
    current_layout=$(setxkbmap -query | grep layout | awk '{print $2}')
    
    # 3. Kiểm tra và vả
    if [ "$current_layout" != "$XKBLAYOUT" ]; then
        echo "--- [$(date +%T)] GNOME VỪA LÀM LOẠN ($current_layout)! ROBOT CHỐT HẠ VỀ $XKBLAYOUT ---"
        setxkbmap -layout "${XKBLAYOUT:-us}" -variant "${XKBVARIANT:-}" -option "${XKBOPTIONS:-}"
    fi
}

# --- GIAI ĐOẠN 1: NHẪN NHỊN (Đợi GNOME load xong) ---
# Mình dùng 10 giây để chắc chắn GNOME và Bộ gõ đã "thức dậy" hoàn toàn

(
    echo "--- [$(date +%T)] Robot đang đợi GNOME múa máy... (10s) ---"
    sleep 15
    reset_to_us
    echo "--- [$(date +%T)] Đã chốt hạ layout lần đầu. Chuyển sang canh gác. ---"
) &

# --- GIAI ĐOẠN 2: CANH GÁC (Lụm kèo mỗi khi cắm rút) ---
# Dùng xinput để bắt thóp GNOME mỗi khi nó định đổi layout do thiết bị mới
xinput test-xi2 --root | grep --line-buffered -E "HierarchyChanged|DeviceChanged" | while read -r line; do
    sleep 2
    reset_to_us
done