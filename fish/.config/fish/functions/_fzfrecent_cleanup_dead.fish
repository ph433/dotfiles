function _fzfrecent_cleanup_dead -d "Luôn dọn file chết, cắt ngắn nếu log > 100 dòng"
    set -l log_file $argv[1]
    set -l entries $argv[2..]

    test -f "$log_file"; or return 1
    test -n "$entries"; or return 1

    # 1. Phân loại luôn cả file sống và file chết trong 1 vòng lặp duy nhất
    set -l dead_files
    set -l valid_entries
    for entry in $entries
        set -l file_path (string replace -r '^[0-9]+\s+' '' -- $entry)
        if test -e "$file_path"
            set -a valid_entries "$entry"
        else
            set -a dead_files "$file_path"
        end
    end

    # 2. Kiểm tra số dòng log
    set -l total_lines (wc -l < "$log_file" 2>/dev/null)

    # Nhánh A: Log đầy (> 100 dòng) -> Truncate log về danh sách valid (đã sạch file chết)
    if test "$total_lines" -gt 100
        if test (count $valid_entries) -gt 0
            printf "%s\n" $valid_entries | tac > "$log_file"
        end

    # Nhánh B: Log chưa đầy nhưng có file chết -> Gỡ file chết bằng awk
    else if test (count $dead_files) -gt 0
        set -l tmp_file (mktemp)
        string join \n -- $dead_files | awk '
            NR == FNR { dead[$0] = 1; next }
            {
                p = $0
                sub(/^[0-9]+ /, "", p)
                if (!(p in dead)) print $0
            }
        ' - "$log_file" > "$tmp_file" && mv "$tmp_file" "$log_file"
    end
end
