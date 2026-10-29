function nvim_open_recent_nano --description "Mở file gần đây nhất từ log bằng nano"
    set -l log_file "$HOME/.cache/nvim_recent.log"

    if test -f "$log_file"
        # Lấy dòng cuối, cắt bỏ cột timestamp để lấy đường dẫn file
        set -l latest_file (tail -n 1 $log_file | string replace -r '^\d+\s+' '')

        if test -n "$latest_file"; and test -f "$latest_file"
            # Xóa dòng lệnh hiện tại trên terminal trước khi mở nano
            commandline -r ""
            nano "$latest_file"
            # Ép Fish vẽ lại prompt sau khi thoát nano
            commandline -f repaint
        else
            echo -e "\n[Lỗi] File không tồn tại hoặc đường dẫn trống: $latest_file"
            commandline -f repaint
        end
    else
        echo -e "\n[Lỗi] Không tìm thấy file log: $log_file"
        commandline -f repaint
    end
end
