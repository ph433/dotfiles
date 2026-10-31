function diff_clip
    # Sử dụng psub để biến output của copyq thành file tạm cho diff đọc
    # Thêm -u để hiển thị định dạng trực quan (có dấu + - rõ ràng)
    /usr/bin/diff -u -w (copyq read 1 | psub) (copyq read 0 | psub) | delta
end
