#!/bin/bash
HIST_FILE="$HOME/.local/share/qutebrowser/cmd-history"
[ ! -f "$HIST_FILE" ] && exit 1

FLAG_FILE=$(mktemp)

OUTPUT=$(tac "$HIST_FILE" | awk '!seen[$0]++' | fzf \
    --reverse \
    --print-query \
    --prompt="Qute History > " \
    --bind "right:replace-query" \
    --bind "enter:execute-silent(echo 'run_selected' > '$FLAG_FILE')+accept" \
    --bind "insert:execute-silent(echo 'run_query' > '$FLAG_FILE')+accept")

ACTION=$(cat "$FLAG_FILE" 2>/dev/null)
rm -f "$FLAG_FILE"

QUERY_TEXT=$(echo "$OUTPUT" | head -n 1)
SELECTED_TEXT=$(echo "$OUTPUT" | sed -n '2p')

if [ "$ACTION" = "run_query" ]; then
    RAW_CMD="$QUERY_TEXT"
elif [ "$ACTION" = "run_selected" ]; then
    RAW_CMD="${SELECTED_TEXT:-$QUERY_TEXT}"
fi

CMD_CLEAN="${RAW_CMD#:}"

if [ -n "$CMD_CLEAN" ] && [ -n "$ACTION" ]; then
    # 1. Tự động ghi lệnh vừa chạy vào cuối file history (đảm bảo luôn có dấu : ở đầu)
    echo ":$CMD_CLEAN" >> "$HIST_FILE"

    # 2. Focus lại cửa sổ Qutebrowser
    xdotool search --onlyvisible --class qutebrowser windowactivate --sync 2>/dev/null

    # 3. Kích hoạt lệnh
    qutebrowser ":$CMD_CLEAN"
fi
