function __fzf_search_directory_custom --description "Search the current directory (Custom version with 100% height and specialized preview)"
    # Sử dụng fd trực tiếp để quét nhanh
    set -f fd_cmd (command -v fdfind || command -v fd  || echo "fd")
    set -f --append fd_cmd --color=always $fzf_fd_opts

    # ĐÃ THÊM --height=100% VÀO ĐÂY ĐỂ BUNG TOÀN MÀN HÌNH
    set -f fzf_arguments --height=100% --multi --ansi --preview-window=bottom:50% $fzf_directory_opts
    set -f token (commandline --current-token)
    
    set -f expanded_token (eval echo -- $token)
    set -f unescaped_exp_token (string unescape -- $expanded_token)

    if string match --quiet -- "*/" $unescaped_exp_token && test -d "$unescaped_exp_token"
        set --append fd_cmd --base-directory=$unescaped_exp_token
        # 🎯 SỬA CHỖ 1: Đổi sang hàm custom và sửa lại cách bao bọc nháy đơn để FZF truyền tham số chính xác
        set --prepend fzf_arguments --prompt="Directory $unescaped_exp_token> " --preview "_fzf_preview_dir_custom '$unescaped_exp_token{}'"
        set -f file_paths_selected $unescaped_exp_token($fd_cmd 2>/dev/null | _fzf_wrapper $fzf_arguments)
    else
        # 🎯 CHỖ 2 ĐÃ ĐÚNG: Giữ nguyên con hàng chuyên dụng của bạn
        set --prepend fzf_arguments --prompt="Directory> " --query="$unescaped_exp_token" --preview '_fzf_preview_dir_custom {}'
        set -f file_paths_selected ($fd_cmd 2>/dev/null | _fzf_wrapper $fzf_arguments)
    end

    if test $status -eq 0
        commandline --current-token --replace -- (string escape -- $file_paths_selected | string join ' ')
    end

    commandline --function repaint
end
