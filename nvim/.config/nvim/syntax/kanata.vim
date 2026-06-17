" Nội dung file ~/.config/nvim/syntax/kanata.vim
if exists("b:current_syntax")
  finish
endif

" =========================================================================
" 1. TỪ KHÓA ĐƠN
" =========================================================================
syntax keyword kanataBlock defcfg
syntax keyword kanataAliasBlock defalias
syntax keyword kanataSrc   defsrc
syntax keyword kanataLayer deflayer

syntax keyword kanataMulti multi
syntax keyword kanataMacro macro

" THÊM MỚI: Gom nhóm toàn bộ các phím Modifier phổ biến của Kanata
syntax keyword kanataModifier lctl rctl ctl ctrl lalt ralt alt lmet rmet met win lsft rsft sft shft shift

" =========================================================================
" 2. TỪ KHÓA CÓ DẤU GẠCH NGANG
" =========================================================================
syntax match kanataOSP  "\<one-shot-press\>\|\<one-shot\>"
syntax match kanataFunc "\<layer-toggle\>\|\<layer-switch\>\|\<tap-hold\>\|\<tap-dance\>"

" =========================================================================
" 3. REGEX
" =========================================================================
syntax match kanataNumber  "\<\d\+\>"
syntax match kanataAlias   "@[a-zA-Z0-9_-]\+"
syntax match kanataComment ";.*$"
syntax match kanataTemp "-temp\>\|\<temp\>"
" (Đã xóa dòng kanataChord để C-z, S-r, A-c tự động trở về màu mặc định)


" =========================================================================
" 4. ĐỊNH NGHĨA MÀU SẮC TRỰC TIẾP (DRACULA THEME)
" =========================================================================
hi kanataBlock      guifg=#FF0800 ctermfg=Red gui=bold
hi kanataSrc        guifg=#FF79C6 ctermfg=Magenta gui=bold
hi kanataLayer      guifg=#BD93F9 ctermfg=DarkMagenta gui=bold
hi kanataAliasBlock guifg=#F1FA8C ctermfg=Yellow gui=bold

hi kanataMulti      guifg=#50FA7B ctermfg=Green gui=bold
hi kanataMacro      guifg=#8BE9FD ctermfg=Cyan gui=bold
hi kanataOSP        guifg=#FFB86C ctermfg=LightRed gui=bold

hi kanataNumber     guifg=#FF9E64 ctermfg=LightRed
hi kanataFunc       guifg=#7AA2F7 ctermfg=Blue

" THÊM MỚI: Tô màu Đỏ Dracula in nghiêng cho các phím Modifier
hi kanataModifier   guifg=#FF5555 ctermfg=Red gui=italic

" Các nút alias (@tabii, @osl_d...) dùng màu Trắng sữa Dracula in nghiêng cho sang
hi kanataAlias guifg=#8BE9FD ctermfg=Cyan gui=italic

" Comment (;; ...) dùng màu Xanh xám bóng đêm chuẩn Dracula
hi kanataComment guifg=#6272A4 ctermfg=DarkGray gui=italic
hi kanataTemp guifg=#565F89 ctermfg=DarkGray gui=italic

let b:current_syntax = "kanata"
