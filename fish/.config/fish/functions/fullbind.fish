function fullbind --description "Lọc danh sách keybinding Fish Shell bằng fzf, preview và dán ra commandline"
    # Lấy query hiện tại trên dòng lệnh (nếu có)
    set -l query (commandline -b)
    
    # Cấu hình fzf: Thêm preview để xem chi tiết bind
    set -l fzf_opts (__my_fzf_defaults) \
        --header="Gõ để tìm keybinding..." \
        --prompt="> " \
        --expect=right \
        --nth=3 \
        --preview="echo {}" \
        --preview-window="down:3:wrap" \
        --bind "left:execute-silent(echo -n {} | xclip -selection clipboard)+clear-screen"

    if test -n "$query"
        set -a fzf_opts --query "$query"
    end

    # Lấy danh sách keybinding và lọc qua fzf
    set -l output (bind | fzf $fzf_opts)

    # Nếu không chọn gì hoặc nhấn Esc
    if test (count $output) -lt 2
        commandline -f repaint
        return
    end

    set -l pressed_key $output[1]
    set -l selected_bind (string trim -- $output[2])

    # Tách lấy phần sequence (ví dụ: `bind \e[A ...` -> lấy tên phím hoặc toàn bộ câu lệnh bind)
    if test "$pressed_key" = "right"
        # Nhấn phím Phải: Copy toàn bộ câu lệnh bind vào clipboard
        echo -n "$selected_bind" | xclip -selection clipboard
    else
        # Phím Enter: Dán câu lệnh bind ra dòng lệnh
        commandline -r $selected_bind
    end

    commandline -f repaint
end
