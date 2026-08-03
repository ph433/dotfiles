function fullfunc --description "Lọc danh sách hàm Fish Shell bằng fzf và dán ra commandline"
    # Lấy query hiện tại trên dòng lệnh (nếu có)
    set -l query (commandline -b)
    set -l fzf_opts (__my_fzf_defaults) \
        --header="Gõ để tìm hàm..." \
        --prompt="> " \
        --expect=right

    if test -n "$query"
        set -a fzf_opts --query "$query"
    end

    # Chạy fzf lấy danh sách hàm
    # fzf sẽ trả về 2 dòng: Dòng 1 là phím bấm (--expect), Dòng 2 là tên hàm được chọn
    set -l output (functions -a | string split " " | string match -v "" | fzf $fzf_opts)

    # Nếu người dùng nhấn Esc (không chọn gì)
    if test (count $output) -lt 2
        commandline -f repaint
        return
    end

    set -l pressed_key $output[1]
    set -l selected_func (string trim -- $output[2])

    # Xử lý theo phím bấm
    if test "$pressed_key" = "right"
        # Mũi tên phải: Chỉ dán tên hàm ra command line để chỉnh sửa
        commandline -r $selected_func
    else
        # Phím Enter: Dán tên hàm và chạy luôn
        commandline -r $selected_func
        commandline -f execute
    end

    commandline -f repaint
end
