function __smart_pager_switch --description "Xử lý gợi ý và chuyển sang mode được truyền vào"
    # $argv[1] là tên mode được truyền vào (ví dụ: mypager)
    set -l target_mode $argv[1]

    # Kiểm tra xem có truyền tham số không, nếu không mặc định là mypager
    test -z "$target_mode"; and set target_mode mypager

    # Nếu được gọi từ Shift-Tab (truyền tham số thứ 2 là 'search')
    if test "$argv[2]" = "search"
        commandline -f complete-and-search
    else
        commandline -f complete
    end

    # Nếu bảng gợi ý Pager hiển thị -> Chuyển sang target_mode
    if commandline --paging-mode
        set fish_bind_mode $target_mode
        commandline -f repaint
    end
end
