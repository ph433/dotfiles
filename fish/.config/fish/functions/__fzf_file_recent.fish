function __fzf_file_recent --description "Bốc danh sách file Frecency (Siêu tốc)"
    set -l initial_scope $argv[1] 
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent." >&2
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

    # 🎯 TỐI ƯU CỰC HẠN: Lược bỏ system("test -e") để tăng tốc độ lên mức 1ms
    env PWD="$PWD" REAL_PWD="$real_pwd" REL_PWD="$rel_pwd" awk '
    BEGIN {
        pwd = ENVIRON["PWD"]
        real_pwd = ENVIRON["REAL_PWD"]
        rel_pwd = ENVIRON["REL_PWD"]
    }
    {
        score = $1
        path = $2
        for(i=3; i<=NF; i++) path = path " " $i
        
        colored_entry = c_score score c_reset " " path
        
        # In ra danh sách Global
        print colored_entry > "'$tmp_global'"
        
        # Kiểm tra Local
        is_local = 0
        if (index(path, pwd "/") == 1) is_local = 1
        else if (index(path, real_pwd "/") == 1) is_local = 1
        else if (rel_pwd != "" && index(path, "/" rel_pwd "/") > 0) is_local = 1
        
        # In ra danh sách Local
        if (is_local) {
            print colored_entry > "'$tmp_local'"
        }
    }' "$log_file"

    # Thiết lập trạng thái ban đầu
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
    cat \"\$hist_file\" 2>/dev/null" > "$master_script"
    chmod +x "$master_script"

    set -l fzf_output ($master_script init | fzf \
        --ansi \
        --tiebreak=index \
        --layout=reverse \
        --border \
        --prompt="Frecency> " \
        --header="Enter: Mở | Right: Dán | Left: Đổi phạm vi" \
        --header-lines=1 \
        --preview-window="bottom:70%:hidden" \
        --preview 'bat --style=numbers --color=always --line-range :100 {2..}' \
        --bind="left:reload($master_script toggle-scope)" \
        --expect=enter,right)

    set -l final_scope (cat "$scope_file" 2>/dev/null)
    rm -f "$tmp_global" "$tmp_local" "$scope_file" "$master_script"

    if test (count $fzf_output) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_output[1]
    set -l selected $fzf_output[2..-1]

    if test (count $selected) -gt 0
        set -l file (string replace -r "^\S+\s+" "" -- "$selected[1]")

        if test "$key_pressed" = "enter"
            nvim $file
        else if test "$key_pressed" = "right"
            commandline -i (string escape $file)" "
	    #        __fzf_score_file "$file"
	    # log_recent_file "$file"
	    fish -c "log_recent_file '$file'; __fzf_score_file '$file'" >/dev/null 2>&1 &
        end
    end
    
    commandline -f repaint 2>/dev/null
end
