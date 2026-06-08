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
	# Gõ 'lt' để hiện cây thư mục bằng eza, có màu sắc, icon và đẩy thư mục lên đầu
	alias lt="eza --tree --level=2 --icons --group-directories-first"

	# Gõ 'lta' để hiện cây thư mục bốc sạch cả file ẩn kịch trần
	alias lta="eza --tree --level=2 --icons --group-directories-first -a"
	alias g="git"
	alias v="nvim"
	set -x BAT_THEME "Dracula"

	# set -gx FZF_DEFAULT_OPTS '--layout=reverse --border --preview-window=bottom:50%:hsplit:wrap'
	# fzf_configure_bindings --directory=\cf --history=\cj --variables=\cv --git_log=\cl --git_status=\cs --processes=\cp
	fzf_configure_bindings_custom --directory=\cx --find_files=\cy --history=\cj --variables=\cv --git_log=\cl --git_status=\ca --processes=\cp --recent=ctrl-shift-y
	# bind \ct __fzf_search_directory_custom
	# bind \cf __fzf_find_files_custom
	set -gx fzf_fd_opts --type=d --hidden --follow --exclude=.git --color=always
	set -gx LS_COLORS (cat ~/.config/fish/.ls_colors)
	# # Ép TẤT CẢ các tính năng fzf preview thư mục dùng eza lên màu + icon
	# set -gx fzf_preview_dir_cmd "eza --all --icons=always --color=always --grid"
	# # Ép TẤT CẢ các tính năng fzf preview file dùng bat lên màu True Color
	# set -gx fzf_preview_file_cmd "bat --style=numbers --color=always --line-range :100"

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

function glog --description "FZF Duyệt Git Log và Preview Commit bằng Delta"
    git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" | fzf \
        --ansi \
        --no-sort \
        --reverse \
        --header="[Git Log] Chọn commit để xem chi tiết" \
        --preview="git show --color=always {2} | delta --side-by-side --width=\$FZF_PREVIEW_COLUMNS"
end

function gdiff --description "FZF Git Diff Preview với Delta"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!"
        return 1
    end

    # Gọi FZF lấy danh sách file thay đổi, preview bằng git diff + delta
    git status -s | fzf \
        --no-sort \
        --reverse \
        --tiebreak=index \
        --header="[Git Diff] Chọn file để soi code thay đổi" \
        --preview="git diff --color=always {2} | delta --width=\$FZF_PREVIEW_COLUMNS" \
        --bind="ctrl-m:execute(nvim -d {2}; clear)" # Sửa dòng này: Thay +refresh bằng ; clear
end

function y
    if test (count $argv) -eq 0
        echo "Nhập tên bài hát nữa bạn ơi! Ví dụ: y lofi chill"
        return
    end

    echo "🔍 Đang bốc dữ liệu trực tiếp từ YouTube bằng yt-dlp..."

    # 1. yt-dlp lấy data
    # 2. jq parse thành TSV
    # 3. awk format dữ liệu và chèn các cột "|" ngăn cách bằng Tab (OFS='\t')
    # 4. column -t căn đều các cột theo Tab
    yt-dlp "ytsearch20:$argv" \
        --flat-playlist \
        --dump-json \
        --extractor-args "youtube:player_client=android" 2>/dev/null \
        | jq -r '[
            (.title // "Không rõ"), 
            (.channel // .uploader // "Không rõ"), 
            (.duration // 0), 
            (.view_count // 0), 
            .url
          ] | @tsv' \
        | awk -F '\t' -v OFS='\t' '
            function commas(n) {
                if (n == 0 || n == "null") return "N/A"
                r = ""
                while(length(n) > 3) {
                    r = "," substr(n, length(n)-2) r
                    n = substr(n, 1, length(n)-3)
                }
                return n r
            }
            {
                title = length($1) > 55 ? substr($1, 1, 52) "..." : $1
                channel = length($2) > 20 ? substr($2, 1, 17) "..." : $2
                
                m = int($3 / 60)
                s = int($3 % 60)
                time = sprintf("%d:%02d", m, s)
                
                views = commas($4)
                
                # In ra các trường cách nhau bởi Tab, tách riêng dấu "|" thành các cột độc lập để dễ căn lề
                print title, "|", channel, "|", time, "|", views, "|", $5
            }
        ' \
        | column -t -s (printf '\t') \
        | fzf --ansi --reverse --prompt="🎵 Chọn bài để quẩy: " \
        | read -l selected

    if test -n "$selected"
        # Lấy URL ở cột cuối cùng
        set -l video_url (echo $selected | awk '{print $NF}')
        
        # Lấy tiêu đề trước dấu "|" đầu tiên và xóa khoảng trắng 2 đầu
        set -l video_title (echo $selected | awk -F '\\|' '{print $1}')
        set video_title (string trim "$video_title")
        
        echo "▶️ Đang phát bài: $video_title"
        mpv --no-video "$video_url"
    else
        echo "Đã hủy chọn bài."
    end
end
