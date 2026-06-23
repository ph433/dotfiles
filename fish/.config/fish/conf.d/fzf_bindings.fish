if status is-interactive
    set -l vi_modes default insert
    for mode in default insert
        bind --mode $mode down 'fzf_menu'
	bind --mode $mode ctrl-x 'y'
	bind --mode $mode ctrl-p 'fzf_menu_git'
	bind --mode $mode shift-left 'prevd; commandline -f repaint'
	bind --mode $mode shift-right 'nextd; commandline -f repaint'
	bind --mode $mode ctrl-y 'fzf_menu_aliases'
    end
end
