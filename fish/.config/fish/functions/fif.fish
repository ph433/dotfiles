# function fif --description "Tìm nội dung file bằng ripgrep và fzf"
#     rg --color=always --line-number --no-heading --smart-case $argv | \
#     fzf --ansi \
#         --color "hl:-1:underline,hl+:-1:underline:bold" \
#         --delimiter : \
#         --preview 'bat --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}' \
#         --preview-window 'up,60%,border-bottom,+{2}+3/3' \
#         --bind 'enter:become(vim +{2} {1})'
# end

function fif --description "Tìm kiếm nội dung realtime bằng ripgrep và fzf"
    # Dùng -g '!...' để loại trừ các đường dẫn/file cụ thể
    set -l RG_PREFIX "rg --column --line-number --no-heading --color=always --smart-case --hidden \
        -g '!.git/' \
        -g '!.cache/' \
        -g '!.local/share/fish/fish_history' \
        -g '!node_modules/'"
    
    fzf --ansi \
        --disabled \
        --query "$argv" \
        --bind "start:reload:$RG_PREFIX -- {q}" \
        --bind "change:reload:$RG_PREFIX -- {q} || true" \
        --delimiter : \
        --preview 'bat --color=always --highlight-line {2} {1} 2>/dev/null || cat {1}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3' \
        --bind 'enter:become(vim +{2} {1})'
end
