function glog --description "FZF Duyệt Git Log và Preview Commit bằng Delta"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # --- CẤU HÌNH GIAO DIỆN PREVIEW ---
    # 1. Trích xuất Ngày giờ và Thống kê (Đã thêm s/^\s*\n//; để xóa dòng trống dư thừa)
    set -l stat_cmd "git show --stat --color=always --format='%C(#FFB86C)%cd' --date=format:'%d/%m/%Y %H:%M:%S' {2} | perl -0777 -pe 's/^\s*\n//m; if (\$_ =~ /\s+\|\s*(\d+\s+.*?)(?=\n)/) { my \$graph = \$1; s/^[ \t]+[^|\n]+?[ \t]+\|.*?\n//gm; s/( *\d+ files? changed.*?)(?=\n|\$)/\$1 | \$graph/g; } s/^\s+(\d+ files? changed)/\$1/gm; s/(\d+ insertions?\(\+\))/\e[38;2;166;227;161m\$1\e[0m/g; s/(\d+ deletions?\(\-\))/\e[38;2;243;139;168m\$1\e[0m/g; s/(\d+ files? changed)/\e[38;2;249;226;175m\$1\e[0m/g; s/\n+---\n+.*//s'"

    # 2. Lấy Diff và ẩn hoàn toàn metadata commit cũ (Vùng đỏ)
    set -l diff_cmd "git show --format='' --color=always {2} | delta --side-by-side"

    # 3. Gộp lệnh cho FZF Preview Window
    set -l preview_cmd "$stat_cmd; echo '────────────────────────────────────────'; $diff_cmd --width=\$FZF_PREVIEW_COLUMNS"
    
    # 4. Gộp lệnh cho khi bấm Enter (Ctrl-M) xem Full màn hình
    set -l enter_cmd "env LESS=R sh -c \"$stat_cmd; echo '────────────────────────────────────────'; $diff_cmd --paging=always\""

    # Gọi FZF và lưu output
    set -l fzf_output (git log --graph --color=always --format="%C(auto)%h%d %s %C(#FFB86C)%cr" | fzf \
        --ansi \
        --no-sort \
        --reverse \
        --multi \
        --header="[Git Log] Enter: Full màn hình | Ctrl-Y: Đẩy commit hash ra Terminal" \
        --preview-window=bottom:70% \
        --preview=$preview_cmd \
        --bind="ctrl-m:execute($enter_cmd)" \
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
