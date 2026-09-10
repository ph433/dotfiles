#!/bin/sh
# Đường dẫn đề xuất: ~/.local/bin/fzf_score_file (nhớ: chmod +x ~/.local/bin/fzf_score_file)

target="$1"
[ -e "$target" ] || exit 0

log_file="$HOME/.cache/yazi/file_recent.log"
tmp_log=$(mktemp "${log_file}.XXXXXX")

# Tách điểm và đường dẫn, bảo toàn nguyên vẹn khoảng trắng
env LC_NUMERIC=C awk -v target="$target" '
{
    score = $1 + 0.0

    # Lấy toàn bộ phần còn lại làm đường dẫn (giữ nguyên khoảng trắng)
    sub(/^[0-9]+(\.[0-9]+)?[ \t]+/, "", $0)
    path = $0

    # Khử trùng lặp: Giữ điểm cao nhất cho mỗi path
    if (!(path in scores) || score > scores[path]) {
        scores[path] = score
    }
}
END {
    found = 0

    for (p in scores) {
        s = scores[p]
        if (p == target) {
            s += 5.0
            found = 1
        } else {
            s -= 1.0
        }

        if (s < 0) s = 0

        printf "%.2f %s\n", s, p
    }

    # Nếu file mới toanh chưa từng có trong log
    if (!found) {
        printf "5.00 %s\n", target
    }
}' "$log_file" | sort -k1,1nr -k2,2 | head -n 100 > "$tmp_log"

# Ghi đè an toàn (atomic replace)
mv "$tmp_log" "$log_file"
