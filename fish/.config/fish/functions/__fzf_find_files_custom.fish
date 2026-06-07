function __fzf_find_files_custom
    # Dùng fd quét file phẳng (--type f), hiện đồ ẩn, né thư mục rác .git
    set -l file (fd --type f --hidden --follow --exclude .git | fzf \
        --layout=reverse \
        --border \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}')
    
    # Nếu chọn được file, dịch nó thành đường dẫn tuyệt đối bằng realpath
    if test -n "$file"
        set -l absolute_file (realpath -- $file)
        # Ném thẳng tên file tuyệt đối đó vào vị trí con trỏ trên Terminal
        commandline -i (string escape -- $absolute_file)
    end
    commandline -f repaint
end
