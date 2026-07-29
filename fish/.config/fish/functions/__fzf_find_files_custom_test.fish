function __fzf_find_files_custom_test
    # Cấp độ mặc định = 1 (Hiện tại, không sâu)
    set -l initial_level $argv[1]
    test -z "$initial_level"; and set initial_level 1

    set -l level_file (mktemp)
    echo "$initial_level" > "$level_file"
    set -l master_script (mktemp)

    # BẢNG MÀU TRUE COLOR HEX
    set -l tc_lvl1  (set_color 7aa2f7) # Xanh dương
    set -l tc_lvl2  (set_color 9ece6a) # Xanh lá
    set -l tc_lvl3  (set_color f7768e) # Đỏ/Hồng
    set -l tc_dim   (set_color 565f89)
    set -l tc_reset (set_color normal)

    # KỊCH BẢN ĐIỀU PHỐI (Chuyển mode & Gọi module quét)
    echo "#!/bin/sh
    action=\$1
    level=\$(cat \"$level_file\")

    if [ \"\$action\" = \"next\" ]; then
        level=\$(( (level % 3) + 1 ))
        echo \"\$level\" > \"$level_file\"
    elif [ \"\$action\" = \"prev\" ]; then
        level=\$(( level - 1 ))
        [ \$level -lt 1 ] && level=3
        echo \"\$level\" > \"$level_file\"
    fi

    case \$level in
        1) scope_text=\"$tc_lvl1 LVL 1 $tc_reset$tc_dim(Thư mục hiện tại - Nông)$tc_reset\" ;;
        2) scope_text=\"$tc_lvl2 LVL 2 $tc_reset$tc_dim(Thư mục hiện tại - Sâu)$tc_reset\" ;;
        3) scope_text=\"$tc_lvl3 LVL 3 $tc_reset$tc_dim(Toàn hệ thống HOME - Sâu)$tc_reset\" ;;
    esac

    printf \"%s>>> TRẠNG THÁI TÌM KIẾM: %s %s<<<%s\n\" \"$tc_dim\" \"\$scope_text\" \"$tc_dim\" \"$tc_reset\"

    # Gọi module quét file bằng Fish Shell
    fish -c \"__fzf_scan_paths \$level f\" </dev/null 2>/dev/null
    " > "$master_script"
    chmod +x "$master_script"

    # GỌI FZF
    set -l fzf_out ($master_script init | fzf \
        --ansi \
        --tiebreak=index \
        --layout=reverse \
        --border \
        --prompt="Files Search> " \
        --header="Enter: Mở | Right: Dán | Shift-Right: Tăng cấp | Shift-Left: Giảm cấp" \
        --header-lines=1 \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {}' \
        --bind="shift-left:reload($master_script prev)" \
        --bind="shift-right:reload($master_script next)" \
        --expect=right,enter)

    # Đọn dẹp file tạm
    rm -f "$level_file" "$master_script"

    # Thoát nếu bấm ESC / không chọn
    if test (count $fzf_out) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_out[1]
    set -l selected_file $fzf_out[2]

    # Xử lý kết quả
    if test -n "$selected_file"
        set -l absolute_file (realpath -- $selected_file)

        if test "$key_pressed" = "enter"
            nvim $absolute_file
        else if test "$key_pressed" = "right"
            commandline -i (string escape -- $absolute_file)" "
            # Gọi hàm log nếu có
            functions -q __fzf_score_file; and __fzf_score_file "$absolute_file"
            functions -q log_recent_file; and log_recent_file "$absolute_file"
        end
    end

    commandline -f repaint 2>/dev/null
end
