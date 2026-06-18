function fzfrecent -d "Tìm file dựa trên lịch sử mở trong Neovim (Dashboard Top 10)"
    set log_file "$HOME/.cache/nvim_recent.log"

    if not test -f "$log_file"
        echo "Chưa có dữ liệu lịch sử file."
        return 1
    end

    # 1. Lọc lấy tối đa 10 file mới nhất và loại bỏ trùng lặp
    set -l top10 (awk '{time=$1; sub(/^[0-9]+ /, ""); map[$0]=time} END {for (p in map) print map[p] " " p}' $log_file | sort -nr | head -n 10)
    
    # GHI ĐÈ LẠI LOG: Xóa các file cũ, giữ cho log luôn chỉ có tối đa 10 dòng
    if test -n "$top10"
        printf "%s\n" $top10 > $log_file
    end

    # 2. Tạo danh sách đánh số từ 0 đến 9
    set -l list (printf "%s\n" $top10 | awk '{time=$1; sub(/^[0-9]+ /, ""); printf "%d │ %-16s │ %s\n", NR-1, strftime("%Y-%m-%d %H:%M", time), $0}')

    # 3. Đưa vào fzf
    # --layout=reverse: Đẩy thanh chọn lên trên cùng
    # --preview-window="bottom:70%": Khung preview nằm dưới, chiếm 70% (tức là phần chọn trên 30%)
    # --expect: Bắt các phím số (0-9) và phím chức năng để xử lý tức thì
    set -l fzf_out (printf "%s\n" $list | fzf \
        --prompt="🕒 Nvim Recent (0-9)> " \
        --delimiter=' │ ' \
        --nth=3 \
        --tiebreak=index \
        --preview="bat --color=always {3} 2>/dev/null || cat {3}" \
        --preview-window="bottom:70%" \
        --expect=0,1,2,3,4,5,6,7,8,9,right,enter \
        --layout=reverse \
        --height=100%)

    # Nhận diện phím đã bấm và nội dung dòng hiện hành
    set -l key $fzf_out[1]
    set -l selected_line $fzf_out[2]

    # Nhấn Esc (không có key)
    if test -z "$key"
        return
    end

    set -l target_path ""

    # TH1: Nếu bấm phím số từ 0 đến 9
    if string match -r '^[0-9]$' "$key" >/dev/null
        # Đổi phím số thành index mảng (Fish array đếm từ 1)
        set -l idx (math $key + 1)
        
        # Chặn lỗi nếu bấm số vượt quá số file thực tế đang có (VD: log mới có 5 file mà bấm số 8)
        if test $idx -le (count $list)
            set target_path (echo $list[$idx] | awk -F ' │ ' '{print $3}')
        else
            return
        end
    else
        # TH2: Nếu bấm Enter hoặc Right mũi tên
        if test -z "$selected_line"
            return
        end
        set target_path (echo "$selected_line" | awk -F ' │ ' '{print $3}')
    end

    # Hành động cuối cùng
    if test "$key" = "right"
        # Bấm mũi tên Phải -> Copy đường dẫn
        if type -q wl-copy
            echo -n "$target_path" | wl-copy
        else if type -q pbcopy
            echo -n "$target_path" | pbcopy
        else if type -q xclip
            echo -n "$target_path" | xclip -selection clipboard
        end
        echo "📋 Đã copy: $target_path"
    else
        # Bấm Số (0-9) hoặc Enter -> Mở Neovim
        nvim "$target_path"
    end
end
