function fdf --description "Mở fzf chọn file ở tầng hiện tại và chèn vào dòng lệnh"
    set -l result (fd --max-depth 1 --type f | fzf)
    
    if test -n "$result"
        commandline -i -- (string escape -- $result)" "
    end
    
    commandline -f repaint
end
