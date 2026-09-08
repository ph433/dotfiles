function fdf --description "Mở fzf chọn file: Enter để mở nvim, Right để chèn vào dòng lệnh"
    set -l fzf_opts (__my_fzf_defaults) \
        --header="Enter: nvim | Right: paste file | Tab: chọn nhiều" \
        --height=70% \
        --preview="bat --color=always {} 2>/dev/null || cat {}" \
        --preview-window="bottom:70%:hidden" \
        --multi \
        --expect=right

    # Chạy fzf và hứng kết quả
    set -l output (fd --max-depth 1 --type f --hidden --no-ignore --follow | fzf $fzf_opts)

    # Nếu không chọn gì (nhấn Esc) thì thoát
    if test -z "$output"
        commandline -f repaint
        return
    end

    # Dòng 1 chứa phím kích hoạt ('right' hoặc rỗng nếu là Enter)
    set -l key $output[1]
    # Các dòng sau chứa danh sách file được chọn
    set -l selections $output[2..-1]

    if test -z "$selections"
        commandline -f repaint
        return
    end

    if test "$key" = "right"
        # Xử lý khi nhấn Right: Escape từng file và nối lại bằng khoảng trắng
        set -l escaped_files
        for file in $selections
            set -a escaped_files (string escape -- $file)
        end
        
        # Chèn danh sách file cùng dấu cách ở cuối vào dòng lệnh
        commandline -i -- (string join " " $escaped_files)" "
    else
        # Xử lý khi nhấn Enter: Mở nvim với file đầu tiên được chọn
        nvim $selections[1]
    end

    commandline -f repaint
end
