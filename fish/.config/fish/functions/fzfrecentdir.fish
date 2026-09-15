function fzfrecentdir -d "Tìm thư mục dựa trên lịch sử di chuyển (Top 50)"
    set -l log_file "$HOME/.cache/dir_recent.log"
    test -f "$log_file"; or return 1

    # 1. Chạy backend fzfrecent_dir.sh và hứng kết quả
    set -l fzf_out (fzfrecent_dir.sh "$log_file")
    test -z "$fzf_out"; and return

    # 2. Bóc tách phím bấm và các dòng được chọn
    set -l key $fzf_out[1]
    set -l selected_lines $fzf_out[2..-1]
    test -z "$selected_lines"; and return

    # 3. Tách target_paths bằng hàm string tích hợp của Fish (không gọi awk)
    set -l target_paths
    for line in $selected_lines
        set -a target_paths (string split -m 1 ' │ ' -- $line)[2]
    end

    switch "$key"
        case right
            set -l escaped_paths
            for path in $target_paths
                set -a escaped_paths (string escape -- "$path")
            end
            commandline -i (string join " " $escaped_paths)" "

            # Gom log vào một background process duy nhất
            sh -c '
                log_file="$1"
                shift
                log_add.sh "$log_file" "$@"
            ' _ "$log_file" $target_paths >/dev/null 2>&1 &
            disown

        case enter
            if test -d "$target_paths[1]"
                cd "$target_paths[1]"
            end
    end

    commandline -f repaint 2>/dev/null
end
