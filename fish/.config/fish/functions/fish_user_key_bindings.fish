function fish_user_key_bindings
    # 1. Các phím tắt chuẩn
    bind enter __nvim_open_latest_recent
    bind down "__fish_exec_in_main_mode_only down-line _down_fzf_recent_or_menu"
    bind right _right_or_fzf_recent
    bind insert _enter_or_fzf_zoxide
    bind left _left_or_fzf_find
    bind home _home_or_fzf_search_dir
    bind end _end_or_fzf_find
    bind space _space_or_fzf_recent
    bind escape _escape_handler
    bind backspace _backspace_become_ll
    bind delete _del_or_become_lta
    bind ctrl-a _crl-a_or_become_pwd
    bind 1 _handle_key_1
    bind insert '_insert_or_function'

    # 2. Cấu hình phím tắt cho Vi mode (Gộp từ Ảnh 2 sang)
    for mode in default insert
        bind --mode $mode ctrl-x 'y'
        bind --mode $mode ctrl-p 'fzf_menu_git'
        bind --mode $mode shift-left 'prevd; commandline -f repaint'
        bind --mode $mode shift-right 'nextd; commandline -f repaint'
    end
end
