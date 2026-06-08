function t
    if test (count $argv) -eq 0
        echo "Nhập tên bài hát nữa bạn ơi! Ví dụ: y lofi chill"
        return
    end

    echo "🔍 Đang bốc dữ liệu trực tiếp từ YouTube bằng yt-dlp..."

    # 1. yt-dlp lấy data
    # 2. jq parse thành TSV
    # 3. awk format dữ liệu và chèn các cột "|" ngăn cách bằng Tab (OFS='\t')
    # 4. column -t căn đều các cột theo Tab
    yt-dlp "ytsearch20:$argv" \
        --flat-playlist \
        --dump-json \
        --extractor-args "youtube:player_client=android" 2>/dev/null \
        | jq -r '[
            (.title // "Không rõ"), 
            (.channel // .uploader // "Không rõ"), 
            (.duration // 0), 
            (.view_count // 0), 
            .url
          ] | @tsv' \
        | awk -F '\t' -v OFS='\t' '
            function commas(n) {
                if (n == 0 || n == "null") return "N/A"
                r = ""
                while(length(n) > 3) {
                    r = "," substr(n, length(n)-2) r
                    n = substr(n, 1, length(n)-3)
                }
                return n r
            }
            {
                title = length($1) > 55 ? substr($1, 1, 52) "..." : $1
                channel = length($2) > 20 ? substr($2, 1, 17) "..." : $2
                
                m = int($3 / 60)
                s = int($3 % 60)
                time = sprintf("%d:%02d", m, s)
                
                views = commas($4)
                
                # In ra các trường cách nhau bởi Tab, tách riêng dấu "|" thành các cột độc lập để dễ căn lề
                print title, "|", channel, "|", time, "|", views, "|", $5
            }
        ' \
        | column -t -s (printf '\t') \
        | fzf --ansi --reverse --prompt="🎵 Chọn bài để quẩy: " \
        | read -l selected

    if test -n "$selected"
        # Lấy URL ở cột cuối cùng
        set -l video_url (echo $selected | awk '{print $NF}')
        
        # Lấy tiêu đề trước dấu "|" đầu tiên và xóa khoảng trắng 2 đầu
        set -l video_title (echo $selected | awk -F '\\|' '{print $1}')
        set video_title (string trim "$video_title")
        
        echo "▶️ Đang phát bài: $video_title"
        mpv --no-video "$video_url"
    else
        echo "Đã hủy chọn bài."
    end
end
