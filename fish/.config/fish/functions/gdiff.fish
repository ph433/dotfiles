function gdiff --description "FZF Git Diff All-in-One Dashboard (Bulletproof Script)"
    # Kiểm tra Git Repository
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # ---------------------------------------------------------
    # CHIẾN THUẬT SCRIPT ĐỘC LẬP: Tránh tuyệt đối lỗi Quote của Fish
    # ---------------------------------------------------------
    set -l history_runner "/tmp/gdiff_history_runner.fish"
    
    # Ghi toàn bộ logic xử lý glog ra một file vật lý (Dùng nháy đơn bao bọc để giữ nguyên $argv)
    echo 'rm -f /tmp/glog_hash /tmp/glog_raw

    # [HÀM GIẢ] Bắt phím Left nguyên vẹn không sợ đứt gãy syntax
    function fzf
        command fzf $argv --bind "ctrl-left:execute-silent(echo {} > /tmp/glog_raw)+abort"
    end

    # [HÀM GIẢ] Bắt Ctrl-Y từ glog cũ của bạn
    function commandline
        if test "$argv[1]" = "--insert"
            echo "$argv[3]" | string trim > /tmp/glog_hash
        end
    end

    # Chạy glog
    glog </dev/tty >/dev/tty

    # Phân tích kết quả trả về
    set -l hash ""
    if test -f /tmp/glog_raw
        set -l raw (cat /tmp/glog_raw)
        set hash (string match -r "[0-9a-f]{7,40}" $raw)[1]
    else if test -f /tmp/glog_hash
        set hash (cat /tmp/glog_hash)
        set hash (string split " " "$hash")[1]
    end

    # Thực thi restore nếu tìm thấy Hash
    if test -n "$hash"
        for p in $argv
            set -l path ""
            if string match -q "*->*" "$p"
                set path (string split -- " -> " "$p")[-1]
            else
                set path (string sub -s 4 "$p")
            end
            git restore --source=$hash "$path"
        end
        
        clear
        set_color green
        echo -e "\n✔ Đã khôi phục thành công các file về commit: $hash"
        set_color normal
        sleep 1.5
    end' > $history_runner

    # ---------------------------------------------------------
    # KHAI BÁO CÁC LỆNH CÒN LẠI (GIỮ NGUYÊN BẢN ỔN ĐỊNH)
    # ---------------------------------------------------------
    set -l add_cmd "fish -c 'for p in \$argv; if string match -q \"*->*\" \"\$p\"; git add (string split -- \" -> \" \"\$p\")[-1]; else; git add (string sub -s 4 \"\$p\"); end; end' -- {+}"
    set -l unstage_cmd "fish -c 'for p in \$argv; if string match -q \"*->*\" \"\$p\"; git restore --staged (string split -- \" -> \" \"\$p\")[-1]; else; git restore --staged (string sub -s 4 \"\$p\"); end; end' -- {+}"
    set -l discard_cmd "fish -c 'for p in \$argv; set code (string sub -l 2 \"\$p\"); set path \"\"; if string match -q \"*->*\" \"\$p\"; set path (string split -- \" -> \" \"\$p\")[-1]; else; set path (string sub -s 4 \"\$p\"); end; if test \"\$code\" = \"??\"; rm -rf \"\$path\"; else; git restore \"\$path\"; end; end' -- {+}"
    
    # Lệnh gọi script vật lý vừa tạo ở trên
    set -l history_cmd "fish $history_runner {+}"
    
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
        --header="[Git Diff]  Right: Add |  Left: Unstage |  C-Right: Commit |  C-Left: Hủy thay đổi |  C-S-Left: Gọi glog | ↵ Enter: Full" \
        --preview='if test {1} = "??"; bat --color=always --style=numbers -- {-1} 2>/dev/null || cat {-1}; else; git diff HEAD --color=always -- {-1} | delta --width=$FZF_PREVIEW_COLUMNS; end' \
        --preview-window="bottom:70%,border-top" \
        --bind="right:execute-silent($add_cmd)+reload(git -c color.status=always status -s)" \
        --bind="left:execute-silent($unstage_cmd)+reload(git -c color.status=always status -s)" \
        --bind="ctrl-left:execute-silent($discard_cmd)+reload(git -c color.status=always status -s)" \
        --bind="ctrl-shift-left:execute($history_cmd)+reload(git -c color.status=always status -s)" \
        --bind="enter:execute($full_screen_cmd)" \
        --expect=ctrl-right)

    # Dọn dẹp rác hệ thống và thoát an toàn
    rm -f $history_runner
    if test (count $fzf_output) -eq 0
        commandline --function repaint 2>/dev/null
        return 0
    end

    set -l key_pressed $fzf_output[1]
    set -l selected_paths $fzf_output[2..-1]

    # Xử lý commit tự động
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
