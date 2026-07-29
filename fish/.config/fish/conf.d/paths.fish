# fish_add_path -g $HOME/.cargo/bin
# fish_add_path -g $HOME/.local/bin
# fish_add_path -g $HOME/.fzf/bin

for p in $HOME/.cargo/bin $HOME/.local/bin $HOME/.fzf/bin
    if test -d $p; and not contains $p $PATH
        set -gx PATH $p $PATH
    end
end
