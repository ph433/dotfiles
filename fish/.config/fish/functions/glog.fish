function glog --description "FZF Duyệt Git Log và Preview Commit bằng Delta"
    # Kiểm tra xem có đang ở trong repo Git không
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    if test $status -ne 0
        echo "Lỗi: Thư mục này không phải là một Git Repository!" >&2
        return 1
    end

    # Đặt mốc độ dài cố định cho cột thời gian (11 ký tự là vừa đẹp cho "2 days ago")
    set -l time_width 11

    # Gọi FZF và lưu output
    set -l fzf_output (git log --graph --color=always --format="%cr|%C(#00FFFF)%h%C(reset) %C(auto)%d%C(reset) %s" --date=relative | awk -F'|' -v w=$time_width '
        BEGIN {
            # Giữ màu hồng Cyberpunk cho phần thời gian
            pink = "\033[38;5;198m";
            reset = "\033[0m";
        }
        {
            # Nếu dòng không có ký tự phân tách "|", in ra bình thường
            if (NF < 2) { print $0; next; }
            
            time_part = $1;
            rest_part = $2;
            
            # Tìm vị trí chữ đầu tiên của thời gian (bỏ qua ký tự graph *, |)
            match(time_part, /[0-9a-zA-Z]/);
            start_idx = RSTART;
            
            if (start_idx > 0) {
                graph = substr(time_part, 1, start_idx - 1);
                time_str = substr(time_part, start_idx);
                
                # Cắt ngắn và thêm ... nếu chuỗi dài hơn mốc w
		if (length(time_str) > w) {
			# Cắt ngắn chuỗi, thêm "..." và tự chèn thêm 1 khoảng trắng để sửa lỗi font chữ hẹp
			time_str = substr(time_str, 1, w - 4) "... ";
			} else {
			# Dòng ngắn thì bù khoảng trắng như bình thường và cộng thêm 1 khoảng trắng cho đồng bộ
			time_str = sprintf("%-" w "s", time_str);
			}

                # Ghép lại dòng hoàn chỉnh với màu hồng rực rỡ
                print graph pink time_str reset " " rest_part;
            } else {
                print $0;
            }
        }
    ' | fzf \
        --ansi \
        --no-sort \
        --reverse \
        --multi \
        --header="[Git Log] Enter: Full màn hình | Ctrl-Y: Đẩy commit hash ra Terminal" \
        --preview-window="bottom:70%" \
	--preview="echo {} | grep -oE '\\b[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]+\\b' | head -1 | xargs -I HASH sh -c 'git show --stat -p --color=always --format=\"commit: %H%n%C(#00FFFF)Author: %an <%ae>%C(reset)%n%C(#FF0087)Date:   %ad%C(reset)%n%n%w(0,4,4)%B\" HASH | delta --side-by-side --width=\$FZF_PREVIEW_COLUMNS'" \
        --bind="ctrl-m:execute(echo {} | grep -oE '\\b[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]+\\b' | head -1 | xargs -I HASH sh -c 'env LESS=R git show --stat -p --color=always --format=\"commit %H%n%C(#00FFFF)Author: %an <%ae>%C(reset)%n%C(#FF0087)Date:   %ad%C(reset)%n%n%w(0,4,4)%B\" HASH | delta --side-by-side --paging=always')" \
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
