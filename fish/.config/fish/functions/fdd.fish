function fdd --description "Mở fzf chọn thư mục: Enter để cd, Right để chèn vào dòng lệnh"
    set -l fzf_opts (__my_fzf_defaults) \
        --header="Enter: cd | Right: paste dir | Tab: chọn nhiều" \
        --height=70% \
        --preview="ll {}" \
        --preview-window="down:50%" \
        --multi \
        --expect=right

    # Chạy fzf và hứng kết quả
    set -l output (fd --max-depth 1 --type d --hidden --no-ignore --follow | fzf $fzf_opts)

    # Nếu không chọn gì (hủy fzf) thì thoát
    if test -z "$output"
        commandline -f repaint
        return
    end

    # Dòng đầu tiên là phím kích hoạt (right hoặc rỗng nếu là Enter)
    set -l key $output[1]
    # Các dòng còn lại là danh sách thư mục được chọn
    set -l selections $output[2..-1]

    if test -z "$selections"
        commandline -f repaint
        return
    end

    if test "$key" = "right"
        # Xử lý khi nhấn phím Right: Escape từng thư mục và nối lại bằng khoảng trắng
        set -l escaped_dirs
        for dir in $selections
            set -a escaped_dirs (string escape -- $dir)
        end
        
        # Chèn danh sách thư mục cùng dấu cách ở cuối vào dòng lệnh
        commandline -i -- (string join " " $escaped_dirs)" "
    else
        # Xử lý khi nhấn Enter: cd vào thư mục đầu tiên được chọn
        cd $selections[1]
    end

    commandline -f repaint
end
