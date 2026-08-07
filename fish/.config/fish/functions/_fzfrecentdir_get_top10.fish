function _fzfrecentdir_get_top10 -d "Lấy top 10 thư mục mới nhất đã được sắp xếp chuẩn theo Timestamp"
    set -l log_file "$HOME/.cache/dir_recent.log"
    test -f "$log_file"; or return 1

    # 1. Đọc ngược file log, lọc trùng lặp giữ lại mốc mới nhất
    set -l candidates (tac "$log_file" 2>/dev/null | awk '{
        path = $0;
        sub(/^[0-9]+ /, "", path);
        if (!seen[path]++) {
            print $0;
            if (++count == 50) exit;
        }
    }')

    # 2. Lọc chỉ giữ lại những thư mục CÒN TỒN TẠI (test -d)
    set -l valid_entries
    for entry in $candidates
        set -l dir_path (string replace -r '^[0-9]+ ' '' -- "$entry" | string replace -r '^~' "$HOME")

        if test -d "$dir_path"
            set -a valid_entries "$entry"
            if test (count $valid_entries) -ge 10
                break
            end
        end
    end

    test -n "$valid_entries"; or return 1

    # 3. Trả về danh sách Top 10 (mới nhất lên đầu)
    printf "%s\n" $valid_entries
end
