function __fzf_file_recent --description "Fuzzy find recent files with keybinds"
    set -l log_file "$HOME/.cache/yazi/file_recent.log"
    test -f "$log_file"; or return 1

    # Dùng --expect để fzf trả về phím bấm ở dòng 1 và nội dung ở dòng 2
    set -l result (fzf \
        --no-sort \
        --reverse \
        --delimiter=" " \
        --nth=2.. \
        --expect=enter,right \
        --preview='test -f {2..} && (bat --style=numbers --color=always {2..} 2>/dev/null || cat {2..} 2>/dev/null)' \
        --preview-window=bottom:70%:hidden \
        --bind='ctrl-/:toggle-preview' \
        $argv < "$log_file")

    # result[1] là phím bấm, result[2] là dòng được chọn
    set -l key_pressed "$result[1]"
    set -l selected "$result[2]"

    # Thoát nếu người dùng bấm Esc / Ctrl-C (selected rỗng)
    test -n "$selected"; or return 0

    # Lấy đường dẫn file (cắt bỏ phần score ở đầu dòng)
    set -l file (string replace -r "^\S+\s+" "" -- "$selected")

    if test "$key_pressed" = "enter"
        nvim "$file"
    else if test "$key_pressed" = "right"
        commandline -i (string escape -- "$file")" "
        fish -c 'log_recent_file $argv[1]' -- "$file" >/dev/null 2>&1 &
        fzf_score_file.sh "$file" >/dev/null 2>&1 &
    end

    commandline -f repaint
end
