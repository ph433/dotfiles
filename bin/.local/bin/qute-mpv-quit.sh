#!/bin/bash
# Khởi chạy MPV ở background
setsid mpv "$1" >/dev/null 2>&1 &
# Đợi 0.1s đảm bảo mpv đã nhận URL rồi mới đóng Qutebrowser
sleep 0.1
qutebrowser ":quit"
