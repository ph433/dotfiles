#!/bin/sh
log_file="$1"
[ -f "$log_file" ] || exit 1

fzfrecent_feed.sh "$log_file" | fzf \
    -m \
    --prompt="🕒 Nvim Recent> " \
    --delimiter=' │ ' \
    --nth=2,.. \
    --tiebreak=index \
    --preview="bat --color=always {2} 2>/dev/null || cat {2}" \
    --preview-window="bottom:70%:hidden" \
    --expect=right,enter \
    --layout=reverse \
    --bind="ctrl-x:reload(fzfrecent_feed.sh '$log_file' -f)+change-prompt(🕒 Nvim Recent> )+clear-query+first" \
    --bind='insert:reload(scan_dir.sh {2})+change-prompt(📁 Parent Dirs> )+clear-query+first' \
    --bind='alt-d:reload(scan_dir.sh {2})+change-prompt(📁 Sub Dirs> )+clear-query+first' \
    --height=100%
