set -gx fzf_fd_opts --type=d --hidden --follow --exclude=.git --color=always
set -gx EZA_CONFIG_DIR $HOME/.config/eza
set -x BAT_THEME "Dracula"
set -g fish_greeting ""
set -x MY_QUICK_DIR
set -gx MY_QUICK_DIR ~/dotfiles
# source ~/.config/fish/myshortcuts.fish
# set -x LS_COLORS "$LS_COLORS:.ICEAuthority=38;2;255;184;108:"
# set -gx LS_COLORS (cat ~/.config/fish/.ls_colors)
# set -gx LS_COLORS (cat ~/dotfiles/fish/.config/fish/.ls_colors)
