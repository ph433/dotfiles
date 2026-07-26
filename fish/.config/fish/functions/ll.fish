function ll --wraps='eza -lah --icons --group-directories-first' --description 'Hien thi danh sach file chi tiet bang eza'
    eza -lah --icons=always --color=always --group-directories-first $argv
end
