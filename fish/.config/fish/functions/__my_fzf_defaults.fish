function __my_fzf_defaults --description "Cấu hình giao diện mặc định cho fzf"
    set -l opts \
        --reverse \
        --pointer="›" \
        --color="header:italic:240,prompt:240,pointer:212,hl:#ff79c6,hl+:#ff79c6:underline" \
        --height=100%
    
    # In ra từng dòng để Fish hiểu là các phần tử mảng riêng biệt
    printf "%s\n" $opts
end
