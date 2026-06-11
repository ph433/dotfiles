function __fzf_file_recent --description "Bốc danh sách file Frecency (Toggle Local/Global siêu mượt)"
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

    cat "$log_file" | sort -nr | while read -l score line
        if test -f "$line"
            echo "$score $line" >> "$tmp_global"
            if string match -q "$PWD/*" "$line"; or string match -q "$real_pwd/*" "$line"
                echo "$score $line" >> "$tmp_local"
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

    # [SỬA REGEX] Dùng \S+ để tương thích với cả dấu phẩy lẫn dấu chấm
    set -l fzf_output (cat "$initial_file" | fzf \
        --tiebreak=index \
        --layout=reverse \
        --border \
        --prompt="Frecency> " \
        --header="Enter: Mở | Ctrl-Y: Dán | Ctrl-Space: Bật/Tắt (Thư mục hiện tại <-> Toàn cục)" \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 (string replace -r "^\S+\s+" "" {})' \
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
        # [SỬA REGEX] Cắt bỏ cột điểm an toàn 100%
        set -l file (string replace -r "^\S+\s+" "" "$selected[1]")

        if test "$key_pressed" = "enter"
            nvim $file
        else if test "$key_pressed" = "ctrl-y"
            commandline -i (string escape $file)" "

            set -l tmp_log (mktemp)
            
            # [ÉP BUỘC] env LC_NUMERIC=C bắt awk phải dùng dấu chấm (.)
            env LC_NUMERIC=C awk -v target="$file" '
            {
                score = $1; path = $2
                for(i=3; i<=NF; i++) path = path " " $i 
                
                # Biến phẩy thành chấm nếu lỡ có lưu sai từ trước
                gsub(",", ".", score)
                
                if (path == target) {
                    score += 5.0
                    found = 1
                } else {
                    score -= 0.5
                    if (score < 1.0) score = 1.0
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
