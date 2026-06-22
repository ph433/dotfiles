# ~/dotfiles/fish/.config/fish/conf.d/dracula.fish
# Module cấu hình màu Dracula True Color cho Fish Shell (Đã đồng bộ 100%)

set -g fish_term24bit 1

set -g fish_color_normal F8F8F2
set -g fish_color_command 50FA7B --bold
set -g fish_color_keyword FF79C6 --bold
set -g fish_color_quote F1FA8C
set -g fish_color_redirection 8BE9FD
set -g fish_color_end 50FA7B
set -g fish_color_error FF5555
set -g fish_color_param 8BE9FD              # Đã sửa về 8BE9FD chuẩn theo thực tế của bạn
set -g fish_color_comment 6272A4
set -g fish_color_match --background=6272A4
set -g fish_color_selection WHITE --bold --background=44475A
set -g fish_color_search_match 44475A --background=44475A
set -g fish_color_history_current --bold
set -g fish_color_operator BD93F9 --bold
set -g fish_color_escape FF79C6
set -g fish_color_cwd 50FA7B
set -g fish_color_cwd_root FF5555
set -g fish_color_valid_path --underline
set -g fish_color_autosuggestion 6272A4
set -g fish_color_user 8BE9FD
set -g fish_color_host 50FA7B
set -g fish_color_host_remote F1FA8C        # Thêm vào để đè bẹp 'yellow' cũ
set -g fish_color_status FF5555             # Thêm vào để đè bẹp 'red' cũ
set -g fish_color_cancel FF5555 --reverse

# function custom_dracula_prompt --on-event fish_prompt
#     # Xóa sạch cấu hình prompt cũ trước khi vẽ
#     functions -e fish_prompt
#
#     # Định nghĩa lại chuẩn True Color
#     function fish_prompt
#         set_color 50FA7B --bold
#         echo -n '❯❯❯ '
#         set_color normal
#     end
# end
