function lta --description 'Hien thi cay thu muc bang eza va dem dir/file (Pink & Yellow)'
    # 1. Hiển thị cây bằng eza
    eza --tree --level=2 --icons=always --color=always --group-directories-first -a $argv

    # 2. Đếm thư mục con + 1 (cho thư mục gốc '.')
    set -l subdirs (command find . -maxdepth 2 -mindepth 1 \( -type d -o -xtype d \) 2>/dev/null | wc -l | string trim)
    set -l dirs (math $subdirs + 1)

    # 3. Đếm tất cả file (file thật + symlink)
    set -l files (command find . -maxdepth 2 -mindepth 1 \( -type f -o -type l \) 2>/dev/null | wc -l | string trim)

    # 4. Logic chia số ít / số nhiều cho chữ
    set -l dir_label "directory"
    test $dirs -gt 1; and set dir_label "directories"

    set -l file_label "file"
    test $files -gt 1; and set file_label "files"

    # 5. In kết quả (Hồng cho Directory + Vàng cho File)
    echo
    echo (set_color --bold ff79c6)"$dirs "(set_color ff79c6)"$dir_label"(set_color normal)", "(set_color --bold f1fa8c)"$files "(set_color f1fa8c)"$file_label"(set_color normal)
end
