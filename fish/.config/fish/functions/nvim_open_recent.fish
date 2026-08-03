function nvim_open_recent --description "Mở file Neovim gần đây nhất từ log"
    set -l log_file "$HOME/.cache/nvim_recent.log"

    if test -f "$log_file"
        # Sắp xếp cột 1 (timestamp) giảm dần, lấy dòng đầu tiên, và cắt bỏ cột timestamp để lấy đường dẫn file
        set -l latest_file (sort -rn "$log_file" | head -n 1 | string replace -r '^\d+\s+' '')

        if test -n "$latest_file"; and test -f "$latest_file"
            # Xóa dòng hiện tại trên terminal trước khi mở nvim để tránh rác lệnh
            commandline -r ""
            nvim "$latest_file"
            # Ép Fish vẽ lại prompt sau khi thoát nvim
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
