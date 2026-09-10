#!/bin/sh

r_dir=$(tail -n 1 ~/.cache/dir_recent.log 2>/dev/null)
r_dir=${r_dir#*/*}
[ -n "$r_dir" ] && r_dir="/${r_dir}"

r_file=$(tail -n 1 ~/.cache/nvim_recent.log 2>/dev/null)
r_file=${r_file#*/*}
[ -n "$r_file" ] && r_file="/${r_file}"

out=""
[ -n "$r_dir" ] && out="\033[1;3;38;2;255;121;198m ${r_dir}\033[0m"

[ -n "$r_file" ] && { 
    [ -n "$out" ] && out="${out}  "
    out="${out}\033[1;3;38;2;241;250;140m󰈔 ${r_file}\033[0m"
}

[ -n "$out" ] && printf "%b\n" "$out"
