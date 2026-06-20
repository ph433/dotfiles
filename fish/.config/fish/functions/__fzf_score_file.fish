function __fzf_score_file --description "Hàm trung tâm: Tính điểm Frecency (Min 1.0)"
    set -l target "$argv[1]"
    
    # Bỏ qua nếu không truyền tham số
    if test -z "$target"
        return
    end

    # Lấy đường dẫn vật lý tuyệt đối của file mục tiêu
    set target (realpath -- "$target" 2>/dev/null)
    if test -z "$target"
        return
    end

    set -l log_file "$HOME/.cache/yazi/file_recent.log"
    set -l tmp_log (mktemp)
    set -l valid_log (mktemp)

    # Tự động tạo thư mục/file log nếu chưa có
    if not test -f "$log_file"
        mkdir -p (dirname "$log_file")
        touch "$log_file"
    end

    # 🎯 FIX 1: Lọc file tồn tại + Phân giải toàn bộ Symlink
    # Ép mọi đường dẫn trong log về file vật lý gốc để chuẩn bị so sánh
    while read -l score line
        if test -e "$line"
            set -l real_line (realpath -- "$line" 2>/dev/null)
            if test -n "$real_line"
                echo "$score $real_line" >> "$valid_log"
            end
        end
    end < "$log_file"

    # 🎯 FIX 2: Gộp trùng lặp và tính điểm bằng AWK
    env LC_NUMERIC=C awk -v target="$target" '
    {
        score = $1; path = $2
        for(i=3; i<=NF; i++) path = path " " $i 
        gsub(",", ".", score)
        
        # Nếu đường dẫn đã tồn tại trong mảng (do gộp symlink), chỉ giữ lại điểm cao nhất
        if (path in scores) {
            if (score > scores[path]) scores[path] = score
        } else {
            scores[path] = score
        }
    }
    END {
        found = 0
        # Duyệt qua danh sách đã được dọn sạch trùng lặp
        for (p in scores) {
            s = scores[p]
            if (p == target) {
                s += 5.0
                found = 1
            } else {
                # Giảm điểm các file khác
                s = s * 0.98
            }
            
            # Chặn điểm đáy
            if (s < 1.0) s = 1.0
            
            printf "%.2f %s\n", s, p
        }
        
        # Nếu file mới toanh chưa từng có
        if (!found) {
            printf "5.00 %s\n", target
        }
    }' "$valid_log" | sort -k1,1nr -k2,2 | head -n 100 > "$tmp_log"
    
    mv "$tmp_log" "$log_file"
    rm -f "$valid_log"
end
