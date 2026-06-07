# Kiểm tra nếu Terminal đang ở chế độ tương tác thì mới gán phím
if status is-interactive
    # Định nghĩa các chế độ gõ (Áp dụng cho cả Vi mode nếu có xài)
    set -l vi_modes default insert

    for mode in default insert
        bind --mode $mode ctrl-shift-x '__zoxide_zi; commandline -f repaint'
    end
end
