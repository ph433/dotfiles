function __fzf_find_files_custom
    # 🎯 THÊM THAM SỐ --no-ignore VÀO ĐÂY
    set -l file (fd --type f --hidden --no-ignore --follow --exclude .git | fzf \
        --layout=reverse \
        --border \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}')
    
    if test -n "$file"
        set -l absolute_file (realpath -- $file)
        commandline -i (string escape -- $absolute_file)
    end
    commandline -f repaint
end
