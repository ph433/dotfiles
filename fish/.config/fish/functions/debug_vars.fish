function debug_vars -d "Chỉ xem biến người dùng tạo khi debug"
    set -l lines

    # Lấy danh sách tên tất cả các biến
    for var in (set -n)
        # 1. Bỏ qua các biến đặc biệt của fzf, debug và Fish internals
        string match -qr '^(lines|var|val|info|history|status|version|pipestatus|_.*)$' -- $var; and continue

        # 2. Lấy thông tin scope của biến
        set -l info (set -S $var)

        # 3. Lọc bỏ biến Exported (biến môi trường như LC_*, STARSHIP_*, ALACRITTY_*)
        if string match -q "*exported*" -- "$info"
            continue
        end

        # 4. Lọc bỏ biến viết hoa toàn bộ (thường là biến cấu hình hệ thống / tool ngoài)
        if string match -qr '^[A-Z0-9_]+$' -- $var
            continue
        end

        # 5. Lấy giá trị biến
        set -l val (eval "string join ' ' -- \$$var")
        set -a lines (printf "\$$var\t: %s" "$val")
    end

    if test (count $lines) -eq 0
        echo "Không tìm thấy biến tùy chỉnh nào."
        return 1
    end

    # Hiển thị fzf, sắp xếp theo thứ tự chữ cái hoặc đảo ngược
    printf "%s\n" $lines | fzf \
        --delimiter="\t: " \
        --preview='eval set -S (string sub -s 2 {1})' \
        --preview-window='right:50%:wrap' \
        --prompt="Debug Vars > " \
        --bind="left:execute-silent(eval echo -n (string sub -s 2 {1}) | xclip -selection clipboard)+clear-screen"
end
