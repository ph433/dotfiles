function history_fzf -d "Tìm history full màn hình bằng fzf"
    # 1. Ép Fish đồng bộ lịch sử mới nhất từ tất cả các terminal khác
    history merge

    # 2. Cấu hình fzf
    set -l query (commandline -b)
    set -l fzf_opts \
        --layout=default \
        --border \
        --prompt="History > " \
        --expect=right \
        --bind "left:execute-silent(echo -n {} | xclip -selection clipboard)+clear-screen"

    # Lấy kết quả từ fzf (trả về 2 dòng: dòng 1 là phím nhấn, dòng 2 là lệnh được chọn)
    if test -n "$query"
        set -a fzf_opts --query "$query"
    end
    
    set -l output (history | awk '!seen[$0]++' | fzf $fzf_opts)
    # set -l output (history | fzf $fzf_opts)

    # Nếu không chọn gì (nhấn Esc), thoát
    if test (count $output) -lt 2
        commandline -f repaint
        return
    end

    set -l pressed_key $output[1]
    set -l selected_command $output[2]

    # 3. Xử lý theo phím bấm
    if test "$pressed_key" = "right"
        # BẮT BUỘC: Ghi trực tiếp bản ghi vào file history của Fish
        set -l now (date +%s)
        echo "- cmd: $selected_command" >> ~/.local/share/fish/fish_history
        echo "  when: $now" >> ~/.local/share/fish/fish_history
        commandline -r (string trim -- "$selected_command")
    else
        # Phím Enter (hoặc mặc định): Dán lệnh và thực thi ngay
        commandline -r "$selected_command"
        commandline -f execute
    end
    commandline -f repaint
end
