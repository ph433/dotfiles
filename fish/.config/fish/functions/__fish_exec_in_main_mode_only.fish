function __fish_exec_in_main_mode_only --description "Chỉ chạy lệnh custom ở giao diện chính, ngược lại trả về tính năng gốc của phím"
    # Lấy tham số đầu tiên làm hành động fallback (ví dụ: down-line, up-line, backward-char...)
    set -l fallback_action $argv[1]
    
    # Các tham số còn lại là lệnh custom muốn chạy (ví dụ: fzf_menu, zi...)
    set -l custom_command $argv[2..-1]

    set -l cl_line (commandline -L)
    set -l cl_count (count (commandline))

    # Nếu đang ở chế độ đặc biệt (Search hoặc sửa code nhiều dòng)
    if commandline --paging-mode; or test $cl_line -lt $cl_count
        # Trả lại tính năng gốc được chỉ định
        commandline -f $fallback_action
    else
        # Nếu ở giao diện chính (Main Mode) thì chạy lệnh custom
        if count $custom_command > 0
            $custom_command
        end
    end
end
