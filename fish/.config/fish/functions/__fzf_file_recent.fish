function __fzf_file_recent --description "Bốc danh sách file vừa làm việc trong Neovim ra FZF với tốc độ bàn thờ"
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent ghen Phương ơi! Hãy mở vài file bằng nvim trước nha."
        return
    end

    # Đọc trực tiếp file log (luôn có sẵn), loại bỏ các file lỡ bị xóa vật lý, rồi ném vào FZF
    set -l file (cat "$log_file" | while read -l line
        if test -f "$line"
            echo "$line"
        end
    end | fzf \
        --layout=reverse \
        --border \
        --prompt="File Recent (Neovim History)> " \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}')

    # Nếu chọn được file, ném thẳng đường dẫn file đó vào vị trí con trỏ chuột trên Terminal
    if test -n "$file"
        commandline -i (string escape $file)
    end
    commandline -f repaint
end
