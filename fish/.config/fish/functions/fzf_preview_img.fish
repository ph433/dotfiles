function fzf_preview_img --description "FZF preview hình ảnh sử dụng Ueberzugpp trên Fish shell"
    # 1. Định nghĩa file tạm và đường ống FIFO
    set -l tmp_dir (mktemp -d)
    set -x FIFO_UEBERZUG "$tmp_dir/fzf-ueberzug-pipe"
    mkfifo "$FIFO_UEBERZUG"

    # 2. KHẮC PHỤC LỖI TREO: Chạy ueberzugpp qua sh -c để tránh Fish shell bị block
    sh -c "ueberzugpp layer --parser json --output x11 < \"$FIFO_UEBERZUG\"" &
    set -l ueberzug_pid $last_pid

    # 3. Mở luồng ghi giả để giữ FIFO mở liên tục
    sh -c "sleep infinity > \"$FIFO_UEBERZUG\"" &
    set -l sleep_pid $last_pid

    # 4. Tạo một script phụ bằng bash để fzf gọi
    set -l preview_script "$tmp_dir/preview.sh"
    
    echo '#!/usr/bin/env bash
file_path="$1"

# FZF tự động truyền các biến môi trường này
x=${FZF_PREVIEW_LEFT:-0}
y=${FZF_PREVIEW_TOP:-0}
w=${FZF_PREVIEW_COLUMNS:-0}
h=${FZF_PREVIEW_LINES:-0}

if [[ -n "$file_path" && -p "$FIFO_UEBERZUG" ]]; then
    printf "{\"action\": \"add\", \"identifier\": \"fzf_preview\", \"x\": %d, \"y\": %d, \"width\": %d, \"height\": %d, \"scaler\": \"fit_contain\", \"path\": \"%s\"}\n" "$x" "$y" "$w" "$h" "$file_path" > "$FIFO_UEBERZUG"
else
    if [[ -p "$FIFO_UEBERZUG" ]]; then
        printf "{\"action\": \"remove\", \"identifier\": \"fzf_preview\"}\n" > "$FIFO_UEBERZUG"
    fi
fi
' > "$preview_script"
    chmod +x "$preview_script"

    # 5. Chạy FZF và nạp danh sách file hình ảnh (Đã sửa lỗi ngoặc đơn)
    set -l selected_file (fd --type file --extension png --extension jpg --extension jpeg --extension webp . | \
    env FIFO_UEBERZUG="$FIFO_UEBERZUG" fzf \
        --preview "$preview_script {}" \
        --preview-window "right:60%")

    # 6. Dọn dẹp hệ thống sau khi thoát fzf
    if test -p "$FIFO_UEBERZUG"
        printf '{"action": "remove", "identifier": "fzf_preview"}\n' > "$FIFO_UEBERZUG"
    end
    
    # Giết các tiến trình ngầm
    if test -n "$ueberzug_pid"
        kill $ueberzug_pid 2>/dev/null
    end
    if test -n "$sleep_pid"
        kill $sleep_pid 2>/dev/null
    end
    
    rm -rf "$tmp_dir"

    # Trả kết quả file đã chọn ra terminal nếu có
    if test -n "$selected_file"
        echo "Bạn đã chọn: $selected_file"
    end
end
