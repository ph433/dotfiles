function __fzf_file_recent --description "Bốc danh sách file Frecency (True Color HEX & Hỗ trợ Stow)"
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent ghen Phương ơi! Hãy mở vài file bằng nvim trước nha." >&2
        return
    end

    set -l tmp_global (mktemp)
    set -l tmp_local (mktemp)
    set -l toggle_state (mktemp)
    set -l toggle_script (mktemp)

    set -l real_pwd (realpath $PWD)
    
    set -l rel_pwd ""
    if test "$PWD" != "$HOME"
        set rel_pwd (string replace "$HOME/" "" "$PWD")
    end

    # TẠO MÀU TRUE COLOR BẰNG MÃ HEX (Bạn có thể tự đổi mã màu tùy thích)
    set -l c_score (set_color ff9e64) # Màu Cam/Vàng nhẹ
    set -l c_reset (set_color normal)
    set -l c_link  (set_color bb9af7) # Màu Tím pastel (Symlink)
    set -l c_dot   (set_color 9ece6a) # Màu Xanh lá mạ (Dotfiles thật)
    set -l c_file  (set_color 7dcfff) # Màu Xanh lơ sáng (File thường)

    # 1. Quét dữ liệu và Phân loại màu sắc
    cat "$log_file" | sort -nr | while read -l score line
        if test -e "$line"
            set -l path_color $c_file 

            if test -L "$line"
                set path_color $c_link
            else if string match -q "*/dotfiles/*" "$line"
                set path_color $c_dot
            end

            # Nối chuỗi biến màu (Fish sẽ tự xuất ra mã ANSI 24-bit chuẩn xác)
            set -l colored_entry "$c_score$score$c_reset $path_color$line$c_reset"
            
            echo $colored_entry >> "$tmp_global"
            
            if string match -q "$PWD/*" "$line"; \
               or string match -q "$real_pwd/*" "$line"; \
               or { test -n "$rel_pwd"; and string match -q "*/$rel_pwd/*" "$line"; }
                echo $colored_entry >> "$tmp_local"
            end
        end
    end

    set -l initial_file
    if test -s "$tmp_local"
        echo "local" > "$toggle_state"
        set initial_file "$tmp_local"
    else
        echo "global" > "$toggle_state"
        set initial_file "$tmp_global"
    end

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

    set -l fzf_output (cat "$initial_file" | fzf \
        --ansi \
        --tiebreak=index \
        --layout=reverse \
        --border \
        --prompt="Frecency> " \
        --header="Enter: Mở | Ctrl-Y: Dán | Ctrl-Space: Bật/Tắt (Thư mục hiện tại <-> Toàn cục)" \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {2..}' \
        --bind="ctrl-space:reload($toggle_script)" \
        --expect=ctrl-y,enter)

    rm -f "$tmp_global" "$tmp_local" "$toggle_state" "$toggle_script"

    if test (count $fzf_output) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_output[1]
    set -l selected $fzf_output[2..-1]

    if test (count $selected) -gt 0
        set -l file (string replace -r "^\S+\s+" "" "$selected[1]")

        if test "$key_pressed" = "enter"
            nvim $file
        else if test "$key_pressed" = "ctrl-y"
            commandline -i (string escape $file)" "

            set -l tmp_log (mktemp)
            
            env LC_NUMERIC=C awk -v target="$file" '
            {
                score = $1; path = $2
                for(i=3; i<=NF; i++) path = path " " $i 
                
                gsub(",", ".", score)
                
                if (path == target) {
                    score += 5.0
                    found = 1
                } else {
                    score -= 0.5
                }
                printf "%.1f %s\n", score, path
            }
            END {
                if (!found) printf "5.0 %s\n", target
            }' "$log_file" | sort -nr | head -n 100 > "$tmp_log"
            
            mv "$tmp_log" "$log_file"
        end
    end
    
    commandline -f repaint 2>/dev/null
end
