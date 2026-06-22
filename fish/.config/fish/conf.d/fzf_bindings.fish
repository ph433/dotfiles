# Kiểm tra nếu Terminal đang ở chế độ tương tác thì mới gán phím
if status is-interactive
    # Định nghĩa các chế độ gõ (Áp dụng cho cả Vi mode nếu có xài)
    set -l vi_modes default insert

    for mode in default insert
        # Phím tắt cũ của bạn
        bind --mode $mode down '__fzf_zoxide_custom'
        
        # 🎯 PHÍM TẮT MỚI: Nhấn Ctrl + H để tìm kiếm thư mục Home
        bind --mode $mode alt-down '__fzf_find_files_custom'
        bind --mode $mode alt-up '__fzf_search_directory_custom'
        bind --mode $mode shift-down '__fzf_file_recent'
	bind --mode $mode ctrl-down 'fzfrecent'
        bind --mode $mode ctrl-up 'gdiff'
	bind --mode $mode shift-up 'glog'
	bind --mode $mode ctrl-shift-up 'fzf_git_checkout'
	bind --mode $mode ctrl-x 'y'
	# bind shift-left cdh
	bind --mode $mode shift-left 'cdh'
	bind --mode $mode shift-right 'cdmd'
	bind --mode $mode ctrl-y 'commandline -r "lta"; commandline -f execute'
	bind --mode $mode ctrl-shift-y 'commandline -r "ll"; commandline -f execute'

    end
end
