#!/bin/sh
log_file="$1"
shift

[ -z "$log_file" ] && exit 0
now=$(date +%s)

for item in "$@"; do
    [ -n "$item" ] && [ "$item" != "$HOME" ] && printf "%s %s\n" "$now" "$item" >> "$log_file"
done
