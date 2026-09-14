function fzfrecent -d "Tìm file dựa trên lịch sử mở trong Neovim (Dashboard Top 10)"

    set -l log_file "$HOME/.cache/nvim_recent.log"
    test -f "$log_file"; or return 1
    
    # 1. Lấy danh sách 10 file gần nhất hợp lệ (dạng thô: <timestamp> <path>)
    set -l top_files (_fzfrecent_get_top_generic "$log_file")
    if test (count $top_files) -eq 0
        echo "Chưa có dữ liệu hoặc không có file nào trong lịch sử còn tồn tại."
        return 1
    end
    
    # 2. Chuyển đổi mảng $top10 thành chuỗi hiển thị UI (đánh số 0-9 & relative time)
    set -l list (_fzfrecent_format_list $top_files)
    
    # 3. Hiển thị FZF Menu (Thêm cờ -m / --multi)
    set -l fzf_out (printf "%s\n" $list | fzf \
        -m \
        --prompt="🕒 Nvim Recent (Tab để chọn nhiều | Ctrl-Space xem chi tiết)> " \
        --delimiter=' │ ' \
        --nth=2,.. \
        --tiebreak=index \
        --preview="bat --color=always {2} 2>/dev/null || cat {2}" \
        --preview-window="bottom:70%:hidden" \
        --expect=right,enter \
        --bind="ctrl-x:reload(fish -c '_fzfrecent_feed \"$log_file\"')" \
        --layout=reverse \
	--bind='insert:reload(sh -c '\''
            raw="$1"
            [ -z "$raw" ] && raw="$2"
            d="${raw%/*}"
            [ -z "$d" ] && d="/"
            while [ "$d" != "/" ] && [ -n "$d" ]; do
                printf "📁 │ %s\n" "$d"
                d="${d%/*}"
                [ -z "$d" ] && d="/"
            done
            printf "📁 │ /\n"
        '\'' _ {2} {1})+change-prompt(📁 Directories> )+clear-query+first' \
        --height=100%)

    # 4. Xử lý phím bấm và kết quả trả về từ FZF
    set -l key $fzf_out[1]
    
    # Lấy toàn bộ các dòng được chọn (từ phần tử thứ 2 trở đi)
    set -l selected_lines $fzf_out[2..-1]

    if test -z "$selected_lines"
        return
    end

    # Tách lấy danh sách target_path cho tất cả các file đã chọn
    set -l target_paths
    for line in $selected_lines
        set -a target_paths (echo "$line" | awk -F ' │ ' '{print $2}')
    end

    switch "$key"
        case right
            # Chèn tất cả đường dẫn đã chọn vào commandline
            set -l escaped_paths
            for path in $target_paths
                set -a escaped_paths (string escape -- "$path")
            end
            commandline -i (string join " " $escaped_paths)" "

            # Ghi log background cho toàn bộ file
            # Đẩy toàn bộ vòng lặp vào chạy nền 1 lần duy nhất
            # Truyền mảng $target_paths vào 1 instance fish duy nhất
            fish -c '
                for p in $argv
                    log_recent_file "$p"
                    fzf_score_file.sh "$p"
                end
            ' -- $target_paths >/dev/null 2>&1 &

        case enter
            set -l target "$target_paths[1]"
            test -z "$target"; and return

            # Nếu dòng đang chọn là thư mục (màn hình Directories) -> cd vào ngay
            if test -d "$target"
                cd "$target"
            # Nếu là file -> mở bằng Neovim
            else if test -f "$target"
                nvim "$target"
            end
            
        # case ins insert
        #     # Đi tới thư mục chứa file đầu tiên trong danh sách chọn
        #     set -l dir_path (dirname -- "$target_paths[1]")
        #     if test -d "$dir_path"
        #         cd "$dir_path"
        #     end
    end   

    commandline -f repaint 2>/dev/null
end
