function __smart_key_exec --description "Gõ phím tắt thông minh cho Fish Shell"
    # Thêm [1] để đảm bảo luôn lấy giá trị đầu tiên (số nguyên duy nhất)
    set -l cursor_pos (commandline -C)[1]
    set -l cmd_len (string length -- (commandline))[1]
    set -l key $argv[1]
    set -l target_cmd $argv[2]
    set -l current_cmd (commandline | string trim)
    
    if test -z "$current_cmd"
        # 1. Khi dòng lệnh RỖNG:
        switch $key
            case ctrl-a backspace delete ctrl-backspace ctrl-delete
                # Chạy pwd (hoặc target_cmd) chuẩn qua commandline execute
                commandline -r "$target_cmd"
                commandline -f execute
            case down
                cd_smart_toggle
            case up
                history_fzf
            case 'end'
                __fzf_search_directory_custom
            case home
                __fzf_find_files_custom
            case right
                fzfrecentdir
            case left
                fzfrecent
            case space
                __fzf_file_recent
            case enter
                nvim_open_recent
            case ctrl-enter
                nvim_open_recent_nano
            case escape
                __fish_fzf_complete
            case insert
                __fzf_zoxide_custom
            case pageup
                fdf
            case pagedown
                fdd
            case '*'
                # Các phím số (1, 2, 3...): Eval trực tiếp & repaint
                eval $target_cmd
                commandline -f repaint
        end
    else
        switch $key
            case ctrl-a
                commandline -f clear-screen
            case ctrl-backspace
                commandline -f backward-kill-token
            case ctrl-delete
                commandline -f kill-token
            case down
                fzf_menu
            case up
                history_fzf
            case 'end'
                if test "$cursor_pos" -eq "$cmd_len"
                    __fzf_search_directory_custom
                else
                    commandline -f end-of-line
                end
            case home
                if test "$cursor_pos" -eq 0
                    __fzf_find_files_custom
                else
                    commandline -f beginning-of-line
                end
            case right
               # Sửa lại logic test an toàn
               if test "$cursor_pos" -eq "$cmd_len"
                   # 1. Lưu lại nội dung buffer hiện tại
                   set -l old_cmd (commandline)
                   set -l old_len (string length -- "$old_cmd")[1]
        
                   # 2. Thử chấp nhận autosuggestion (nếu có chữ mờ)
                   commandline -f accept-autosuggestion
        
                   # 3. Kiểm tra xem sau khi bấm accept thì buffer có dài thêm ra không
                   if test (string length -- (commandline))[1] -eq "$old_len"
                       fzfrecentdir
                   end
               else
                   # Nếu đang ở giữa dòng -> Tiến con trỏ sang phải 1 ký tự
                   commandline -f forward-char
               end               
            case left
                if test "$cursor_pos" -eq 0
                    fzfrecent
                else
                    commandline -f backward-char
                end
            case space
                commandline -i ' '
            case enter
                commandline -f execute
            case ctrl-enter
                commandline -f forward-bigword
            case delete
                commandline -f delete-char
            case backspace
                commandline -f backward-delete-char
            case escape
                __fish_fzf_complete
            case insert
                __nvim_open_func_source
            case pageup
                fdf
            case pagedown
                fdd
            case '*'
                commandline -i "$key"
        end
    end
end