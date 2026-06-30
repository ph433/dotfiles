function fzf_git_checkout
    # Lấy danh sách nhánh và lọc qua fzf
    set -l branch (git branch -a --format='%(refname:short)' | fzf --height 40% --layout=reverse --border --prompt="Select branch: ")
    
    # Nếu chọn nhánh thành công, tiến hành checkout
    if test -n "$branch"
        # Xóa tiền tố 'origin/' nếu chọn nhánh remote
        set -l clean_branch (string replace -r '^origin/' '' $branch)
        git checkout $clean_branch
        
        # Làm mới lại dòng lệnh sau khi thực thi
        commandline -f repaint
    end
end
