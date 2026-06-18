function fzfrecent -d "Tìm file dựa trên lịch sử mở trong Neovim"
    set log_file "$HOME/.cache/nvim_recent.log"

    # Kiểm tra xem file log có tồn tại không
    if not test -f "$log_file"
        echo "Chưa có dữ liệu lịch sử file."
        return 1
    end

    # Dùng AWK để lọc:
    # 1. Quét qua file log, lưu thời gian ($1) vào mảng với key là đường dẫn ($2).
    # 2. Mảng sẽ tự ghi đè thời gian cũ bằng thời gian mới nhất.
    # 3. END block in ra kết quả.
    # Sau đó sort -nr (mới nhất lên trên) và cut -d' ' -f2- (bỏ cột thời gian, chỉ giữ đường dẫn)
    set -l cmd_list "awk '{map[\$2] = \$1} END {for (path in map) print map[path], path}' $log_file | sort -nr | cut -d' ' -f2-"

    # Đưa danh sách vào fzf
    set -l selected_file (eval $cmd_list | fzf \
        --prompt="🕒 Nvim Recent> " \
        --tiebreak=index \
        --preview="bat --color=always {} 2>/dev/null || cat {}" \
        --layout=reverse \
        --height=80%)

    # Mở file nếu người dùng có chọn
    if test -n "$selected_file"
        nvim "$selected_file"
    end
end
