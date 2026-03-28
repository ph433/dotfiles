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

# --- GIAI ĐOẠN 2: BẢN CHỐNG SPAM (LỤM KÈO CHUẨN) ---
xinput test-xi2 --root | grep --line-buffered -E "HierarchyChanged|DeviceChanged" | while read -r line; do
    # Kiểm tra xem có thằng sleep nào của chính script này đang chạy không
    # Nếu CHƯA có thì mới cho phép đẻ thằng mới
    if ! pgrep -f "sleep 2" > /dev/null; then
        (
            sleep 2
            reset_to_us
        ) &
    fi
done