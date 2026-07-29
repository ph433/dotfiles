function fullfunc --description "Lọc danh sách hàm Fish Shell bằng fzf và xem chi tiết"
    set -l selected_func (functions -a | string split " " | string match -v "" | fzf \
        --reverse \
        --header="Gõ để tìm hàm..." \
        --prompt="> " \
        --pointer="›" \
        --color="header:italic:240,prompt:240,pointer:212,hl:#ff79c6,hl+:#ff79c6:underline" \
        --height=100%)

    if test -n "$selected_func"
        # Hiển thị mã nguồn/nội dung của hàm được chọn
        $selected_func
    end
end
