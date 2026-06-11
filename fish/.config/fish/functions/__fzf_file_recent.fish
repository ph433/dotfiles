function __fzf_file_recent --description "Bốc danh sách file Frecency (Alt-Space quét TẤT CẢ - Giữ nguyên điểm cũ)"
    set -l log_file "$HOME/.cache/yazi/file_recent.log"

    if not test -f "$log_file"
        echo "Chưa có lịch sử file recent ghen Phương ơi! Hãy mở vài file bằng nvim trước nha." >&2
        return
    end

    # Khởi tạo các tài nguyên tạm trên RAM
    set -l tmp_global (mktemp)
    set -l tmp_local (mktemp)
    set -l tmp_lookup (mktemp)       # File map trung gian để dò đường dẫn thật
    set -l scope_file (mktemp)       # Lưu trạng thái không gian (local/global)
    set -l mode_file (mktemp)        # Lưu trạng thái chế độ (history/all)
    set -l master_script (mktemp)    # Bộ điều phối danh sách cho FZF

    set -l real_pwd (realpath $PWD)
    
    set -l rel_pwd ""
    if test "$PWD" != "$HOME"
        set rel_pwd (string replace "$HOME/" "" "$PWD")
    end

    # BẢNG MÀU TRUE COLOR HEX
    set -l c_score (set_color ff9e64) # Màu Cam/Vàng nhẹ
    set -l c_reset (set_color normal)
    set -l c_link  (set_color bb9af7) # Màu Tím pastel (Symlink)
    set -l c_dot   (set_color 9ece6a) # Màu Xanh lá mạ (Dotfiles thật)
    set -l c_file  (set_color 7dcfff) # Màu Xanh lơ sáng (File thường)

    set -l raw_score "$c_score"
    set -l raw_reset "$c_reset"
    set -l raw_file "$c_file"
    set -l raw_dot "$c_dot"

    # 1. Quét dữ liệu lịch sử, phân loại màu sắc và tạo File Map
    cat "$log_file" | sort -nr | while read -l score line
        if test -e "$line"
            set -l path_color $c_file 

            if test -L "$line"
                set path_color $c_link
            else if string match -q "*/dotfiles/*" "$line"
                set path_color $c_dot
            end

            set -l colored_entry "$c_score$score$c_reset $path_color$line$c_reset"
            echo $colored_entry >> "$tmp_global"
            
            # Lưu đường dẫn gốc vào map để awk đối chiếu
            echo "$score|$path_color|$line" >> "$tmp_lookup"

            if string match -q "$PWD/*" "$line"; \
               or string match -q "$real_pwd/*" "$line"; \
               or { test -n "$rel_pwd"; and string match -q "*/$rel_pwd/*" "$line"; }
                echo $colored_entry >> "$tmp_local"
            end
        end
    end

    # Thiết lập trạng thái ban đầu khi vừa gọi hàm
    set -l initial_file
    if test -s "$tmp_local"
        echo "local" > "$scope_file"
        echo "history" > "$mode_file"
        set initial_file "$tmp_local"
    else
        echo "global" > "$scope_file"
        echo "history" > "$mode_file"
        set initial_file "$tmp_global"
    end

    # 2. XÂY DỰNG BỘ ĐIỀU PHỐI DANH SÁCH (MASTER SCRIPT)
    echo "#!/bin/sh
    action=\$1
    scope=\$(cat \"$scope_file\")
    mode=\$(cat \"$mode_file\")

    if [ \"\$action\" = \"toggle-scope\" ]; then
        if [ \"\$scope\" = \"local\" ]; then scope=\"global\"; else scope=\"local\"; fi
        echo \"\$scope\" > \"$scope_file\"
    elif [ \"\$action\" = \"toggle-mode\" ]; then
        # Chuyển đổi giữa (Chỉ file lịch sử) và (Tất cả mọi file)
        if [ \"\$mode\" = \"history\" ]; then mode=\"all\"; else mode=\"history\"; fi
        echo \"\$mode\" > \"$mode_file\"
    fi

    # Xác định file lịch sử cần dùng
    if [ \"\$scope\" = \"local\" ]; then
        hist_file=\"$tmp_local\"
        scan_dir=\"$real_pwd\"
    else
        hist_file=\"$tmp_global\"
        scan_dir=\"\$HOME\"
    fi

    if [ \"\$mode\" = \"history\" ]; then
        # CHẾ ĐỘ 1: CHỈ HIỆN FILE CÓ TRONG LỊCH SỬ
        cat \"\$hist_file\"
    else
        # CHẾ ĐỘ 2: HIỆN TẤT CẢ (Giữ nguyên điểm lịch sử + Bổ sung file 0đ)
        
        # Bước 1: In ra lịch sử trước để giữ Top ưu tiên
        cat \"\$hist_file\"

        # Bước 2: Quét thư mục, ép giải mã đường dẫn thật bằng -X realpath
        if command -v fd >/dev/null 2>&1; then
            fd --type f --type l --hidden --exclude .git . \"\$scan_dir\" -X realpath 2>/dev/null
        else
            find \"\$scan_dir\" \\( -type f -o -type l \\) -not -path '*/.git*' -exec realpath {} + 2>/dev/null
        fi | sort -u | env LC_NUMERIC=C awk -v lookup=\"$tmp_lookup\" -v c_score=\"$raw_score\" -v c_reset=\"$raw_reset\" -v c_file=\"$raw_file\" -v c_dot=\"$raw_dot\" '
        BEGIN {
            while ((getline < lookup) > 0) {
                split(\$0, parts, \"|\")
                # Đánh dấu những file đã in ở Bước 1
                history_paths[parts[3]] = 1
            }
            close(lookup)
        }
        {
            path = \$0
            # CHỈ in ra file mới (0.0 điểm) nếu nó chưa xuất hiện trong lịch sử
            if (!(path in history_paths)) {
                score = \"0.0\"
                path_color = c_file
                if (path ~ /\/dotfiles\//) {
                    path_color = c_dot
                }
                printf \"%s%s%s %s%s%s\\n\", c_score, score, c_reset, path_color, path, c_reset
            }
        }'
    fi" > "$master_script"
    chmod +x "$master_script"

    # 3. TRIỂN KHAI CẤU TRÚC FZF
    set -l fzf_output (cat "$initial_file" | fzf \
        --ansi \
        --tiebreak=index \
        --layout=reverse \
        --border \
        --prompt="Frecency> " \
        --header="Enter: Mở | Ctrl-Y: Dán | Ctrl-Space: Lịch sử (Local/Global) | Alt-Space: Bật/Tắt Quét Mọi File" \
        --preview-window="bottom:50%" \
        --preview 'bat --style=numbers --color=always --line-range :100 {2..}' \
        --bind="ctrl-space:reload($master_script toggle-scope)" \
        --bind="alt-space:reload($master_script toggle-mode)" \
        --expect=ctrl-y,enter)

    # Giải phóng không gian bộ nhớ tạm thời
    rm -f "$tmp_global" "$tmp_local" "$tmp_lookup" "$scope_file" "$mode_file" "$master_script"

    if test (count $fzf_output) -eq 0
        commandline -f repaint 2>/dev/null
        return
    end

    set -l key_pressed $fzf_output[1]
    set -l selected $fzf_output[2..-1]

    if test (count $selected) -gt 0
        set -l file (string replace -r "^\S+\s+" "" -- "$selected[1]")

        if test "$key_pressed" = "enter"
            nvim $file
        else if test "$key_pressed" = "ctrl-y"
            commandline -i (string escape $file)" "

            set -l tmp_log (mktemp)
            
            env LC_NUMERIC=C awk -v target="$file" '
            {
                score = $1; path = $2
                for(i=3; i<=NF; i++) path = path " " $i 
                
                gsub(",", ".", score)
                
                if (path == target) {
                    score += 5.0
                    found = 1
                } else {
                    score -= 0.5
                    # if (score < -10.0) score = -10.0
                }
                printf "%.1f %s\n", score, path
            }
            END {
                if (!found) printf "5.0 %s\n", target
            }' "$log_file" | sort -nr | head -n 100 > "$tmp_log"
            
            mv "$tmp_log" "$log_file"
        end
    end
    
    commandline -f repaint 2>/dev/null
end
