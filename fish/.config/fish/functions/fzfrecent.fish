function fzfrecent -d "Tìm file dựa trên lịch sử mở trong Neovim (Dashboard Top 10)"
    set -l log_file "$HOME/.cache/nvim_recent.log"
    test -f "$log_file"; or return 1

    # 1. Pipe trực tiếp từ hàm feed vào FZF ngay trong session Fish
    set -l fzf_out (_fzfrecent_feed "$log_file" | fzf \
        -m \
        --prompt="🕒 Nvim Recent> " \
        --delimiter=' │ ' \
        --nth=2.. \
        --tiebreak=index \
        --preview="bat --color=always {2} 2>/dev/null || cat {2}" \
        --preview-window="bottom:70%:hidden" \
        --expect=right,enter \
        --layout=reverse \
        --height=100%)

    test -z "$fzf_out"; and return

    # 2. Xử lý phím bấm và danh sách đường dẫn
    set -l key $fzf_out[1]
    set -l selected_lines $fzf_out[2..-1]
    test -z "$selected_lines"; and return

    # 3. Tách target_paths bằng builtin string split
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

            # Ghi log và tính điểm ngầm bằng sh
            sh -c '
                log_file="$1"
                score_cmd="$2"
                shift 2

                log_add.sh "$log_file" "$@"
                for p in "$@"; do
                    "$score_cmd" "$p"
                done
            ' _ "$log_file" "fzf_score_file.sh" $target_paths >/dev/null 2>&1 &
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
