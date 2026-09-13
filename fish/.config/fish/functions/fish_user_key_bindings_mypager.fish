function fish_user_key_bindings_mypager
    set -l mode mypager
    
    bind --mode $mode up 'history_fzf'
    
    for char in (string split '' '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!"#$%&\'()*+,-./:;<=>?@[\]^_`{|}~')
        bind --mode $mode $char self-insert
    end
    
    bind --mode $mode space self-insert
    bind --mode $mode backspace backward-delete-char
    bind --mode $mode delete delete-char
    bind --mode $mode enter -m default execute
    bind --mode $mode escape -m default cancel
    bind --mode $mode up up-line
    bind --mode $mode down down-line
    bind --mode $mode left backward-char
    bind --mode $mode right forward-char
    bind --mode $mode ctrl-c -m default clear-commandline
    bind --mode $mode tab complete
end
