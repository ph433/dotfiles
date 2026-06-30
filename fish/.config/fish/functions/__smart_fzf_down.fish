function __smart_fzf_down --description "Chỉ gọi FZF khi Fish không mở bảng Search hoặc chế độ sửa code"
    # 1. Lấy vị trí dòng hiện tại của con trỏ và tổng số dòng trên buffer
    set -l cl_line (commandline -L)
    set -l cl_count (count (commandline))

    # 2. Kiểm tra các điều kiện né FZF:
    # - Đang mở bảng Search (paging-mode)
    # - HOẶC con trỏ chưa nằm ở dòng cuối cùng của một khối code nhiều dòng (như khi trong funced)
    if commandline --paging-mode; or test $cl_line -lt $cl_count
        # Trả lại tính năng gốc: Di chuyển con trỏ xuống dòng dưới trong menu hoặc block code
        commandline -f down-line
    else
        # Nếu Terminal trống trải bình thường ở dòng cuối: Kích hoạt FZF Zoxide của bạn
        fzf_menu
    end
end
