function cd_smart_toggle --description "Toggle giữa HOME và thư mục gần nhất trong log"
    if test "$PWD" = "$HOME"
        # 1. Nếu đang ở HOME -> Chuyển đến thư mục gần nhất trong log
        set -l log_file "$HOME/.cache/dir_recent.log"
        
        if test -f "$log_file"
            # Đọc file log, loại bỏ timestamp và đảo ngược danh sách (mới nhất lên đầu)
            set -l recent_dirs (string replace -r '^[0-9]+\s+' '' < "$log_file")[-1..1]
            
            for dir in $recent_dirs
                if test -d "$dir"; and test "$dir" != "$HOME"
                    cd "$dir"
                    commandline -f repaint
                    return 0
                end
            end
        end
    else
        # 2. Nếu KHÔNG ở HOME -> Trở về HOME
        cd "$HOME"
        commandline -f repaint
    end
end
