function _fzfrecent_get_top_generic -d "Lấy top gần đây từ log, kiểm tra theo loại (file/dir)"
    set -l log_file $argv[1]
    set -l type_flag $argv[2]  # "-f" hoặc "-d"

    test -f "$log_file"; or return 1
    test -n "$type_flag"; or set type_flag "-f"

    # 1. Đọc ngược file log, lấy candidates không trùng lặp
    set -l candidates (tac "$log_file" 2>/dev/null | awk '{
        path = $0;
        sub(/^[0-9]+ /, "", path);
        if (!seen[path]++) {
            print $0;
            if (++count == 50) exit;
        }
    }')

    # 2. Lọc entry còn tồn tại theo cờ test (-f hoặc -d)
    set -l valid_entries
    for entry in $candidates
        set -l target_path (string replace -r '^[0-9]+ ' '' -- "$entry" | string replace -r '^~' "$HOME")

        if test $type_flag "$target_path"
            set -a valid_entries "$entry"
            if test (count $valid_entries) -ge 50
                break
            end
        end
    end

    test -n "$valid_entries"; or return 1

    # 3. Trả về kết quả
    printf "%s\n" $valid_entries

    # 4. Tự động xoay vòng log nếu vượt quá 100 dòng
    set -l total_lines (wc -l < "$log_file")
    if test $total_lines -gt 100
        printf "%s\n" $valid_entries | tac > "$log_file"
    end
end
