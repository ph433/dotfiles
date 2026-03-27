#!/bin/bash

# Vòng lặp vô tận để canh chừng
while true; do
    # Lấy layout hiện tại đang chạy trong GUI
    CURRENT_LAYOUT=$(setxkbmap -query | grep layout | awk '{print $2}')

    # Nếu layout KHÔNG PHẢI là "us" (bao gồm cả trường hợp bị dính "et,us")
    if [ "$CURRENT_LAYOUT" != "us" ]; then
        # Chạy lệnh reset thần thánh của bạn
        . /etc/default/keyboard
        setxkbmap -layout "$XKBLAYOUT" -variant "$XKBVARIANT" -option "$XKBOPTIONS"
        
        # Ghi log nhẹ để mình biết nó vừa hoạt động (có thể xóa dòng này)
        # echo "Đã phát hiện layout lạ ($CURRENT_LAYOUT), đã reset về us."
    fi

    # Nghỉ 3 giây rồi kiểm tra tiếp (tránh tốn CPU)
    sleep 3
done