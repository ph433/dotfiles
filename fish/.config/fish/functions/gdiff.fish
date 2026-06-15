function gdiff --description "FZF Git Diff Preview với Delta và Action Menu"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # VÒNG LẶP CHÍNH (Bao trọn cả Menu 1 và Menu 2 để có thể quay lại)
    while true
        # ---------------------------------------------------------
        # TẦNG 1: FZF CHỌN FILE
        # ---------------------------------------------------------
        set -l fzf_output (git -c color.status=always status -s | fzf \
            --ansi \
            --no-sort \
            --reverse \
            --tiebreak=index \
            --multi \
            --header="[Git Diff] Tab: Chọn multi | Enter: Mở Menu Hành Động | Ctrl-F: Xem Full Màn Hình" \
            --preview='if test {1} = "??"; bat --color=always --style=numbers -- {2} 2>/dev/null || cat {2}; else; git diff --color=always -- {2} | delta --width=$FZF_PREVIEW_COLUMNS; end' \
            --preview-window="bottom:70%" \
            --bind='ctrl-f:execute-silent(fish -c "__fzf_score_file {2}")+execute(if test {1} = "??"; env LESS=R bat --color=always --style=numbers --paging=always -- {2} 2>/dev/null || cat {2}; else; env LESS=R git diff --color=always -- {2} | delta --paging=always; end)')

        # Thoát hoàn toàn nếu nhấn Esc hoặc không chọn gì ở Tầng 1
        if test (count $fzf_output) -eq 0
            commandline --function repaint 2>/dev/null
            return 0
        end

        set -l selected_paths $fzf_output
        set -l cleaned_paths
        
        # Tạo file tạm để gom diff
        set -l tmp_preview (mktemp)

        for path_line in $selected_paths
            set -l extracted_path ""
            set -l status_code (string sub --length 2 $path_line)
            
            if test (string sub --length 1 $path_line) = R
                set extracted_path (string split -- "-> " $path_line)[-1]
            else
                set extracted_path (string sub --start=4 $path_line)
            end
            
            set --append cleaned_paths $extracted_path
            
            # Ghi nội dung vào file tạm
            echo -e "\n\033[1;33m=== $extracted_path ===\033[0m\n" >> $tmp_preview
            if test "$status_code" = "??"
                bat --color=always --style=numbers -- $extracted_path 2>/dev/null >> $tmp_preview || cat $extracted_path >> $tmp_preview
            else
                git diff HEAD --color=always -- $extracted_path | delta >> $tmp_preview
            end
            
            __fzf_score_file "$extracted_path" 2>/dev/null
        end

        # ---------------------------------------------------------
        # TẦNG 2: MENU HÀNH ĐỘNG 
        # ---------------------------------------------------------
        set -l menu_items "1. git add\n2. git restore (Bỏ thay đổi)\n3. git restore --staged (Unstage)\n4. git commit\n5. Chèn đường dẫn ra Terminal\n6. Xem Full màn hình (Delta)"
        set -l action ""
        set -l go_back 0
        
        while true
            set action (echo -e $menu_items | fzf \
                --prompt="⚡ Chọn hành động ("(count $cleaned_paths)" file) - Phím 1-6 chọn nhanh, Phím 'q' để quay lại: " \
                --height=90% \
                --layout=reverse \
                --border=rounded \
                --preview="cat $tmp_preview" \
                --preview-window="bottom:70%,border-top" \
                --bind '1:become(echo "1")' \
                --bind '2:become(echo "2")' \
                --bind '3:become(echo "3")' \
                --bind '4:become(echo "4")' \
                --bind '5:become(echo "5")' \
                --bind "6:execute(less -R < /dev/tty > /dev/tty $tmp_preview)" \
                --bind 'q:become(echo "BACK")' \
                --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up')

            # Nếu bấm Esc để hủy hoàn toàn lệnh
            if test -z "$action"
                echo (set_color red)"Đã hủy thao tác."(set_color normal)
                rm -f $tmp_preview
                commandline --function repaint 2>/dev/null
                return 0
            end

            # Nhận tín hiệu quay lại Menu 1 khi bấm 'q'
            if test "$action" = "BACK"
                set go_back 1
                break
            end

            # Xử lý nếu dùng "Mũi tên xuống dòng 6 + Enter"
            if string match -q "6*" "$action"
                less -R < /dev/tty > /dev/tty $tmp_preview
                continue
            end

            # Bấm 1-5 thì thoát vòng lặp phụ để đi xuống phần thực thi
            break
        end

        # Xóa file tạm
        rm -f $tmp_preview

        # Nếu người dùng bấm 'q', dùng continue để lặp lại Menu 1
        if test $go_back -eq 1
            continue
        end

        # Chạy lệnh (xử lý cả trường hợp bấm phím nóng "1" và chọn bằng Enter "1. git add")
        if test -n "$action"; and not string match -q "6*" "$action"
            switch "$action"
                case "1" "1*"
                    git add $cleaned_paths
                    echo (set_color green)"✔ Đã thêm "(count $cleaned_paths)" file vào staging."(set_color normal)
                
                case "2" "2*"
                    git restore $cleaned_paths
                    echo (set_color yellow)"⚠ Đã loại bỏ thay đổi của "(count $cleaned_paths)" file."(set_color normal)
                
                case "3" "3*"
                    git restore --staged $cleaned_paths
                    echo (set_color cyan)"✔ Đã unstage "(count $cleaned_paths)" file."(set_color normal)
                
                case "4" "4*"
                    git add $cleaned_paths
                    commandline --replace "git commit -m \"\""
                    commandline --cursor (math (string length "git commit -m \"\"") - 1)
                
                case "5" "5*"
                    set -l output_str (string join ' ' $cleaned_paths)
                    commandline --insert -- "$output_str "
            end
        end
        
        # Nếu đã thực thi thành công một lệnh (1-5), thoát hẳn vòng lặp lớn
        break
    end

    commandline --function repaint 2>/dev/null
end
