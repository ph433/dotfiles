function _fzfrecent_get_top_generic -d "Lấy top gần đây từ log, deduplicate nhanh"
    set -l log_file $argv[1]
    test -f "$log_file"; or return 1

    # Đọc ngược, deduplicate và lấy tối đa 50 dòng duy nhất
    set -l entries (tac "$log_file" 2>/dev/null | awk '{
        path = $0;
        sub(/^[0-9]+ /, "", path);
        if (!seen[path]++) {
            print $0;
            if (++count >= 50) exit;
        }
    }')

    test -n "$entries"; or return 1

    # Xuất kết quả ngay lập tức cho FZF
    printf "%s\n" $entries

    # Đẩy tác vụ dọn dẹp ra background
    # _fzfrecent_cleanup_log "$log_file" $entries >/dev/null 2>&1
    _fzfrecent_cleanup_log "$log_file" $entries >/dev/null 2>&1 &
    disown $last_pid 2>/dev/null
    return 0
end
