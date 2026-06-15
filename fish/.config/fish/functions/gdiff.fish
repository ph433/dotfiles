function gdiff --description "FZF Git Diff Preview với Delta và Action Menu"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # Gọi FZF (Giữ nguyên toàn bộ thuộc tính, giao diện và chức năng phím Enter)
    set -l fzf_output (git -c color.status=always status -s | fzf \
        --ansi \
        --no-sort \
        --reverse \
        --tiebreak=index \
        --multi \
        --header="[Git Diff] Tab: Chọn nhiều | Enter: Xem Full | Ctrl-Y: Mở Menu Hành Động" \
        --preview='if test {1} = "??"; bat --color=always --style=numbers -- {2} 2>/dev/null || cat {2}; else; git diff --color=always -- {2} | delta --width=$FZF_PREVIEW_COLUMNS; end' \
        --preview-window="bottom:70%" \
        --bind='ctrl-m:execute-silent(fish -c "__fzf_score_file {2}")+execute(if test {1} = "??"; env LESS=R bat --color=always --style=numbers --paging=always -- {2} 2>/dev/null || cat {2}; else; env LESS=R git diff --color=always -- {2} | delta --paging=always; end)' \
        --expect=ctrl-y)

    # Thoát an toàn nếu không chọn gì
    if test (count $fzf_output) -eq 0
        commandline --function repaint 2>/dev/null
        return 0
    end

    set -l key_pressed $fzf_output[1]
    set -l selected_paths $fzf_output[2..-1]

    # Xử lý nếu bấm Ctrl-Y
    if test "$key_pressed" = "ctrl-y"; and test (count $selected_paths) -gt 0
        set -l cleaned_paths

        for path in $selected_paths
            set -l extracted_path ""
            
            if test (string sub --length 1 $path) = R
                # Xử lý file đổi tên: "R LICENSE -> LICENSE.md"
                set extracted_path (string split -- "-> " $path)[-1]
            else
                set extracted_path (string sub --start=4 $path)
            end
            
            set --append cleaned_paths $extracted_path
            
            # GỌI HÀM CỘNG ĐIỂM Ở ĐÂY
            __fzf_score_file "$extracted_path" 2>/dev/null
        end

        # ---------------------------------------------------------
        # TẠO MENU HÀNH ĐỘNG (ACTION MENU) BẰNG FZF
        # ---------------------------------------------------------
        set -l action (echo -e "git add\ngit restore (Bỏ thay đổi)\ngit restore --staged (Unstage)\ngit commit\nChèn đường dẫn ra Terminal" | fzf \
            --prompt="⚡ Chọn hành động cho "(count $cleaned_paths)" file: " \
            --height=30% \
            --layout=reverse \
            --border=rounded)

        # Xử lý hành động được chọn
        switch "$action"
            case "git add"
                git add $cleaned_paths
                echo (set_color green)"✔ Đã thêm "(count $cleaned_paths)" file vào staging."(set_color normal)
            
            case "git restore (Bỏ thay đổi)"
                git restore $cleaned_paths
                echo (set_color yellow)"⚠ Đã loại bỏ thay đổi của "(count $cleaned_paths)" file."(set_color normal)
            
            case "git restore --staged (Unstage)"
                git restore --staged $cleaned_paths
                echo (set_color cyan)"✔ Đã unstage "(count $cleaned_paths)" file."(set_color normal)
            
            case "git commit"
                # Auto-add file đã chọn và in sẵn lệnh commit ra terminal để gõ message
                git add $cleaned_paths
                commandline --replace "git commit -m \"\""
                # Di chuyển con trỏ chuột vào giữa 2 dấu ngoặc kép
                commandline --cursor (math (string length "git commit -m \"\"") - 1)
            
            case "Chèn đường dẫn ra Terminal"
                set -l output_str (string join ' ' $cleaned_paths)
                commandline --insert -- "$output_str "
                
            case '*'
                # Bấm Esc để hủy menu
                echo (set_color red)"Đã hủy thao tác."(set_color normal)
        end
    end
    
    # Yêu cầu Fish vẽ lại giao diện dòng lệnh
    commandline --function repaint 2>/dev/null
end
