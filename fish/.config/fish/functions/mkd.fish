function mkd
    if test (count $argv) -gt 0
        set dir $argv[1]
    else
        set dir (gum input --placeholder "Nhập tên thư mục muốn tạo...")
    end

    if test -z "$dir"
        gum style --foreground 196 "⚠️ Đã hủy: Chưa nhập tên thư mục!"
        return 1
    end

    # Chạy mkdir và ẩn stderr chuẩn để dùng gum thông báo lỗi đẹp hơn
    if mkdir -p "$dir" 2>/dev/null
        gum style --foreground 212 --bold "✨ Đã tạo thư mục: $dir"
    else
        gum style --foreground 196 --bold "❌ Không thể tạo thư mục '$dir'!"
    end
end
