function gdiff --description "FZF Git Diff All-in-One Dashboard (3/7 Layout)"
    # Kiểm tra Git Repository
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # ---------------------------------------------------------
    # KHAI BÁO LỆNH THỰC THI NGẦM CHO PHÍM TẮT
    # ---------------------------------------------------------
    # Lệnh xử lý Add và Restore
    set -l add_cmd "fish -c 'for p in \$argv; if string match -q \"*->*\" \"\$p\"; git add (string split \" -> \" \"\$p\")[-1]; else; git add (string sub -s 4 \"\$p\"); end; end' -- {+}"
    set -l restore_cmd "fish -c 'for p in \$argv; if string match -q \"*->*\" \"\$p\"; git restore --staged (string split \" -> \" \"\$p\")[-1]; else; git restore --staged (string sub -s 4 \"\$p\"); end; end' -- {+}"

    # Lệnh xem full màn hình (Tự động phân biệt file mới Untracked và file Modified)
    # Lưu ý: Cần kết nối lại TTY (< /dev/tty > /dev/tty) để pager không bị văng
    set -l full_screen_cmd "fish -c 'if test \"\$argv[1]\" = \"??\"; bat --color=always --style=numbers --paging=always -- \"\$argv[2]\" </dev/tty >/dev/tty 2>/dev/null || less -R </dev/tty >/dev/tty \"\$argv[2]\"; else; git diff HEAD --color=always -- \"\$argv[2]\" | delta --paging=always </dev/tty >/dev/tty; end' -- {1} {-1}"

    # ---------------------------------------------------------
    # KHỞI CHẠY FZF
    # ---------------------------------------------------------
    set -l fzf_output (git -c color.status=always status -s | fzf \
        --ansi \
        --no-sort \
        --reverse \
        --tiebreak=index \
        --multi \
        --header="[Git Diff]  Right: Add |  Left: Unstage |  Ctrl-Right: Commit | ↵ Enter: Xem Full (q để thoát)" \
        --preview='if test {1} = "??"; bat --color=always --style=numbers -- {-1} 2>/dev/null || cat {-1}; else; git diff HEAD --color=always -- {-1} | delta --width=$FZF_PREVIEW_COLUMNS; end' \
        --preview-window="bottom:70%,border-top" \
        --bind="right:execute-silent($add_cmd)+reload(git -c color.status=always status -s)" \
        --bind="left:execute-silent($restore_cmd)+reload(git -c color.status=always status -s)" \
        --bind="enter:execute($full_screen_cmd)" \
        --expect=ctrl-right)

    # Thoát an toàn nếu bấm Esc
    if test (count $fzf_output) -eq 0
        commandline --function repaint 2>/dev/null
        return 0
    end

    # Lấy thông tin phím đã bấm và các file được chọn
    set -l key_pressed $fzf_output[1]
    set -l selected_paths $fzf_output[2..-1]

    # ---------------------------------------------------------
    # XỬ LÝ KHI BẤM CTRL-RIGHT (COMMIT)
    # ---------------------------------------------------------
    if test "$key_pressed" = "ctrl-right"
        if test (count $selected_paths) -gt 0
            for path_line in $selected_paths
                set -l extracted_path ""
                if test (string sub --length 1 $path_line) = R
                    set extracted_path (string split -- "-> " $path_line)[-1]
                else
                    set extracted_path (string sub --start=4 $path_line)
                end
                
                git add $extracted_path
                __fzf_score_file "$extracted_path" 2>/dev/null
            end
        end
        
        commandline --replace "git commit -m \"\""
        commandline --cursor (math (string length "git commit -m \"\"") - 1)
    end

    commandline --function repaint 2>/dev/null
end
