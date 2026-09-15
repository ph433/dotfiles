function fzfrecent -d "Tìm file dựa trên lịch sử mở trong Neovim (Dashboard Top 10)"
    set -l log_file "$HOME/.cache/nvim_recent.log"
    test -f "$log_file"; or return 1

    # 1. Gọi thẳng backend sh để chạy FZF UI
    set -l fzf_out (fzfrecent_file.sh "$log_file")
    test -z "$fzf_out"; and return

    # 2. Xử lý phím bấm và các dòng được chọn
    set -l key $fzf_out[1]
    set -l selected_lines $fzf_out[2..-1]
    test -z "$selected_lines"; and return

    # 3. Tách target_paths bằng hàm string tích hợp của Fish (loại bỏ fork awk)
    set -l target_paths
    for line in $selected_lines
        set -a target_paths (string split -m 1 ' │ ' -- $line)[2]
    end

    switch "$key"
        case right
            # Chèn tất cả đường dẫn đã chọn vào dòng lệnh
            set -l escaped_paths
            for path in $target_paths
                set -a escaped_paths (string escape -- "$path")
            end
            commandline -i (string join " " $escaped_paths)" "

            # Ghi log background một lần duy nhất
            fish -c '
                for p in $argv
                    log_recent_file "$p"
                    fzf_score_file.sh "$p"
                end
            ' -- $target_paths >/dev/null 2>&1 &
            disown

        case enter
            set -l target "$target_paths[1]"
            test -z "$target"; and return

            # Nếu là thư mục thì cd vào, nếu là file thì mở bằng Neovim
            if test -d "$target"
                cd "$target"
            else if test -f "$target"
                nvim "$target"
            end
    end

    commandline -f repaint 2>/dev/null
end
