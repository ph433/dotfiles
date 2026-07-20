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

    # Nếu thư mục hiện tại là $HOME thì bỏ qua không ghi log
    if test "$PWD" = "$HOME"
        return
    end

    # Kiểm tra xem hàm log_recent_dir có đang bận xử lý hay không
    if set -q __is_logging_dir
        return
    end

    # Đặt cờ khóa (Lock) trước khi gọi hàm xử lý
    set -g __is_logging_dir 1

    log_recent_dir
    # ~/dwm-flexipatch/dwm_status_update.sh &
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

function _escape_handler
	# Kiểm tra xem bảng gợi ý có đang mở không
	if commandline --paging-mode
		# Nếu đang ở bảng chọn, Esc có tác dụng đóng bảng/hủy chọn
		commandline -f cancel
	else
		set -l current_cmd (commandline | string trim)
		commandline -f complete-and-search
	end
end

function _crl-a_or_become_pwd
    set -l current_cmd (commandline | string trim)
    if test -z "$current_cmd"
        commandline -r 'pwd'
        commandline -f execute
    else
        # Nhánh else: Hoạt động như Ctrl + A mặc định (về đầu dòng)
        commandline -f clear-screen
    end
end

function _down_fzf_recent_or_menu
    # Lấy nội dung dấu nhắc lệnh hiện tại (đã xóa khoảng trắng thừa 2 đầu)
    set -l current_cmd (commandline | string trim)

    # TRƯỜNG HỢP 1: Dấu nhắc lệnh đang TRỐNG
    if test -z "$current_cmd"
        
        if test "$PWD" = "$HOME"
            # 1a. Nếu đang ở HOME -> cd vào thư mục gần nhất trong log
            set -l log_file "$HOME/.cache/dir_recent.log"
            if test -f "$log_file"
                # ĐÃ FIX TẠI ĐÂY: Thêm [-1..1] để đọc mảng từ dưới lên trên (ưu tiên thư mục mới nhất)
                set -l recent_dirs (string replace -r '^[0-9]+\s+' '' < "$log_file")[-1..1]
                
                for dir in $recent_dirs
                    if test -d "$dir"; and test "$dir" != "$HOME"
                        cd "$dir"
                        commandline -f repaint
                        return
                    end
                end
            end
        else
            # 1b. Nếu KHÔNG ở HOME -> trở về HOME
            cd "$HOME"
            commandline -f repaint
        end

    # TRƯỜNG HỢP 2: Dấu nhắc lệnh ĐANG GÕ (có chữ)
    else
        # Gọi menu fzf
        fzf_menu
    end
end

function __nvim_open_latest_recent
    set -l log_file "$HOME/.cache/nvim_recent.log"
    
    if test -f $log_file
        # Sắp xếp cột 1 (timestamp) giảm dần, lấy dòng đầu tiên, và cắt bỏ cột timestamp để lấy đường dẫn file
        set -l latest_file (sort -rn $log_file | head -n 1 | string replace -r '^\d+\s+' '')

        if test -n "$latest_file"; and test -f $latest_file
            # Xóa dòng hiện tại trên terminal trước khi mở nvim để tránh rác lệnh
            commandline -r ""
            nvim $latest_file
            # Ép Fish vẽ lại prompt sau khi thoát nvim
            commandline -f repaint
        else
            echo -e "\n[Lỗi] File không tồn tại hoặc đường dẫn trống: $latest_file"
            commandline -f repaint
        end
    else
        echo -e "\n[Lỗi] Không tìm thấy file log: $log_file"
        commandline -f repaint
    end
end

function fish_user_key_bindings
    bind enter _enter_or_fzf_zoxide
    bind down "__fish_exec_in_main_mode_only down-line _down_fzf_recent_or_menu"
    bind right _right_or_fzf_recent
    bind insert __nvim_open_latest_recent
    bind left _left_or_fzf_find
    bind home _home_or_fzf_search_dir
    bind end _end_or_fzf_find
    bind space _space_or_fzf_recent
    bind escape _escape_handler
    bind backspace _backspace_become_ll
    bind delete _del_or_become_lta
    bind ctrl-a _crl-a_or_become_pwd
end
