function __fzf_find_files_custom
    set -l fzf_out (fd --type f --hidden --exclude .git </dev/null 2>/dev/null | fzf \
        --height 100% \
        --layout=reverse \
        --prompt="Custom Search> " \
        --header="Enter: Dán | Alt-Space: Quay lại Frecency" \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}' \
        --expect=alt-space,enter)

    # Thoát nếu bấm ESC
    if test (count $fzf_out) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_out[1]
    set -l selected_file $fzf_out[2]

    # 🎯 FIX LỖI THOÁT HẲN: Thêm sleep 0.05 vào đây
    if test "$key_pressed" = "alt-space"
        sleep 0.05 # Nghỉ một nhịp để dọn luồng Terminal
        __fzf_file_recent
        return
    end

    # 🎯 Xử lý chọn file: Dán đường dẫn ra Terminal
    if test -n "$selected_file"
        set -l absolute_file (realpath -- $selected_file)
        commandline -i (string escape -- $absolute_file)" "
    end
    
    commandline -f repaint 2>/dev/null
end
