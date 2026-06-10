function glog --description "FZF Duyệt Git Log và Preview Commit bằng Delta"
    git log --graph --color=always --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" | fzf \
        --ansi \
        --no-sort \
        --reverse \
        --header="[Git Log] Chọn commit để xem chi tiết" \
        --preview-window=bottom:70% \
        --preview="git show --color=always {2} | delta --side-by-side --width=\$FZF_PREVIEW_COLUMNS"
end
