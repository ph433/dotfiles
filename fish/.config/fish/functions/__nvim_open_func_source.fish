function __nvim_open_func_source
    # Lấy từ đầu tiên trên dòng lệnh (thường là tên hàm/lệnh)
    set -l current_cmd (commandline -b | string trim | string split -m 1 ' ')[1]

    # Kiểm tra xem từ đó có phải là một hàm (function) trong Fish không
    if test -n "$current_cmd"; and functions -q $current_cmd
        # Tìm đường dẫn file chứa định nghĩa hàm này
        set -l func_file (functions --details $current_cmd)

        # Nếu tìm thấy file thực tế, tiến hành mở bằng nvim
        if test -f "$func_file"
            commandline -r "" # Xóa rác trên terminal trước khi mở
            nvim $func_file
            commandline -f repaint # Vẽ lại prompt sau khi thoát nvim
        else
            echo -e "\n[Lỗi] Hàm '$current_cmd' được định nghĩa trực tiếp, không có file lưu trữ."
            commandline -f repaint
        end
    else
        echo -e "\n[Lỗi] '$current_cmd' không phải là một hàm Fish shell hợp lệ!"
        commandline -f repaint
    end
end
