function __fzf_find_files_custom
    # 🎯 Nhận "gậy tiếp sức" trạng thái từ Frecency
    set -l initial_scope $argv[1]
    if test -z "$initial_scope"
        set initial_scope "local"
    end

    set -l scope_file (mktemp)
    echo "$initial_scope" > "$scope_file"
    set -l master_script (mktemp)
    set -l real_pwd (realpath $PWD)
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    # --- BẢNG MÀU TRUE COLOR HEX ---
    set -l tc_local   (set_color 9ece6a)
    set -l tc_global  (set_color f7768e)
    set -l tc_dim     (set_color 565f89)
    set -l tc_reset   (set_color normal)

    # KỊCH BẢN ĐIỀU PHỐI RIÊNG CHO HÀM CUSTOM (Quản lý fd)
    echo "#!/bin/sh
    action=\$1
    scope=\$(cat \"$scope_file\")

    if [ \"\$action\" = \"toggle-scope\" ]; then
        if [ \"\$scope\" = \"local\" ]; then scope=\"home\"; else scope=\"local\"; fi
        echo \"\$scope\" > \"$scope_file\"
    fi

    if [ \"\$scope\" = \"local\" ]; then
        scan_dir=\"$real_pwd\"
        scope_text=\"$tc_local LOCAL $tc_reset$tc_dim(Quét file trong thư mục hiện tại)$tc_reset\"
    else
        scan_dir=\"\$HOME\"
        scope_text=\"$tc_global HOME $tc_reset$tc_dim(Quét file trên toàn hệ thống)$tc_reset\"
    fi

    printf \"%s>>> TRẠNG THÁI TÌM KIẾM: %s %s<<<%s\n\" \"$tc_dim\" \"\$scope_text\" \"$tc_dim\" \"$tc_reset\"

    # 🎯 TỐI ƯU HÓA LỆNH FD: Tôn trọng .gitignore và chặn thẳng các thư mục rác siêu to khổng lồ
    fd --type f --type l --hidden --follow --exclude .git --exclude node_modules --exclude .cache --exclude .local/share --exclude target --exclude build . \"\$scan_dir\" </dev/null 2>/dev/null
    " > "$master_script"
    chmod +x "$master_script"

    # GỌI FZF
    set -l fzf_out ($master_script init | fzf \
        --ansi \
        --tiebreak=index \
        --layout=reverse \
        --border \
        --prompt="Custom Search> " \
        --header="Enter: Mở | Ctrl-Y: Dán | Left: Đổi phạm vi | Right: File recent | Ctrl-Right: Tìm thư mục" \
        --header-lines=1 \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}' \
        --bind="left:reload($master_script toggle-scope)" \
        --expect=right,ctrl-right,enter,ctrl-y)

    # Đọc lại trạng thái cuối cùng và dọn dẹp
    set -l final_scope (cat "$scope_file" 2>/dev/null)
    rm -f "$scope_file" "$master_script"

    # Thoát nếu bấm ESC
    if test (count $fzf_out) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_out[1]
    set -l selected_file $fzf_out[2]

    # 🎯 Chuyền trạng thái sang hàm Frecency
    if test "$key_pressed" = "right"
        sleep 0.05 
        __fzf_file_recent "$final_scope"
        return
    end

    # 🎯 Chuyền trạng thái sang hàm tìm thư mục
    if test "$key_pressed" = "ctrl-right"
        sleep 0.05
        __fzf_search_directory_custom "$final_scope"
        return
    end

    # 🎯 Xử lý Mở file (Enter) và Dán (Ctrl-Y), kèm theo Ghi điểm Frecency
    if test -n "$selected_file"
        set -l absolute_file (realpath -- $selected_file)

        # Mở hoặc dán
        if test "$key_pressed" = "enter"
            nvim $absolute_file
        else if test "$key_pressed" = "ctrl-y"
            commandline -i (string escape -- $absolute_file)" "
        end

        # 🎯 Ghi điểm Frecency
        __fzf_score_file "$absolute_file"
    end
    
    commandline -f repaint 2>/dev/null
end
