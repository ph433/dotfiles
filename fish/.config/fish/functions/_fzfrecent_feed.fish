function _fzfrecent_feed -d "Deduplicate và format relative time siêu tốc với systime()"
    set -l log_file $argv[1]
    test -f "$log_file"; or return 1

    tac "$log_file" 2>/dev/null | awk '
    BEGIN {
        now = systime()
    }
    {
        time = $1
        path = substr($0, length(time) + 2)

        if (!seen[path]++) {
            diff = now - time
            if (diff < 0) diff = 0

            if (diff < 60) raw = diff "s ago"
            else if (diff < 3600) raw = int(diff / 60) "m ago"
            else if (diff < 86400) raw = int(diff / 3600) "h ago"
            else if (diff < 604800) raw = int(diff / 86400) "d ago"
            else if (diff < 2592000) raw = int(diff / 604800) "w ago"
            else if (diff < 31536000) raw = int(diff / 2592000) "mo ago"
            else raw = int(diff / 31536000) "y ago"

            printf "%8s │ %s\n", raw, path
            if (++count >= 100) exit
        }
    }'
end
