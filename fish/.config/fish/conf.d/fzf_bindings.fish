# Kiểm tra nếu Terminal đang ở chế độ tương tác thì mới gán phím
if status is-interactive
    # Định nghĩa các chế độ gõ (Áp dụng cho cả Vi mode nếu có xài)
    set -l vi_modes default insert

    for mode in default insert
        # Phím tắt cũ của bạn
        bind --mode $mode ctrl-shift-x '__zoxide_zi; commandline -f repaint'
        
        # 🎯 PHÍM TẮT MỚI: Nhấn Ctrl + H để tìm kiếm thư mục Home
        bind --mode $mode alt-x '__fzf_search_home_custom'
        bind --mode $mode ctrl-down 'gdiff'
        bind --mode $mode ctrl-shift-down 'glog'
        bind --mode $mode shift-down '__fzf_find_files_custom'
        bind --mode $mode down '__fzf_file_recent'
    end
end
