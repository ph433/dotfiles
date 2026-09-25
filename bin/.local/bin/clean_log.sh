#!/bin/sh
# Cách dùng: clean_log.sh <đường_dẫn_log_file> <-f|-d>

log_file="$1"
check_flag="$2"

# Bắt buộc truyền đủ 2 tham số và cờ phải là -f hoặc -d
if [ -z "$log_file" ] || { [ "$check_flag" != "-f" ] && [ "$check_flag" != "-d" ]; }; then
    echo "Cách dùng: $0 <log_file> <-f|-d>" >&2
    exit 1
fi

[ -f "$log_file" ] || exit 0

tmp_file="$(mktemp "${log_file}.tmp.XXXXXX")" || exit 1

# Đảo ngược file -> Giữ dòng mới nhất -> Kiểm tra tồn tại -> Ghi ra tmp
tac "$log_file" 2>/dev/null | awk '{
    t = $1
    p = substr($0, length(t) + 2)
    if (!seen[p]++) {
        print $0
    }
}' | while IFS=' ' read -r time path; do
    if [ "$check_flag" "$path" ]; then
        printf "%s %s\n" "$time" "$path"
    fi
done | tac > "$tmp_file"

# Ghi đè an toàn
if [ -s "$tmp_file" ]; then
    mv "$tmp_file" "$log_file"
else
    rm -f "$tmp_file"
    : > "$log_file"
fi
