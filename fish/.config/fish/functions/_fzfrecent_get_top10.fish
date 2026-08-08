function _fzfrecent_get_top10 -d "Lấy top 10 file mới nhất đã được sắp xếp chuẩn theo Timestamp"
    set -l log_file "$HOME/.cache/nvim_recent.log"
    test -f "$log_file"; or return 1

    # 1. Đọc ngược file log, lấy candidates trùng lập
    set -l candidates (tac "$log_file" 2>/dev/null | awk '{
            path = $0;
            sub(/^[0-9]+ /, "", path);
            if (!seen[path]++) {
                print $0;
                if (++count == 50) exit;
            }
        }')


    # 2. Lọc file tồn tại
    set -l valid_entries
    for entry in $candidates
        set -l file_path (string replace -r '^[0-9]+ ' '' -- "$entry" | string replace -r '^~' "$HOME")

        if test -f "$file_path"
            set -a valid_entries "$entry"
            if test (count $valid_entries) -ge 50
                break
            end
        end
    end
    
    test -n "$valid_entries"; or return 1

    # 3. Sắp xếp lại theo Timestamp (cột 1, số lớn nhất/mới nhất lên đầu) và lấy đúng 10 file
    printf "%s\n" $valid_entries
    # printf "%s\n" $valid_entries | sort -k1,1nr | head -n 10
    printf "%s\n" $candidates | tac > $log_file
end
