function _fzf_preview_dir_custom --description "Chuyên dụng cho Directory Search Preview"
    set -f file_path $argv

    if test -L "$file_path" # Nếu gặp liên kết ẩn (Symlink)
        set -l target_path (realpath "$file_path")
        set_color yellow
        echo "'$file_path' is a symlink to '$target_path'."
        set_color normal
        _fzf_preview_dir_custom "$target_path" # Đệ quy để lội vào trong đích thực tế
    else if test -d "$file_path" # 🎯 NẾU LÀ THƯ MỤC: Táng thẳng eza dạng lưới
        if command -v eza >/dev/null
            eza --all --icons=always --color=always --grid "$file_path"
        else
            command ls -A -F --color=always "$file_path"
        end
    else if test -f "$file_path" # Dự phòng nếu lọt file vào
        if command -v bat >/dev/null
            bat --style=numbers --color=always --line-range :100 "$file_path"
        else
            cat "$file_path"
        end
    end
end
