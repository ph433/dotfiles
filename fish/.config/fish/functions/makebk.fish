function makebk --description "Bật/Tắt đuôi .bk cho file được chọn bằng fzf"
    # 1. Lấy dữ liệu từ ll truyền qua fzf (giữ nguyên True Color)
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
            # Tách lấy tên file gốc từ dòng output của ll
            set -l item (echo "$line" | string match -r '(\S+)(?:\s+->.*)?$' | tail -n 1)

            if test -n "$item" -a -e "$item"
                # Nếu tên đã kết thúc bằng .bk -> Khôi phục về tên cũ
                if string match -q '*.bk' "$item"
                    set -l original_name (string replace -r '\.bk$' '' "$item")
                    mv "$item" "$original_name"
                    echo "Đã khôi phục: $item -> $original_name"
                else
                    # Nếu chưa có .bk -> Đổi tên thành .bk
                    mv "$item" "$item.bk"
                    echo "Đã sao lưu:  $item -> $item.bk"
                end
            end
        end
    end
end
