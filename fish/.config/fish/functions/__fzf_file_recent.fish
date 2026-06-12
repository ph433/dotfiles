function __fzf_file_recent --description "Bốc danh sách file Frecency"
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent ghen Phương ơi! Hãy mở vài file bằng nvim trước nha." >&2
        return
    end

    # Khởi tạo tài nguyên tạm (Đã bỏ bớt các file rườm rà)
    set -l tmp_global (mktemp)
    set -l tmp_local (mktemp)
    set -l scope_file (mktemp)
    set -l master_script (mktemp)

    set -l real_pwd (realpath $PWD)
    set -l rel_pwd ""
    if test "$PWD" != "$HOME"
        set rel_pwd (string replace "$HOME/" "" "$PWD")
    end

    # --- BẢNG MÀU TRUE COLOR HEX ---
    set -l tc_local   (set_color 9ece6a)
    set -l tc_global  (set_color f7768e)
    set -l tc_dim     (set_color 565f89)
    set -l tc_reset   (set_color normal)
    
    set -l c_score (set_color ff9e64)
    set -l c_reset (set_color normal)
    set -l c_link  (set_color bb9af7)
    set -l c_dot   (set_color 9ece6a)
    set -l c_file  (set_color 7dcfff)

    # Quét dữ liệu lịch sử và tạo danh sách
    cat "$log_file" | sort -nr | while read -l score line
        if test -e "$line"
            set -l path_color $c_file 
            if test -L "$line"
                set path_color $c_link
            else if string match -q "*/dotfiles/*" "$line"
                set path_color $c_dot
            end

            set -l colored_entry "$c_score$score$c_reset $path_color$line$c_reset"
            echo $colored_entry >> "$tmp_global"

            if string match -q "$PWD/*" "$line"; \
               or string match -q "$real_pwd/*" "$line"; \
               or { test -n "$rel_pwd"; and string match -q "*/$rel_pwd/*" "$line"; }
                echo $colored_entry >> "$tmp_local"
            end
        end
    end

    # Trạng thái ban đầu
    if test -s "$tmp_local"
        echo "local" > "$scope_file"
    else
        echo "home" > "$scope_file"
    end

    # KỊCH BẢN ĐIỀU PHỐI (Chỉ còn nhiệm vụ đọc file, không còn AWK phức tạp)
    echo "#!/bin/sh
    action=\$1
    scope=\$(cat \"$scope_file\")

    if [ \"\$action\" = \"toggle-scope\" ]; then
        if [ \"\$scope\" = \"local\" ]; then scope=\"home\"; else scope=\"local\"; fi
        echo \"\$scope\" > \"$scope_file\"
    fi

    if [ \"\$scope\" = \"local\" ]; then
        hist_file=\"$tmp_local\"
        scope_text=\"$tc_local LOCAL $tc_reset$tc_dim(Lịch sử thư mục hiện tại)$tc_reset\"
    else
        hist_file=\"$tmp_global\"
        scope_text=\"$tc_global HOME $tc_reset$tc_dim(Lịch sử toàn hệ thống)$tc_reset\"
    fi

    printf \"%s>>> TRẠNG THÁI: %s %s<<<%s\n\" \"$tc_dim\" \"\$scope_text\" \"$tc_dim\" \"$tc_reset\"
    cat \"\$hist_file\"" > "$master_script"
    chmod +x "$master_script"

    # GỌI FZF
    set -l fzf_output ($master_script init | fzf \
        --ansi \
        --tiebreak=index \
        --layout=reverse \
        --border \
        --prompt="Frecency> " \
        --header="Enter: Mở | Ctrl-Y: Dán | Ctrl-Space: Đổi phạm vi | Alt-Space: Tìm Custom" \
        --header-lines=1 \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {2..}' \
        --bind="ctrl-space:reload($master_script toggle-scope)" \
        --expect=ctrl-y,enter,alt-space)

    # Dọn dẹp
    rm -f "$tmp_global" "$tmp_local" "$scope_file" "$master_script"

    if test (count $fzf_output) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_output[1]
    set -l selected $fzf_output[2..-1]

    # 🎯 Nhảy sang hàm Custom
    if test "$key_pressed" = "alt-space"
        sleep 0.05
        __fzf_find_files_custom
        return
    end

    # --- Xử lý Mở file và Ghi điểm ---
    if test (count $selected) -gt 0
        set -l file (string replace -r "^\S+\s+" "" -- "$selected[1]")

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
                if (path == target) { score += 5.0; found = 1 } else { score -= 0.5 }
                printf "%.1f %s\n", score, path
            }
            END { if (!found) printf "5.0 %s\n", target }' "$log_file" | sort -nr | head -n 100 > "$tmp_log"
            mv "$tmp_log" "$log_file"
        end
    end
    
    commandline -f repaint 2>/dev/null
end
