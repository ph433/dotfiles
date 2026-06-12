function gdiff --description "FZF Git Diff Preview với Delta"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # Gọi FZF
    set -l fzf_output (git status -s | fzf \
        --no-sort \
        --reverse \
        --tiebreak=index \
        --multi \
        --header="[Git Diff] Enter: Full màn hình | Ctrl-Y: Đẩy file ra Terminal" \
        --preview="git diff --color=always {2} | delta --width=\$FZF_PREVIEW_COLUMNS" \
        --preview-window="bottom:70%" \
        --bind="ctrl-m:execute(env LESS=R git diff --color=always {2} | delta --paging=always)" \
        --expect=ctrl-y)

    # Thoát an toàn
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
            if test (string sub --length 1 $path) = R
                # Xử lý file đổi tên: "R LICENSE -> LICENSE.md"
                set --append cleaned_paths (string split -- "-> " $path)[-1]
            else
                set --append cleaned_paths (string sub --start=4 $path)
            end
        end

        # Gộp mảng thành chuỗi và thêm 1 dấu cách ở cuối
        set -l output_str (string join ' ' $cleaned_paths)
        commandline --insert -- "$output_str "
    end
    
    # Yêu cầu Fish vẽ lại giao diện dòng lệnh ngay lập tức
    commandline --function repaint 2>/dev/null
end
