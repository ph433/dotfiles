#!/bin/bash
HIST_FILE="$HOME/.local/share/qutebrowser/cmd-history"
[ ! -f "$HIST_FILE" ] && exit 1

FLAG_FILE=$(mktemp)

OUTPUT=$(tac "$HIST_FILE" | awk '!seen[$0]++' | fzf \
    --reverse \
    --prompt="Qute History > " \
    --bind "right:execute-silent(echo 'edit' > $FLAG_FILE)+accept" \
    --bind "enter:execute-silent(echo 'run' > $FLAG_FILE)+accept")

ACTION=$(cat "$FLAG_FILE" 2>/dev/null)
rm -f "$FLAG_FILE"

CMD_CLEAN="${OUTPUT#:}"

if [ -n "$CMD_CLEAN" ]; then
    if [ "$ACTION" = "edit" ]; then
        # 1. Ép dwm focus lại vào cửa sổ Qutebrowser ngay lập tức
        xdotool search --onlyvisible --class qutebrowser windowactivate --sync 2>/dev/null

        # 2. Đưa câu lệnh ra thanh ':' với con trỏ ở cuối dòng
        qutebrowser ":set-cmd-text :$CMD_CLEAN "
    elif [ "$ACTION" = "run" ]; then
        qutebrowser ":$CMD_CLEAN"
    fi
fi
