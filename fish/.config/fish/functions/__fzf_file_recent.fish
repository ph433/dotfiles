function __fzf_file_recent --description "Bốc danh sách file Frecency ra FZF với tốc độ bàn thờ"
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent ghen Phương ơi! Hãy mở vài file bằng nvim trước nha." >&2
        return
    end

    # sort -nr xếp điểm cao lên đầu
    # --no-sort ép FZF tuyệt đối giữ nguyên thứ tự này khi lọc từ khóa
    set -l fzf_output (cat "$log_file" | while read -l score line
        if test -f "$line"
            echo "$score $line"
        end
    end | sort -nr | fzf \
        --no-sort \
        --layout=reverse \
        --border \
        --prompt="Frecency Files (Neovim History)> " \
        --header="Enter: Mở file bằng Nvim | Ctrl-Y: Dán đường dẫn ra con trỏ" \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 (string replace -r "^\d+\s+" "" {})' \
        --expect=ctrl-y,enter)

    # Nếu người dùng hủy (nhấn ESC hoặc Ctrl-C)
    if test (count $fzf_output) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_output[1]
    set -l selected $fzf_output[2..-1]

    if test (count $selected) -gt 0
        # Lọc bỏ điểm số, chỉ lấy đường dẫn vật lý
        set -l file (string replace -r "^\d+\s+" "" "$selected[1]")

        if test "$key_pressed" = "enter"
            # Chạy trực tiếp nvim đè lên terminal hiện tại
            nvim $file
        else if test "$key_pressed" = "ctrl-y"
            # Chèn đường dẫn đã escape và 1 dấu cách vào ngay con trỏ
            commandline -i (string escape $file)" "
        end
    end
    
    # Vẽ lại giao diện dòng lệnh sau khi nvim đóng hoặc sau khi dán file
    commandline -f repaint 2>/dev/null
end
