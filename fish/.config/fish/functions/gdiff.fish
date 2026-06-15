function gdiff --description "FZF Git Diff Preview với Delta và Action Menu"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # Tầng 1: FZF chọn file (Enter để tiếp tục, Ctrl-F để xem full)
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

    # Thoát nếu nhấn Esc hoặc không chọn gì
    if test (count $fzf_output) -eq 0
        commandline --function repaint 2>/dev/null
        return 0
    end

    # Do không dùng expect nữa nên toàn bộ fzf_output là các dòng file được chọn
    set -l selected_paths $fzf_output
    set -l cleaned_paths
    
    # Tạo một file tạm để gom toàn bộ diff preview cho multi-select
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
        
        # --- GOM PREVIEW CHO NHIỀU FILE (DELTA MULTI) ---
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
    set -l menu_items "1. git add\n2. git restore (Bỏ thay đổi)\n3. git restore --staged (Unstage)\n4. git commit\n5. Chèn đường dẫn ra Terminal"
    
    set -l action (echo -e $menu_items | fzf \
        --prompt="⚡ Chọn hành động ("(count $cleaned_paths)" file) - Bấm phím 1-5 để chọn: " \
        --height=90% \
        --layout=reverse \
        --border=rounded \
        --preview="cat $tmp_preview" \
        --preview-window="right:65%,border-left" \
        --bind '1:become(echo "1. git add")' \
        --bind '2:become(echo "2. git restore (Bỏ thay đổi)")' \
        --bind '3:become(echo "3. git restore --staged (Unstage)")' \
        --bind '4:become(echo "4. git commit")' \
        --bind '5:become(echo "5. Chèn đường dẫn ra Terminal")' \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up')

    # Xóa file tạm đi cho sạch máy
    rm -f $tmp_preview

    # Thực thi lệnh
    switch "$action"
        case "1. git add"
            git add $cleaned_paths
            echo (set_color green)"✔ Đã thêm "(count $cleaned_paths)" file vào staging."(set_color normal)
        
        case "2. git restore (Bỏ thay đổi)"
            git restore $cleaned_paths
            echo (set_color yellow)"⚠ Đã loại bỏ thay đổi của "(count $cleaned_paths)" file."(set_color normal)
        
        case "3. git restore --staged (Unstage)"
            git restore --staged $cleaned_paths
            echo (set_color cyan)"✔ Đã unstage "(count $cleaned_paths)" file."(set_color normal)
        
        case "4. git commit"
            git add $cleaned_paths
            commandline --replace "git commit -m \"\""
            commandline --cursor (math (string length "git commit -m \"\"") - 1)
        
        case "5. Chèn đường dẫn ra Terminal"
            set -l output_str (string join ' ' $cleaned_paths)
            commandline --insert -- "$output_str "
    end
    
    commandline --function repaint 2>/dev/null
end
