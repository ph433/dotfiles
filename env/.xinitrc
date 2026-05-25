# --- Các cấu hình chạy ngầm làm nền ---
xinput set-prop "FTCS0038:00 2808:0106 Touchpad" "libinput Tapping Enabled" 1 &
#feh --bg-scale ~/Pictures/wallpaper.jpg &

# --- KHỞI ĐỘNG CÁC ỨNG DỤNG CHẠY NGẦM HỆ THỐNG ---
# 1. Bật bộ gõ tiếng Việt Fcitx5
fcitx5 -d &

# 2. Bật quản lý Clipboard CopyQ
copyq &

# 3. Bật công cụ chụp màn hình Flameshot
flameshot &

# --- Chọn Window Manager để quẩy ở đây ---

exec dwm       # Nếu muốn vào dwm
# exec i3      # Nếu muốn vào i3 (bỏ dấu # ở đầu để kích hoạt)
# exec cinnamon-session # Nếu muốn vào Cinnamon
