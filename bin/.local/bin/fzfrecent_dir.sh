#!/bin/sh

# Nhánh bóc tách thư mục cha khi bấm insert (thay thế cho sh -c lồng dài dòng)
if [ "$1" = "--parents" ]; then
    d="${2%/}"
    [ -z "$d" ] && d="/"
    while [ "$d" != "/" ] && [ -n "$d" ]; do
        printf "📁 │ %s\n" "$d"
        d="${d%/*}"
        [ -z "$d" ] && d="/"
    done
    printf "📁 │ /\n"
    exit 0
fi

log_file="$1"
[ -f "$log_file" ] || exit 1

fzfrecent_feed.sh "$log_file" | fzf \
    -m \
    --prompt="📁 Dir Recent> " \
    --delimiter=' │ ' \
    --nth=2,.. \
    --tiebreak=index \
    --preview="command -v eza >/dev/null && eza -1 --icons --color=always {2} 2>/dev/null || ls -A --color=always {2} 2>/dev/null" \
    --preview-window="bottom:70%:hidden" \
    --expect=right,enter \
    --layout=reverse \
    --bind="ctrl-x:reload(fzfrecent_feed.sh '$log_file')+change-prompt(📁 Dir Recent> )+clear-query+first" \
    --bind="insert:reload(\"$0\" --parents {2})+change-prompt(📁 Parent Dirs> )+clear-query+first" \
    --bind='alt-d:reload(scan_dir.sh {2})+change-prompt(📁 Sub Dirs> )+clear-query+first' \
    --height=100%
