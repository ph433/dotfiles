function __fzf_zoxide_custom --description "Zoxide fzf: Enter để CD, Right để Paste"
    # Gọi zoxide xuất danh sách kèm điểm số, pipe vào fzf
    set -l fzf_out (zoxide query -ls | fzf \
        --expect=right,enter \
        --preview='eza --icons --color=always {2..}' \
        --preview-window='down:70%' \
        --layout=reverse \
        --prompt="Zoxide> " \
        --header="Enter: CD | Right: Paste" \
        --color="prompt:#61afef,info:#e5c07b,header:#56b6c2,pointer:#c678dd,marker:#98c379")

    # Nếu người dùng nhấn Esc thoát (output rỗng)
    if test (count $fzf_out) -lt 2
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key $fzf_out[1]
    set -l selected $fzf_out[2]

    # Regex cắt bỏ phần điểm số ở cột 1, chỉ lấy đường dẫn chuẩn
    set -l target (string replace -r "^\s*[0-9.]+\s+" "" -- $selected)

    if test "$key" = "right"
        # 🎯 Nhấn Right: Dán đường dẫn ra shell (cách ra 1 dấu nhịp)
        commandline -i (string escape $target)" "
    else if test "$key" = "enter"
        # 🎯 Nhấn Enter: Dọn dòng lệnh và cd vào thư mục 
        # (Dùng 'z' thay vì 'cd' để zoxide cộng thêm điểm lịch sử)
        commandline -r "z "(string escape $target)
        commandline -f execute
    end

    commandline -f repaint 2>/dev/null
end
