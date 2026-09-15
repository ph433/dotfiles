function fzfrecentdir -d "Tìm thư mục dựa trên lịch sử di chuyển (Top 50)"
    set -l log_file "$HOME/.cache/dir_recent.log"
    test -f "$log_file"; or return 1

    # 1. Pipe trực tiếp từ hàm feed vào FZF ngay trong session Fish
    set -l fzf_out (_fzfrecent_feed "$log_file" | fzf \
        -m \
        --prompt="📁 Recent Dir> " \
        --delimiter=' │ ' \
        --nth=2.. \
        --tiebreak=index \
        --preview="eza --tree --level=1 --icons --color=always {2} 2>/dev/null || ls -la {2}" \
        --preview-window="bottom:60%:hidden" \
        --expect=right,enter \
        --layout=reverse \
        --height=100%)

    test -z "$fzf_out"; and return

    # 2. Bóc tách phím bấm và các dòng được chọn
    set -l key $fzf_out[1]
    set -l selected_lines $fzf_out[2..-1]
    test -z "$selected_lines"; and return

    # 3. Tách target_paths bằng hàm string tích hợp của Fish
    set -l target_paths
    for line in $selected_lines
        set -a target_paths (string split -m 1 ' │ ' -- $line)[2]
    end

    switch "$key"
        case right
            # Chèn các đường dẫn đã chọn vào dòng lệnh
            set -l escaped_paths
            for path in $target_paths
                set -a escaped_paths (string escape -- "$path")
            end
            commandline -i (string join " " $escaped_paths)" "

            # Ghi log background bằng log_add.sh
            sh -c '
                log_file="$1"
                shift
                log_add.sh "$log_file" "$@"
            ' _ "$log_file" $target_paths >/dev/null 2>&1 &
            disown

        case enter
            set -l target "$target_paths[1]"
            if test -d "$target"
                cd "$target"
            end
    end

    commandline -f repaint 2>/dev/null
end
