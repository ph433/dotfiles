# Mấy cái cấu hình biến môi trường hệ thống (nếu có) thì để ở ngoài này
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.fzf/bin

# 1. Hàm bổ trợ gánh phần hiển thị (Thay thế hoàn toàn cho file preview.sh của tác giả)
function _fzf_preview_helper
    # 1. Tách chuỗi dữ liệu đầu vào để lấy file và dòng
    set -l pieces (string split ":" $argv[1])
    set -l file $pieces[1]
    set -l line $pieces[2]
    
    # 2. Lấy toàn bộ cụm từ khóa bạn gõ (bao gồm cả các từ cách nhau bằng dấu cách)
    set -l search_query $argv[2]

    if test -n "$line" -a -f "$file"
        # Chạy lệnh bat lấy nội dung thô có màu trước
        set -l preview_output (bat --style=numbers --color=always --highlight-line $line "$file" 2>/dev/null)

        if test -n "$search_query"
            # Tách cụm tìm kiếm thành danh sách các từ độc lập dựa trên dấu cách
            set -l tokens (string split " " $search_query)

            for token in $tokens
                if test -n "$token"
                    # Duyệt qua từng từ, đắp mã màu ANSI nền vàng chữ đen (\e[30;43m) lên từ đó
                    set preview_output (string replace -a -i "$token" (printf "\e[30;43m$token\e[0m") $preview_output)
                end
            end
        end

        # In kết quả cuối cùng đã được bôi màu ra màn hình preview
        echo -e "$preview_output" | string match -r -v '^$'
    else if test -f "$file"
        bat --style=numbers --color=always "$file" 2>/dev/null
    end
end

# 2. Hàm TÌM KIẾM ĐỘNG CHÍNH CHỦ (Bản dịch chuẩn từ file gốc fzf GitHub sang Fish)
function fif
    # Giải pháp tối thượng: 
    # -L: Quét qua symlinks
    # --no-messages: Nuốt sạch lỗi ngầm để tránh nghẽn fzf
    # --: Chặn lỗi dấu gạch ngang
    set -l RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case --hidden --no-ignore -L --no-messages --"

    # Sử dụng biến môi trường FZF_DEFAULT_COMMAND để fzf tự hiểu luồng nạp động 
    # Cách này giúp loại bỏ hoàn toàn việc dùng nháy bọc {q} trong chuỗi --bind phức tạp!
    fzf --ansi --disabled --query "$argv" \
        --layout=reverse --border --preview-window=right:60% \
        --prompt="Live Grep> " \
        --bind "start:reload:$RG_PREFIX {q} || true" \
        --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
        --preview "_fzf_preview_helper {} {q}"
end

if status is-interactive
	# Khai báo để Fish nhận biết các công cụ cài qua Cargo và Script thủ công
	set -g fish_greeting ""
	# Các Alias viết tắt
	# --- Các Alias viết tắt ---

	# Cấu hình cho BAT (Chỉ alias lệnh cat sang bat, không alias ngược)
	if type -q bat
		alias cat="bat"
	end

	# Cấu hình cho EZA (Thay thế hoàn toàn cho ls)
	if type -q eza
		alias ls="eza --icons --group-directories-first"
		alias ll="eza -lah --icons --group-directories-first"
	else
		alias ll="ls -lah"
	end
	# Viết tắt cho ripgrep (Tìm chữ)
	if type -q rg
		alias grep="rg"
	end

	# Viết tắt cho fd-find (Tìm file)
	if type -q fd
		alias find="fd"
	end

	# if type -q zoxide
	# 	alias cd="z"
	# end

	alias g="git"
	alias v="nvim"
	set -x BAT_THEME "Dracula"
	# set -gx FZF_DEFAULT_OPTS '--layout=reverse --border --preview-window=bottom:50%:hsplit:wrap'
	# fzf_configure_bindings --directory=\cf --history=\cj --variables=\cv --git_log=\cl --git_status=\cs --processes=\cp
	fzf_configure_bindings_custom --directory=\ct --find_files=\cf --history=\cj --variables=\cv --git_log=\cl --git_status=\cs --processes=\cp
	# bind \ct __fzf_search_directory_custom
	# bind \cf __fzf_find_files_custom
	set -gx fzf_fd_opts --type=d --hidden --follow --exclude=.git
	set -gx fzf_configure_options --layout=reverse --border --preview-window=bottom:50%
	# Nạp phím tắt chính chủ từ nguồn cài đặt fzf
	# if test -f ~/.fzf/shell/key-bindings.fish
	# 	source ~/.fzf/shell/key-bindings.fish
	# 	fzf_key_bindings
	# end
	# Tích hợp công cụ Rust
	if type -q zoxide
		zoxide init fish | source
	end
	if type -q atuin
		atuin init fish | source
	end
	# Bộ giao diện (Nếu bạn có dùng Starship)
	if type -q starship
		starship init fish | source
	end
end
