function __fzf_file_recent --description "Bốc danh sách file Frecency"
    # 🎯 Nhận "gậy tiếp sức" trạng thái từ hàm Custom truyền sang
    set -l initial_scope $argv[1] 
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent ghen Phương ơi! Hãy mở vài file bằng nvim trước nha." >&2
        return
    end

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
    # Đã xóa các biến màu c_link, c_dot, c_file để đường dẫn hiển thị màu trắng mặc định

    cat "$log_file" | sort -nr | while read -l score line
        if test -e "$line"
            # Đường dẫn ($line) không bọc màu, sẽ tự lấy màu mặc định của terminal
            set -l colored_entry "$c_score$score$c_reset $line"
            echo $colored_entry >> "$tmp_global"

            if string match -q "$PWD/*" "$line"; \
               or string match -q "$real_pwd/*" "$line"; \
               or { test -n "$rel_pwd"; and string match -q "*/$rel_pwd/*" "$line"; }
                echo $colored_entry >> "$tmp_local"
            end
        end
    end

    # 🎯 Thiết lập trạng thái ban đầu: Ưu tiên trạng thái được truyền vào
    if test -n "$initial_scope"
        echo "$initial_scope" > "$scope_file"
    else if test -s "$tmp_local"
        echo "local" > "$scope_file"
    else
        echo "home" > "$scope_file"
    end

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

    # 🎯 Đọc lại trạng thái cuối cùng trước khi dọn file rác
    set -l final_scope (cat "$scope_file" 2>/dev/null)
    rm -f "$tmp_global" "$tmp_local" "$scope_file" "$master_script"

    if test (count $fzf_output) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_output[1]
    set -l selected $fzf_output[2..-1]

    # 🎯 Chuyền "gậy tiếp sức" (final_scope) cho hàm Custom
    if test "$key_pressed" = "alt-space"
        sleep 0.05
        __fzf_find_files_custom "$final_scope"
        return
    end

    if test (count $selected) -gt 0
        set -l file (string replace -r "^\S+\s+" "" -- "$selected[1]")

        if test "$key_pressed" = "enter"
            nvim $file
        else if test "$key_pressed" = "ctrl-y"
            commandline -i (string escape $file)" "
            __fzf_score_file "$file"
        end
    end
    
    commandline -f repaint 2>/dev/null
end
