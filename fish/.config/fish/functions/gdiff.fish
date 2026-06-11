function gdiff --description "FZF Git Diff Preview với Delta"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!"
        return 1
    end

    # Gọi FZF lấy danh sách file thay đổi
    git status -s | fzf \
        --no-sort \
        --reverse \
        --tiebreak=index \
        --header="[Git Diff] Enter: Xem full màn hình (Nhấn 'q' để thoát) | Ctrl-C: Thoát FZF" \
        --preview="git diff --color=always {2} | delta --width=\$FZF_PREVIEW_COLUMNS" \
        --preview-window="bottom:70%" \
        --bind="ctrl-m:execute(git diff --color=always {2} | delta --paging=always)"
end
