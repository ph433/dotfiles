function gdiff --description "FZF Git Diff All-in-One Dashboard (Tích hợp Dò Commit)"
    # Kiểm tra Git Repository
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # ---------------------------------------------------------
    # KHAI BÁO CÁC LỆNH THỰC THI NGẦM
    # ---------------------------------------------------------
    
    # 1. Lệnh Add (Right) và Unstage (Left)
    set -l add_cmd "fish -c 'for p in \$argv; if string match -q \"*->*\" \"\$p\"; git add (string split \" -> \" \"\$p\")[-1]; else; git add (string sub -s 4 \"\$p\"); end; end' -- {+}"
    set -l unstage_cmd "fish -c 'for p in \$argv; if string match -q \"*->*\" \"\$p\"; git restore --staged (string split \" -> \" \"\$p\")[-1]; else; git restore --staged (string sub -s 4 \"\$p\"); end; end' -- {+}"

    # 2. Lệnh Hủy thay đổi (Ctrl-Left)
    # Tự động phân biệt: Nếu là file Untracked (??) thì xóa hẳn (rm), nếu là Modified (M) thì git restore
    set -l discard_cmd "fish -c 'for p in \$argv; set code (string sub -l 2 \"\$p\"); set path \"\"; if string match -q \"*->*\" \"\$p\"; set path (string split \" -> \" \"\$p\")[-1]; else; set path (string sub -s 4 \"\$p\"); end; if test \"\$code\" = \"??\"; rm -rf \"\$path\"; else; git restore \"\$path\"; end; end' -- {+}"

    # 3. Lệnh Dò Commit (Ctrl-T)
    # Mở một FZF con lồng bên trong để xem git log, trích xuất Hash và restore file về thời điểm đó
    set -l history_cmd "fish -c '
        set selected_commit (git log --oneline --color=always | fzf --ansi --prompt=\" Chọn commit để khôi phục file: \" --preview=\"git show {1} --color=always\" < /dev/tty > /dev/tty)
        if test -n \"\$selected_commit\"
            set hash (string split -m 1 \" \" \"\$selected_commit\")[1]
            for p in \$argv
                set path \"\"
                if string match -q \"*->*\" \"\$p\"
                    set path (string split \" -> \" \"\$p\")[-1]
                else
                    set path (string sub -s 4 \"\$p\")
                end
                git restore --source=\$hash \"\$path\"
            end
        end
    ' -- {+}"

    # 4. Lệnh xem full màn hình (Enter)
    set -l full_screen_cmd "fish -c 'if test \"\$argv[1]\" = \"??\"; bat --color=always --style=numbers --paging=always -- \"\$argv[2]\" </dev/tty >/dev/tty 2>/dev/null || less -R </dev/tty >/dev/tty \"\$argv[2]\"; else; git diff HEAD --color=always -- \"\$argv[2]\" | delta --paging=always </dev/tty >/dev/tty; end' -- {1} {-1}"

    # ---------------------------------------------------------
    # KHỞI CHẠY FZF GIAO DIỆN CHÍNH
    # ---------------------------------------------------------
    set -l fzf_output (git -c color.status=always status -s | fzf \
        --ansi \
        --no-sort \
        --reverse \
        --tiebreak=index \
        --multi \
        --header="[Git Diff]  Right: Add |  Left: Unstage |  C-Right: Commit |  C-Left: Bỏ thay đổi |  C-T: Dò Commit | ↵ Enter: Full" \
        --preview='if test {1} = "??"; bat --color=always --style=numbers -- {-1} 2>/dev/null || cat {-1}; else; git diff HEAD --color=always -- {-1} | delta --width=$FZF_PREVIEW_COLUMNS; end' \
        --preview-window="bottom:70%,border-top" \
        --bind="right:execute-silent($add_cmd)+reload(git -c color.status=always status -s)" \
        --bind="left:execute-silent($unstage_cmd)+reload(git -c color.status=always status -s)" \
        --bind="ctrl-left:execute-silent($discard_cmd)+reload(git -c color.status=always status -s)" \
        --bind="ctrl-t:execute($history_cmd)+reload(git -c color.status=always status -s)" \
        --bind="enter:execute($full_screen_cmd)" \
        --expect=ctrl-right)

    # Thoát an toàn nếu bấm Esc
    if test (count $fzf_output) -eq 0
        commandline --function repaint 2>/dev/null
        return 0
    end

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
