# Mấy cái cấu hình biến môi trường hệ thống (nếu có) thì để ở ngoài này

if status is-interactive

	# Khai báo để Fish nhận biết các công cụ cài qua Cargo và Script thủ công
	fish_add_path $HOME/.cargo/bin
	fish_add_path $HOME/.local/bin
	fish_add_path $HOME/.fzf/bin
	set -g fish_greeting ""

	# Các Alias viết tắt
	alias bat="batcat"
	alias g="git"
	alias v="nvim"

	# Tích hợp công cụ Rust
	zoxide init fish | source

	if type -q atuin
		atuin init fish | source
	end

	# Bộ giao diện (Nếu bạn có dùng Starship)
	# starship init fish | source
end
