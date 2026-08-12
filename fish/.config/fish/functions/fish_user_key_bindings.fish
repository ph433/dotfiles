function fish_user_key_bindings
    set -l mode default
    bind --mode $mode up 'history_fzf'
    bind --mode $mode down '__smart_key_exec down'
    bind --mode $mode left '__smart_key_exec left'
    bind --mode $mode right '__smart_key_exec right'
    bind --mode $mode backspace '__smart_key_exec backspace ll'
    bind --mode $mode delete '__smart_key_exec delete lta'
    bind --mode $mode home '__smart_key_exec home'
    bind --mode $mode end '__smart_key_exec end'
    bind --mode $mode space '__smart_key_exec space'
    bind --mode $mode enter '__smart_key_exec enter'
    bind --mode $mode insert '__smart_key_exec insert'
    bind --mode $mode pageup '__smart_key_exec pageup'
    bind --mode $mode pagedown '__smart_key_exec pagedown'
    bind --mode $mode 1 '__smart_key_exec 1 mkd'
    bind --mode $mode 2 '__smart_key_exec 2 fullfunc'
    bind --mode $mode 3 '__smart_key_exec 3 fullbind'
    bind --mode $mode 4 '__smart_key_exec 4 fullvar'
    bind --mode $mode 5 '__smart_key_exec 5 __fish_fzf_complete'
    bind --mode $mode 9 '__smart_key_exec 9 fdf'
    bind --mode $mode 0 '__smart_key_exec 0 fdd'
    
    bind --mode $mode ctrl-a '__smart_key_exec ctrl-a pwd'
    bind --mode $mode ctrl-x 'y'
    bind --mode $mode ctrl-p 'fzf_menu_git'
    bind --mode $mode shift-left 'prevd; commandline -f repaint'
    bind --mode $mode shift-right 'nextd; commandline -f repaint'
    bind --mode $mode tab '__smart_pager_switch mypager'
    bind --mode $mode escape '__smart_pager_switch mypager search'
    fish_user_key_bindings_mypager
    
    # set -g fish_bind_mode default
end
