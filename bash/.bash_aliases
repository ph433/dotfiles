# --- Keyboard & Kanata ---
# k: Thêm lệnh xóa sạch cấu hình layout của GUI trước khi nạp file hệ thống
alias k='source /etc/default/keyboard && setxkbmap -layout "$XKBLAYOUT" -variant "$XKBVARIANT" -option "$XKBOPTIONS"'
alias kk='sudo udevadm trigger --subsystem-match=input --action=change'
# knt: Kanata Restart (giữ nguyên của bạn nhưng thêm sudo nếu cần)
alias knt='systemctl --user restart kanata'

# klog: Xem log của Kanata ngay lập tức (Để debug xem tại sao Caps thành Backspace)
alias klog='journalctl --user -u kanata -f'

# --- Tiện ích Hệ thống ---
# w: Nâng cấp watch để highlight những chỗ thay đổi (rất phê khi soi layout)
alias w='watch -d -n 0.5'

# up: Thêm dọn dẹp rác tự động sau khi nâng cấp
alias up='sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y'

# cls: Xóa sạch màn hình và reset terminal (Hữu ích khi terminal bị loạn phím)
alias cls='clear && reset'

# --- Dotfiles & Navigation ---
alias dots='cd ~/dotfiles'
alias reload='source ~/.bashrc && echo "🚀 Bashrc reloaded!"'

# --- Tìm kiếm nhanh (Cực kỳ an tâm) ---
# q: Truy tìm nhanh xem "thằng" nào đang điều khiển phím nào
alias q='setxkbmap -query'
alias qg='gsettings get org.gnome.libgnomekbd.keyboard layouts'