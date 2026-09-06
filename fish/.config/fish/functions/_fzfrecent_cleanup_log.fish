function _fzfrecent_cleanup_log -d "Dọn dẹp log ngầm"
    set -l log_file $argv[1]
    test -f "$log_file"; or return 1
    
    # sleep 3.2
    
    set -l total_lines (wc -l < "$log_file" 2>/dev/null)
    if test "$total_lines" -gt 100
        printf "%s\n" $argv[2..] | tac > "$log_file"
    end
end
