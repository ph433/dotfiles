#!/bin/sh
eval $(command ls -1Ap 2>/dev/null | awk '
/\/$/ {d++}
!/\/$/ {f++}
END { print "d="d+0"; f="f+0 }')

r_dir=$(tail -n 1 ~/.cache/dir_recent.log 2>/dev/null | grep -o "/.*" | sed "s|^$HOME|~|")
r_file=$(tail -n 1 ~/.cache/nvim_recent.log 2>/dev/null | grep -o "/.*" | sed "s|^$HOME|~|")

out=""
# Màu hồng bold italic cho dir
[ -n "$r_dir" ] && out="\033[1;3;38;2;255;121;198m${d}  ${r_dir}\033[0m"

# Màu vàng bold italic cho file
[ -n "$r_file" ] && { 
    [ -n "$out" ] && out="${out}  "
    out="${out}\033[1;3;38;2;241;250;140m${f} 󰈔 ${r_file}\033[0m"
}

printf "%b\n" "$out"
