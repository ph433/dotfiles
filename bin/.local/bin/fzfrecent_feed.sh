#!/bin/sh
log_file="$1"
[ -f "$log_file" ] || exit 1

tail -n 2000 "$log_file" 2>/dev/null | tac 2>/dev/null | awk -v now="$(date +%s)" '
{
    t = $1;
    sub(/^[0-9]+ /, "");
    p = $0;
    if (!seen[p]++) {
        diff = now - t;
        if (diff < 60) s = diff "s";
        else if (diff < 3600) s = int(diff/60) "m";
        else if (diff < 86400) s = int(diff/3600) "h";
        else s = int(diff/86400) "d";

        printf "[%-3s] │ %s\n", s, p;
        if (++c >= 50) exit;
    }
}'
