#!/bin/sh

# 1. Đọc thư mục: Xóa dãy số timestamp ở đầu dòng, sau đó rút gọn /home/user thành ~
if [ -s ~/.cache/dir_recent.log ]; then
    RECENT_DIR=$(tail -n 1 ~/.cache/dir_recent.log | sed 's/^[0-9]* *//' | sed "s|^$HOME|~|")
fi

# 2. Đọc file: Sắp xếp lấy mới nhất, xóa dãy số timestamp ở đầu dòng, rút gọn /home/user thành ~
if [ -s ~/.cache/nvim_recent.log ]; then
    RECENT_FILE=$(sort -rn ~/.cache/nvim_recent.log | head -n 1 | sed 's/^[0-9]* *//' | sed "s|^$HOME|~|")
fi

# 3. Xuất ra bar. Đã thêm KHOẢNG TRẮNG ở tận cùng sau \x01 để tách biệt với CPU
/usr/bin/echo -e "\x15    $RECENT_DIR \x16 󰈔  $RECENT_FILE\x01" > /tmp/dwm_bar
