function fzf_menu_aliases --description "Màn hình gọi lệnh nhanh bằng phím tắt qua fzf"
    # 1. Tạo bảng hiển thị hướng dẫn (Cheat sheet)
    set -l cheat_sheet \
        " [Tab]   : Open yazi" \
        " [Left]  : List tree" \
        " [Down]  : Print working dictory" \
        " [Right] : List all" \
        " [Up]    : Clear all" \
        " [Space] : Find directory (recent)"

    # 2. Xuất màn hình chờ ra fzf và bắt phím tắt
    set -l choice (printf "%s\n" $cheat_sheet | fzf \
        --ansi \
        --color="header:#ff79c6:bold,info:#ffb86c" \
        --layout=reverse \
        --header="BẤM PHÍM TẮT ĐỂ GỌI LỆNH NGAY LẬP TỨC:" \
        --bind "tab:become(echo y)" \
        --bind "left:become(echo lta)" \
        --bind "down:become(echo pwd)" \
        --bind "right:become(echo ll)" \
        --bind "up:become(echo clear)" \
        --bind "space:become(echo __fzf_search_directory_custom)" \
        --bind "enter:ignore")

    # 3. Nếu người dùng nhấn ESC để thoát
    if test -z "$choice"
        commandline -f repaint
        return
    end

    # 4. Thực thi lệnh một cách tự nhiên
    # Nạp lệnh vào dòng nhắc hiện tại và mô phỏng thao tác nhấn phím Enter
    commandline -r "$choice"
    commandline -f execute
end
