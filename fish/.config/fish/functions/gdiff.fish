function gdiff --description "FZF Git Diff Preview với Delta"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!"
        return 1
    end

    # Gọi FZF lấy danh sách file thay đổi, preview bằng git diff + delta
    git status -s | fzf \
        --no-sort \
        --reverse \
        --tiebreak=index \
        --header="[Git Diff] Chọn file để soi code thay đổi" \
        --preview="git diff --color=always {2} | delta --width=\$FZF_PREVIEW_COLUMNS" \
        --bind="ctrl-m:execute(nvim -d {2}; clear)" # Sửa dòng này: Thay +refresh bằng ; clear
end
