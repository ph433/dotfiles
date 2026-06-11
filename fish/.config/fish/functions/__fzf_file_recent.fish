function __fzf_file_recent --description "Bốc danh sách file Frecency (Toggle Local/Global siêu mượt)"
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent ghen Phương ơi! Hãy mở vài file bằng nvim trước nha." >&2
        return
    end

    # Khởi tạo các file tạm (RAM) an toàn tuyệt đối
    set -l tmp_global (mktemp)
    set -l tmp_local (mktemp)
    set -l toggle_state (mktemp)
    set -l toggle_script (mktemp)

    # Phân giải đường dẫn để trị dứt điểm lỗi Symlink (Dotfiles)
    set -l real_pwd (realpath $PWD)

    # 1. Quét dữ liệu 1 lần và chia vào 2 giỏ
    cat "$log_file" | sort -nr | while read -l score line
        if test -f "$line"
            echo "$score $line" >> "$tmp_global"
            
            # Khớp thư mục hiện tại (cả đường dẫn ảo lẫn thật)
            if string match -q "$PWD/*" "$line"; or string match -q "$real_pwd/*" "$line"
                echo "$score $line" >> "$tmp_local"
            end
        end
    end

    # 2. Xử lý trạng thái khởi động (Nếu thư mục hiện tại không có file, tự mở Global)
    set -l initial_file
    if test -s "$tmp_local"
        echo "local" > "$toggle_state"
        set initial_file "$tmp_local"
    else
        echo "global" > "$toggle_state"
        set initial_file "$tmp_global"
    end

    # 3. Tạo "Công tắc" (Script ẩn) để FZF chuyển qua lại không bao giờ bị lỗi cú pháp
    echo "#!/bin/sh
    state=\$(cat \"$toggle_state\")
    if [ \"\$state\" = \"local\" ]; then
        echo \"global\" > \"$toggle_state\"
        cat \"$tmp_global\"
    else
        echo \"local\" > \"$toggle_state\"
        cat \"$tmp_local\"
    fi" > "$toggle_script"
    chmod +x "$toggle_script"

    # 4. Bọc TOÀN BỘ luồng chạy vào trong (...) để bắt output chuẩn xác
    set -l fzf_output (cat "$initial_file" | fzf \
        --tiebreak=index \
        --layout=reverse \
        --border \
        --prompt="Frecency> " \
        --header="Enter: Mở | Ctrl-Y: Dán | Ctrl-Space: Bật/Tắt (Thư mục hiện tại <-> Toàn cục)" \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 (string replace -r "^\d+\s+" "" {})' \
        --bind="ctrl-space:reload($toggle_script)" \
        --expect=ctrl-y,enter)

    # Dọn dẹp RAM ngay sau khi FZF đóng
    rm -f "$tmp_global" "$tmp_local" "$toggle_state" "$toggle_script"

    # Thoát an toàn nếu bấm ESC / Ctrl-C
    if test (count $fzf_output) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_output[1]
    set -l selected $fzf_output[2..-1]

    # 5. Xử lý file được chọn
    if test (count $selected) -gt 0
        set -l file (string replace -r "^\d+\s+" "" "$selected[1]")

        if test "$key_pressed" = "enter"
            nvim $file
        else if test "$key_pressed" = "ctrl-y"
            commandline -i (string escape $file)" "
        end
    end
    
    commandline -f repaint 2>/dev/null
end
