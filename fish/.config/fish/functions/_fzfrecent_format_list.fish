function _fzfrecent_format_list -d "Định dạng danh sách 0-9 kèm relative time cho FZF"
    set -l top10 $argv
    test -n "$top10"; or return 1

    set -l current_time (date +%s)
    printf "%s\n" $top10 | awk -v now="$current_time" '{
        time=$1; 
        sub(/^[0-9]+ /, ""); 
        
        diff = now - time;
        if (diff < 0) diff = 0;
        
        if (diff < 60) { ago = diff "s ago" }
        else if (diff < 3600) { ago = int(diff/60) "m ago" }
        else if (diff < 86400) { ago = int(diff/3600) "h ago" }
        else if (diff < 604800) { ago = int(diff/86400) "d ago" }
        else if (diff < 2592000) { ago = int(diff/604800) "w ago" }
        else if (diff < 31536000) { ago = int(diff/2592000) "mo ago" }
        else { ago = int(diff/31536000) "y ago" }
        
        printf "%d │ %10s │ %s\n", NR-1, ago, $0
    }'
end
