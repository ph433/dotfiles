function fzf_menu --description "Màn hình gọi lệnh nhanh bằng phím tắt qua fzf"
    # 1. Tạo bảng hiển thị hướng dẫn (Cheat sheet)
    set -l cheat_sheet \
        " [Tab]   : Find file" \
        " [Left]  : Recent file" \
        " [Down]  : Zoxide" \
        " [Right] : Recent dir" \
        " [Up]    : Find file (score)" \
        " [Space] : Find directory (recent)"

    # 2. Xuất màn hình chờ ra fzf và bắt phím tắt
    set -l choice (printf "%s\n" $cheat_sheet | fzf \
        --ansi \
        --color="header:#ff79c6:bold,info:#ffb86c" \
        --layout=reverse \
        --header="BẤM PHÍM TẮT ĐỂ GỌI LỆNH NGAY LẬP TỨC:" \
	--bind "home:become(echo __fzf_find_files_custom)" \
        --bind "left:become(echo fzfrecent)" \
        --bind "enter:become(echo __fzf_zoxide_custom)" \
        --bind "right:become(echo fzfrecentdir)" \
        --bind "space:become(echo __fzf_file_recent)" \
	--bind "end:become(echo __fzf_search_directory_custom)" \
	) # Vô hiệu hóa Enter để tránh lỗi do không còn cuộn được

    # 3. Nếu người dùng nhấn ESC để thoát
    if test -z "$choice"
        commandline -f repaint
        return
    end

    # 4. Thực thi lệnh
    # Với tư duy mới, $choice giờ đây chính là tên hàm được trả về từ lệnh become()
    eval $choice
end
