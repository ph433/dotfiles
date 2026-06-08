function __fzf_file_recent --description "Bốc danh sách file Frecency ra FZF với tốc độ bàn thờ"
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent ghen Phương ơi! Hãy mở vài file bằng nvim trước nha."
        return
    end

    # Đọc log, lọc file tồn tại vật lý, đưa cả ĐIỂM SỐ vào fzf để hiển thị trực quan
    # Dùng awk để đảo ngược: fzf nhìn thấy đường dẫn để preview, nhưng hiển thị thì thấy cả điểm
    set -l selected (cat "$log_file" | while read -l score line
        if test -f "$line"
            echo "$score $line"
        end
    end | fzf \
        --layout=reverse \
        --border \
        --prompt="Frecency Files (Neovim History)> " \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 (string replace -r "^\d+\s+" "" {})')

    # Nếu chọn được file, lọc bỏ điểm số chỉ lấy đường dẫn đưa vào dòng lệnh
    if test -n "$selected"
        set -l file (string replace -r "^\d+\s+" "" "$selected")
        commandline -i (string escape $file)
    end
    commandline -f repaint
end
