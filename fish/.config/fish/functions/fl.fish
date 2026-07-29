function fl --description "Lọc file bằng fzf giữ nguyên True Color 100% khi search"
    set -l selected (ll | fzf \
        --ansi \
        --reverse \
        --header="Gõ để lọc danh sách..." \
        --prompt="> " \
        --pointer="›" \
        --color="header:italic:240,prompt:240,pointer:212,hl:#ff79c6,hl+:#ff79c6:underline" \
        --height=100%)

    if test -n "$selected"
        # Bỏ mã màu ANSI (nếu có) và lấy tên file/thư mục ở cột cuối cùng
        set -l file (echo "$selected" | string replace -r '\x1b\[[0-9;]*[a-zA-Z]' '' | string match -r '\S+$')
        
        # Chạy lại ll trên file/thư mục được chọn
        ll $file
    end
end
