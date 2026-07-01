if status is-interactive
    # --- Biệt danh (Aliases & Abbreviations) ---
    alias cat="bat"
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -lah --icons --group-directories-first"
    alias lt="eza --tree --level=2 --icons --group-directories-first"
    # alias lta="eza --tree --level=2 --icons --group-directories-first -a --color=always"
    
    # alias grep="rg"
    alias find="fd"
    alias g="git"
    alias v="nvim"

    # --- Khởi tạo ứng dụng (App Inits) ---
    zoxide init fish | source
    atuin init fish | source
    starship init fish | source
end

function __log_recent_dir --on-variable PWD
    # Tránh kích hoạt log khi đang ở trong subshell hoặc các lệnh thay đổi tạm thời
    if status --is-command-substitution
        return
    end

    # Kiểm tra xem hàm log_recent_dir có đang bận xử lý hay không
    if set -q __is_logging_dir
        return
    end

    # Đặt cờ khóa (Lock) trước khi gọi hàm xử lý
    set -g __is_logging_dir 1

    log_recent_dir

    # Xóa cờ khóa sau khi xử lý xong
    set -e __is_logging_dir
end

# Xử lý cho phím mũi tên Phải (Right Arrow)
function _right_or_fzf_recent
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        fzfrecentdir
        commandline -f repaint
    else
        # Hành vi mặc định: di chuyển con trỏ sang phải
        commandline -f forward-char
    end
end

# Xử lý cho phím mũi tên Trái (Left Arrow)
function _left_or_fzf_find
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        fzfrecent
        commandline -f repaint
    else
        # Hành vi mặc định: di chuyển con trỏ sang trái
        commandline -f backward-char
    end
end

# Xử lý cho phím Enter (đã làm ở bước trước)
function _enter_or_fzf_zoxide
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        __fzf_zoxide_custom
        commandline -f repaint
    else
        commandline -f execute
    end
end

# Xử lý cho phím Home
function _home_or_fzf_search_dir
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        __fzf_find_files_custom
        commandline -f repaint
    else
        commandline -f beginning-of-line
    end
end

# Xử lý cho phím End
function _end_or_fzf_find
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        __fzf_search_directory_custom
        commandline -f repaint
    else
        commandline -f end-of-line
    end
end


# function _up_or_fzf_history
#     set -l current_cmd (commandline | string trim)
#     if test -z "$current_cmd"
#         # Gọi hàm tìm kiếm lịch sử bằng fzf nếu dòng lệnh trống
#         _fzf_search_history_custom
#         commandline -f repaint
#     else
#         # Di chuyển con trỏ lên hoặc tìm lịch sử mặc định của Fish nếu đang có chữ
#         commandline -f up-line
#     end
# end

# Xử lý cho phím Space (Khoảng trắng)
function _space_or_fzf_recent
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        __fzf_file_recent
        commandline -f repaint
    else
        # Thêm dấu cách bình thường nếu dòng lệnh đang có chữ
        commandline -i ' '
    end
end

function _backspace_become_ll
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        # Thay thế dòng lệnh bằng 'll' và thực thi ngay lập tức
        commandline -r 'll'
        commandline -f execute
    else
        # Nếu dòng lệnh đang có chữ, giữ nguyên hành vi hủy/thoát mặc định của Esc
        commandline -f backward-delete-char
    end
end

function _del_or_become_lta
	set -l current_cmd (commandline | string trim)
	if test -z "$current_cmd"
		commandline -r 'lta'
		commandline -f execute
	else
		# Nhánh else: đóng vai trò làm phím Del như bình thường
		commandline -f delete-char
	end
end

# Xử lý nâng cao cho Backspace (hoặc Ctrl+Z)
function _escape_toggle_home
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        if test "$PWD" = "$HOME"
            # Thử cd - trước
            if not cd - 2>/dev/null
                set -l log_file "$HOME/.cache/dir_recent.log"
                if test -f "$log_file"
                    # Đọc dòng đầu tiên, dùng string split để cắt lấy cột thứ 2
                    set -l log_line (head -n 1 "$log_file")
                    set -l recent_dir (string split -m 1 ' ' $log_line)[2]

                    # Nếu cắt thành công và thư mục hợp lệ thì cd vào
                    if test -n "$recent_dir"; and test -d "$recent_dir"
                        cd "$recent_dir"
                    end
                end
            end
        else
            cd ~
        end
        commandline -f repaint
    else
        commandline -f backward-kill-word
    end
end

function fish_user_key_bindings
    bind enter _enter_or_fzf_zoxide
    bind right _right_or_fzf_recent
    bind left _left_or_fzf_find
    bind home _home_or_fzf_search_dir
    bind end _end_or_fzf_find
    bind space _space_or_fzf_recent
    bind escape '__fish_exec_in_main_mode_only cancel _escape_toggle_home'
    bind backspace _backspace_become_ll
    # bind up _up_or_fzf_history
    bind delete _del_or_become_lta
end

function _fzf_history_format_ago
    # Lấy timestamp hiện tại
    set -l current_time (date +%s)
    
    # Đọc dữ liệu history từ stdin và xử lý bằng awk tách biệt, không bị lỗi nháy đơn
    awk -v current_time="$current_time" -F " │ " '
    BEGIN {  
        # Xử lý chuỗi kết thúc bằng ký tự NULL (\0) từ history --null
        RS="\0"; ORS="\0" 
    } 
    {
        if ($1 == "") next;
        diff = current_time - $1;
        if (diff < 0) diff = 0;
        
        if (diff < 60) time_str = diff "s ago";
        else if (diff < 3600) time_str = int(diff/60) "m ago";
        else if (diff < 86400) time_str = int(diff/3600) "h ago";
        else time_str = int(diff/86400) "d ago";
        
        # Định dạng cột thời gian rộng 12 ký tự để canh lề thẳng hàng
        printf "%-12s │ %s\n", time_str, $2;
    }'
end
