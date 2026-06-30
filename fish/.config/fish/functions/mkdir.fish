function mkdir -d "Tạo thư mục và lưu vào lịch sử dir_recent"
    # 1. Chạy lệnh mkdir gốc của hệ thống với các tham số truyền vào
    command mkdir $argv
    set -l exit_status $status

    # 2. Nếu tạo thư mục thành công (exit code = 0), tiến hành ghi log
    if test $exit_status -eq 0
        # Duyệt qua các tham số để tìm tên thư mục (bỏ qua các cờ như -p, -v)
        for arg in $argv
            # Thêm -- để chặn lỗi nuốt cờ của lệnh string match
            if not string match -q -- "-*" $arg
                
                # 🚀 GỌI ĐỒNG BỘ MODULE MỚI Ở ĐÂY:
                # Không cần realpath hay tự gõ echo nữa, log_recent_dir tự lo hết!
                log_recent_dir "$arg"
                
            end
        end
    end

    # 3. Trả về đúng exit code của lệnh mkdir gốc
    return $exit_status
end
