function makebkdebug --description "Bật/Tắt đuôi .bk cho file được chọn bằng fzf"
    # 1. Lấy dữ liệu từ ll truyền qua fzf
    set -l selected (ll | fzf -m \
        --ansi \
        --reverse \
        --header="[Tab]: Chọn nhiều | [Phím Phải / Enter]: Toggle .bk" \
        --prompt="> " \
        --pointer="›" \
        --color="header:italic:240,prompt:240,pointer:212,hl:#ff79c6,hl+:#ff79c6:underline" \
        --height=100% \
        --bind="right:accept")

    # 2. Xử lý đổi tên hoặc khôi phục
    if test -n "$selected"
        for line in $selected
            # Lấy phần tử cuối cùng trong dòng output của ll (tên file/thư mục)
            set -l item (echo $line | string match -r '\S+$')

            if test -n "$item" -a -e "$item"
                if string match -q '*.bk' "$item"
                    # Nếu đã có đuôi .bk -> Xóa đuôi .bk
                    set -l original_name (string replace -r '\.bk$' '' "$item")
                    mv "$item" "$original_name"
                    echo "Đã khôi phục: $item -> $original_name"
                else
                    # Nếu chưa có -> Thêm đuôi .bk
                    mv "$item" "$item.bk"
                    echo "Đã sao lưu:   $item -> $item.bk"
                end
            end
        end
    end
end
