#!/bin/bash
HIST_FILE="$HOME/.local/share/qutebrowser/cmd-history"
[ ! -f "$HIST_FILE" ] && exit 1

FLAG_FILE=$(mktemp)

# Chạy fzf với --print-query để vừa lọc vừa lấy nội dung đang nhập/chọn
# - Enter: Chạy lệnh đang chọn hoặc câu lệnh vừa sửa trên ô tìm kiếm
# - Phím Phải (Right): Dán câu lệnh hiện tại lên thanh tìm kiếm để tiếp tục sửa
OUTPUT=$(tac "$HIST_FILE" | awk '!seen[$0]++' | fzf \
    --reverse \
    --print-query \
    --prompt="Qute History > " \
    --bind "right:replace-query" \
    --bind "enter:execute-silent(echo 'run' > '$FLAG_FILE')+accept")

ACTION=$(cat "$FLAG_FILE" 2>/dev/null)
rm -f "$FLAG_FILE"

# Dòng 1 của OUTPUT từ --print-query chứa nội dung trong ô tìm kiếm (chuỗi đã sửa/nhập)
# Dòng 2 chứa item được highlight từ danh sách bên dưới
QUERY_TEXT=$(echo "$OUTPUT" | head -n 1)
SELECTED_TEXT=$(echo "$OUTPUT" | sed -n '2p')

# Ưu tiên lấy chuỗi do bạn chủ động sửa/gõ (QUERY_TEXT), nếu trống mới dùng SELECTED_TEXT
RAW_CMD="${QUERY_TEXT:-$SELECTED_TEXT}"

# Xóa dấu ':' ở đầu nếu có
CMD_CLEAN="${RAW_CMD#:}"

if [ -n "$CMD_CLEAN" ] && [ "$ACTION" = "run" ]; then
    # 1. Chuyển focus lại window Qutebrowser
    xdotool search --onlyvisible --class qutebrowser windowactivate --sync 2>/dev/null

    # 2. Gửi lệnh thực thi tới Qutebrowser
    qutebrowser ":$CMD_CLEAN"
fi
