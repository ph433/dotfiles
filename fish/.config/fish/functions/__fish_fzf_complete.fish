function __fish_fzf_complete
    set -l cmd (commandline -b)

    # Lấy danh sách gợi ý từ Fish
    set -l targets (complete -C"$cmd")

    if test -n "$targets"
        # --print-query: Trả về chuỗi đang gõ ở ô search (dòng 1)
        # --expect: Trả về tên phím kích hoạt (dòng 2)
        # Dòng 3 trở đi: Kết quả được chọn từ danh sách
        set -l fzf_out (string join \n $targets | column -t -s \t | fzf --height=100% \
            --layout=reverse \
            --tiebreak=index \
            --print-query \
            --bind=insert:accept,right:accept \
            --expect=enter,insert,right)

        # Đọc thứ tự các dòng output từ fzf
        set -l query $fzf_out[1]
        set -l key $fzf_out[2]
        set -l selected $fzf_out[3]

        if test "$key" = "insert"
            # Phím Insert: Chèn CHỮ ĐANG GÕ trong ô search fzf + dấu cách
            commandline -rt "$query "
        else if test -n "$selected"
            # Lấy từ đầu tiên của candidate được chọn
            set -l result (string match -r '^\S+' -- $selected)

            if test "$key" = "enter"
                # Phím Enter: Chèn candidate được chọn & chạy lệnh
                commandline -rt "$result"
                commandline -f execute
            else if test "$key" = "right"
                # Phím Right: Chèn candidate được chọn KHÔNG có dấu cách
                commandline -rt "$result "
            end
        end
    end
    commandline -f repaint
end
