function __fzf_file_recent --description "Bốc danh sách file Frecency ra FZF với tốc độ bàn thờ"
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent ghen Phương ơi! Hãy mở vài file bằng nvim trước nha."
        return
    end

    # Đọc log, lọc file và đưa vào fzf. Thêm --expect=ctrl-y để bắt sự kiện phím
    set -l fzf_output (cat "$log_file" | while read -l score line
        if test -f "$line"
            echo "$score $line"
        end
    end | fzf \
        --layout=reverse \
        --border \
        --prompt="Frecency Files (Neovim History)> " \
        --header="Ctrl-Y / Enter: Dán đường dẫn ra vị trí con trỏ" \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 (string replace -r "^\d+\s+" "" {})' \
        --expect=ctrl-y,enter)

    # Thoát an toàn nếu người dùng nhấn ESC hoặc Ctrl-C
    if test (count $fzf_output) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    # Dòng 1 là tên phím, dòng 2 trở đi là nội dung file được chọn
    set -l key_pressed $fzf_output[1]
    set -l selected $fzf_output[2..-1]

    # Nếu người dùng bấm Ctrl-Y (hoặc Enter) và có file được chọn
    if contains $key_pressed ctrl-y enter; and test (count $selected) -gt 0
        # Lọc bỏ điểm số chỉ lấy đường dẫn
        set -l file (string replace -r "^\d+\s+" "" "$selected[1]")
        
        # Chèn đường dẫn đã escape (chống lỗi space trong tên file) và 1 dấu cách vào ngay con trỏ
        commandline -i (string escape $file)" "
    end
    
    commandline -f repaint 2>/dev/null
end
