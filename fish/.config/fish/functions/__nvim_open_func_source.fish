function __nvim_open_func_source
    # Lấy hàm được truyền từ tham số (hoặc từ commandline nếu không truyền)
    set -l current_cmd $argv[1]
    if test -z "$current_cmd"
        set current_cmd (commandline -b | string trim | string split -m 1 ' ')[1]
    end

    if test -n "$current_cmd"; and functions -q $current_cmd
        set -l func_file (functions --details $current_cmd)

        if test -f "$func_file"
            commandline -r "" 
            nvim $func_file
            commandline -f repaint
        else
            echo -e "\n[Lỗi] Hàm '$current_cmd' được định nghĩa trực tiếp, không có file lưu trữ."
            commandline -f repaint
        end
    else
        echo -e "\n[Lỗi] '$current_cmd' không phải là một hàm Fish shell hợp lệ!"
        commandline -f repaint
    end
end
