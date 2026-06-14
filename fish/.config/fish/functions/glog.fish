function glog --description "FZF Duyệt Git Log và Preview Commit bằng Delta"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # Gọi FZF và lưu output
    set -l fzf_output (git log --graph --color=always --format="%C(#FF0087)%<(12,trunc)%cr%C(reset) %C(#00FFFF)%h%C(reset) %C(auto)%d%C(reset) %s" --date=relative | fzf \
        --ansi \
        --no-sort \
        --reverse \
        --multi \
        --header="[Git Log] Enter: Full màn hình | Ctrl-Y: Đẩy commit hash ra Terminal" \
        --preview-window="bottom:70%" \
	--preview="echo {} | grep -oE '\\b[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]+\\b' | head -1 | xargs -I HASH sh -c 'git show --stat -p --color=always --format=\"commit: %H%n%C(#00FFFF)Author: %an <%ae>%C(reset)%n%C(#FF0087)Date:   %ad%C(reset)%n%n%w(0,4,4)%B\" HASH | delta --side-by-side --width=\$FZF_PREVIEW_COLUMNS'" \
        --bind="ctrl-m:execute(echo {} | grep -oE '\\b[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]+\\b' | head -1 | xargs -I HASH sh -c 'env LESS=R git show --stat -p --color=always --format=\"commit %H%n%C(#00FFFF)Author: %an <%ae>%C(reset)%n%C(#FF0087)Date:   %ad%C(reset)%n%n%w(0,4,4)%B\" HASH | env COLORTERM=truecolor delta --side-by-side --paging=always')" \
        --expect=ctrl-y)
    

    # Thoát an toàn nếu user ấn Esc/Ctrl-C
    if test (count $fzf_output) -eq 0
        commandline --function repaint 2>/dev/null
        return 0
    end

    set -l key_pressed $fzf_output[1]
    set -l selected_lines $fzf_output[2..-1]

    # Xử lý nếu bấm Ctrl-Y
    if test "$key_pressed" = "ctrl-y"; and test (count $selected_lines) -gt 0
        set -l cleaned_hashes

        for line in $selected_lines
            # Regex trích xuất commit hash (chuỗi hex từ 7-40 ký tự) bỏ qua các ký tự graph (*, |)
            # Ở đoạn này là code Fish thuần, không qua FZF nên vẫn dùng {7,40} bình thường
            set -l hash (string match -r '\b[0-9a-f]{7,40}\b' $line)[1]
            if test -n "$hash"
                set --append cleaned_hashes $hash
            end
        end

        # Gộp mảng thành chuỗi và thêm 1 dấu cách ở cuối
        set -l output_str (string join ' ' $cleaned_hashes)
        commandline --insert -- "$output_str "
    end
    
    # Yêu cầu Fish vẽ lại giao diện dòng lệnh ngay lập tức
    commandline --function repaint 2>/dev/null
end
