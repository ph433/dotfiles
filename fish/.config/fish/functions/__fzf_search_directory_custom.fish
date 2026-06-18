function __fzf_search_directory_custom --description "Search directories (Enter: cd, Right: paste, Left: toggle scope)"
    # 🎯 Nhận trạng thái phạm vi từ các hàm fzf khác (nếu có)
    set -l initial_scope $argv[1]
    if test -z "$initial_scope"
        set initial_scope "local"
    end

    set -l scope_file (mktemp)
    echo "$initial_scope" > "$scope_file"
    set -l master_script (mktemp)
    set -l real_pwd (realpath $PWD)

    # Đọc token hiện tại để hỗ trợ tìm kiếm trong thư mục đang gõ (ví dụ: gõ /var/log/ rồi bấm phím tắt)
    set -f token (commandline --current-token)
    set -f expanded_token (eval echo -- $token)
    set -f unescaped_exp_token (string unescape -- $expanded_token)

    set -l local_base_dir "$real_pwd"
    if string match --quiet -- "*/" $unescaped_exp_token && test -d "$unescaped_exp_token"
        set local_base_dir (realpath -- $unescaped_exp_token)
    end

    # --- BẢNG MÀU TRUE COLOR HEX ---
    set -l tc_local   (set_color 9ece6a)
    set -l tc_global  (set_color f7768e)
    set -l tc_dim     (set_color 565f89)
    set -l tc_reset   (set_color normal)

    # KỊCH BẢN ĐIỀU PHỐI RIÊNG (Chỉ quét thư mục)
    echo "#!/bin/sh
    action=\$1
    scope=\$(cat \"$scope_file\")

    if [ \"\$action\" = \"toggle-scope\" ]; then
        if [ \"\$scope\" = \"local\" ]; then scope=\"home\"; else scope=\"local\"; fi
        echo \"\$scope\" > \"$scope_file\"
    fi

    if [ \"\$scope\" = \"local\" ]; then
        scan_dir=\"$local_base_dir\"
        scope_text=\"$tc_local LOCAL $tc_reset$tc_dim(Quét thư mục tại \$scan_dir)$tc_reset\"
    else
        scan_dir=\"\$HOME\"
        scope_text=\"$tc_global HOME $tc_reset$tc_dim(Quét thư mục toàn hệ thống)$tc_reset\"
    fi

    printf \"%s>>> TRẠNG THÁI TÌM KIẾM: %s %s<<<%s\n\" \"$tc_dim\" \"\$scope_text\" \"$tc_dim\" \"$tc_reset\"

    # 🎯 Tìm riêng thư mục (--type d), do truyền \$scan_dir là đường dẫn tuyệt đối nên fd sẽ trả về đường dẫn tuyệt đối
    fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude .cache --exclude .local/share --exclude target --exclude build . \"\$scan_dir\" </dev/null 2>/dev/null
    " > "$master_script"
    chmod +x "$master_script"

    # GỌI FZF
    set -l fzf_out ($master_script init | fzf \
        --ansi \
        --height=100% \
        --tiebreak=index \
        --layout=reverse \
        --border \
        --prompt="Dir Search> " \
        --header="Enter: CD | Right: Dán | Left: Đổi phạm vi" \
        --header-lines=1 \
        --preview-window="bottom:50%" \
        --preview "_fzf_preview_dir_custom {}" \
        --bind="left:reload($master_script toggle-scope)" \
        --expect=enter,right)

    # Đọc lại trạng thái cuối cùng và dọn dẹp
    set -l final_scope (cat "$scope_file" 2>/dev/null)
    rm -f "$scope_file" "$master_script"

    # Thoát nếu bấm ESC
    if test (count $fzf_out) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_out[1]
    set -l selected_dir $fzf_out[2]

    # Xử lý hành động đầu ra
    if test -n "$selected_dir"
        set -l absolute_dir (realpath -- $selected_dir)

        if test "$key_pressed" = "enter"
            # 🎯 CD trực tiếp vào thư mục
            cd "$absolute_dir"
            
            # (Tùy chọn) Xóa chữ "cd" nếu người dùng lỡ gõ trên dòng lệnh trước khi gọi fzf để tránh kẹt lệnh
            set -l current_cmd (commandline)
            if string match --quiet --regex "^cd\s+.*" "$current_cmd"
                commandline -r ""
            end
            
        else if test "$key_pressed" = "right"
            # 🎯 Dán đường dẫn thư mục
            commandline --current-token --replace -- (string escape -- $absolute_dir)" "
        end
    end

    commandline -f repaint 2>/dev/null
end
