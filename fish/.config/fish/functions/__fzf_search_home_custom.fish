function __fzf_search_home_custom --description "Search the Home directory (Custom version with 100% height and specialized preview)"
    # 1. Sử dụng fd trực tiếp để quét nhanh
    set -f fd_cmd (command -v fdfind || command -v fd  || echo "fd")
    set -f --append fd_cmd --color=always $fzf_fd_opts

    # 2. Định cấu hình FZF bung toàn màn hình 100%
    set -f fzf_arguments --height=100% --multi --ansi --preview-window=bottom:50% $fzf_directory_opts
    set -f token (commandline --current-token)
    
    set -f expanded_token (eval echo -- $token)
    set -f unescaped_exp_token (string unescape -- $expanded_token)

    # 3. Ép lệnh fd luôn quét từ thư mục Home ($HOME)
    set --append fd_cmd --base-directory=$HOME

    # Cấu hình prompt và sửa lại nháy kép để truyền $HOME trực tiếp vào preview (Fix mất màu)
    set --prepend fzf_arguments --prompt="Search Home> " --query="$unescaped_exp_token" --preview "_fzf_preview_dir_custom $HOME/{}"
    
    # Thực thi và dùng eval để giữ nguyên màu ANSI qua pipe (Fix mất màu)
    set -f file_paths_selected (eval $fd_cmd 2>/dev/null | _fzf_wrapper $fzf_arguments)

    # 4. Nếu chọn thành công, bổ sung lại đường dẫn tuyệt đối cho các file đã chọn
    if test $status -eq 0 && test -n "$file_paths_selected"
        set -f absolute_paths
        for path in $file_paths_selected
            set --append absolute_paths "$HOME/$path"
        end
        commandline --current-token --replace -- (string escape -- $absolute_paths | string join ' ')
    end

    commandline --function repaint
end
