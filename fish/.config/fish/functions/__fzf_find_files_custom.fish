function __fzf_find_files_custom
    # Dùng fd quét file phẳng (--type f), hiện đồ ẩn, né thư mục rác .git
    set -l file (fd --type f --hidden --exclude .git | fzf \
        --layout=reverse \
        --border \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}')
    
    # Nếu chọn được file, ném thẳng tên file đó vào vị trí con trỏ chuột trên Terminal
    if test -n "$file"
        commandline -i (string escape $file)
    end
    commandline -f repaint
end
