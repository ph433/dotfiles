" Vim syntax file for Kanata (.kbd)
if exists("b:current_syntax")
  finish
endif

" 1. Các khối từ khóa cấu hình hệ thống chính
syn keyword kanataKeyword defcfg defsrc deflayer defalias defchords deftmeta process-unmapped-keys

" 2. Các tên alias khi được gọi (có dấu @ đứng trước)
syn match kanataAlias "\v\@[a-zA-Z0-9_-]+"

" 3. TÁCH BIỆT CÁC HÀM HÀNH ĐỘNG KHÁC NHAU CỦA KANATA
" 3a. Nhóm chuyển Layer (Trọng tâm nhất)
syn match kanataLayerAction "\v<(layer-switch|layer-toggle|layer-add|layer-rem)>"
" 3b. Nhóm Gom tổ hợp & Chuỗi phím
syn match kanataComboAction "\v<(multi|macro)>"
" 3c. Nhóm Sự kiện thời gian & Tính năng nâng cao
syn match kanataTimeAction "\v<(one-shot|one-shot-press|tap-hold|tap-hold-release|release-key|tap-dance)>"

" Fallback cho bất kỳ hàm lạ nào nằm sau dấu mở ngoặc đơn
syn match kanataAction "\v\(\zs[a-zA-Z0-9_-]+[?!]="

" 4. Nhận diện tổ hợp phím Modifiers dạng viết tắt (C-z, A-c, C-A-del...)
syn match kanataChord "\v<[CAGMHS](-[CAGMHS])?-[a-zA-Z0-9_-]+"

" 5. ĐỊNH NGHĨA PHÍM CHỨC NĂNG (Bao phủ cả phím số đơn lẻ 0-9 khi đứng độc lập làm phím bấm)
syn match kanataSpecialKey "\v<(esc|tab|caps|lsft|lctl|lmet|lalt|ralt|rsft|rctl|rmet|spc|ret|ent|enter|alt)>" containedin=ALL
syn match kanataSpecialKey "\v<(up|down|left|rght|bspc|del|ins|prtsc|home|end|pgup|pgdn|nlck)>" containedin=ALL
syn match kanataSpecialKey "\v<f[0-9]{1,2}>" containedin=ALL
syn match kanataSpecialKey "\v\s\zs[0-9]\ze(\s|$)" containedin=ALL

" 6. Nhận diện các phím Numpad (kp7, kp8, kprt...)
syn match kanataNumpad "\v<kp[a-zA-Z0-9*+-/.]+>" containedin=ALL

" 7. Nhận diện các thông số số (Thời gian delay: 1000, 500, 200...)
" Chỉ nhận diện số có từ 2 chữ số trở lên để tránh đè vào phím số đơn lẻ
syn match kanataNumber "\v<[0-9]{2,}>" containedin=ALL

" 8. Nhận diện tên định nghĩa Alias ở đầu dòng (c04, rb01, shin, aa_1, a_1...)
syn match kanataAliasDef "\v(^|\s)\zs[a-zA-Z0-9_-]+\ze\s+\("

" 9. Nhận diện các ký tự đơn lẻ trong chuỗi Macro (v, i, w, c, g, n...)
syn match kanataMacroChar "\v\s\zs[a-zA-Z]\ze(\s|$)" containedin=ALL

" 10. Nhận diện dấu đóng mở ngoặc đơn
syn match kanataDelimiter "[()]"

" 11. Nhận diện chú thích (comment) bằng dấu chấm phẩy
syn match kanataComment ";.*$"

" ==========================================================================
" ÉP MÀU ĐỘC LẬP - PHÂN CẤP THỊ GIÁC CAO CẤP
" ==========================================================================
hi kanataKeyword      ctermfg=208 guifg=#ff8700  " Màu Cam (Từ khóa chính: defalias, deflayer...)
hi kanataAliasDef     ctermfg=81  guifg=#5fd7ff  " Màu Xanh Ngọc (Tên định nghĩa: aa_1, c_st...)
hi kanataAlias        ctermfg=220 guifg=#ffdf00  " Màu Vàng (Các phím gọi @alias)

" Tách biệt 3 nhóm hàm
hi kanataLayerAction  ctermfg=197 guifg=#ff005f  " Màu Đỏ Hồng Neon (Chuyển Layer: layer-switch, layer-toggle)
hi kanataComboAction  ctermfg=215 guifg=#ffaf5f  " Màu Cam Cát / Vàng Nhạt (Gom cụm: multi, macro)
hi kanataTimeAction   ctermfg=175 guifg=#d787af  " Màu Tím Hồng / Tím Khói (Thời gian: tap-dance, one-shot-press)
hi kanataAction       ctermfg=211 guifg=#ff87af  " Màu Hồng chung cho các hàm khác nếu có

hi kanataSpecialKey   ctermfg=121 guifg=#87ffaf  " Màu Xanh Lá Sáng (Các phím: lctl, lalt, tab, left, phím số 1, 2, 3...)
hi kanataNumber       ctermfg=141 guifg=#af87ff  " Màu Tím Sáng (Cho thông số delay: 1000, 200)
hi kanataMacroChar    ctermfg=223 guifg=#ffd7af  " Màu Kem nhẹ (Các chữ đơn lẻ trong macro)
hi kanataChord        ctermfg=135 guifg=#af5fff  " Màu Tím đậm (Các tổ hợp C-z, A-c)
hi kanataNumpad       ctermfg=197 guifg=#ff005f  " Màu Đỏ (Các phím Numpad)
hi kanataNormalKey    ctermfg=244 guifg=#808080  " Màu Xám nhẹ (Cho các dấu gạch ngang '-')
hi kanataDelimiter    ctermfg=246 guifg=#949494  " Màu Trắng Chì (Dấu ngoặc đơn chìm xuống nền)
hi kanataComment      ctermfg=242 guifg=#6c6c6c  " Màu Xám mờ (Chú thích)

let b:current_syntax = "kanata"
