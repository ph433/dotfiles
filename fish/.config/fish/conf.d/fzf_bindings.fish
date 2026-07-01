if status is-interactive
    set -l vi_modes default insert
    for mode in default insert
        # bind --mode $mode down '__fish_exec_in_main_mode_only fzf_menu'
        bind down '__fish_exec_in_main_mode_only down-line fzf_menu'
	bind tab complete-and-search
	bind shift-tab complete
	bind --mode $mode ctrl-x 'y'
	bind --mode $mode ctrl-p 'fzf_menu_git'
	bind --mode $mode shift-left 'prevd; commandline -f repaint'
	bind --mode $mode shift-right 'nextd; commandline -f repaint'
    end
end
