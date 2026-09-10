set -gx fzf_fd_opts --type=d --hidden --follow --exclude=.git --color=always
set -gx EZA_CONFIG_DIR $HOME/.config/eza
set -x BAT_THEME "Dracula"
set -g fish_greeting ""
set -x MY_QUICK_DIR
set -gx MY_QUICK_DIR ~/dotfiles
set -gx FZF_DEFAULT_OPTS "
  --prompt='NORMAL > ' \
  --bind='b:accept,j:down,k:up,q:abort' \
  --bind='a:unbind(a,b,j,k,q)+change-prompt(INSERT > )' \
  --bind='esc:transform:[ \"\$FZF_PROMPT\" = \"INSERT > \" ] && echo \"rebind(a,b,j,k,q)+change-prompt(NORMAL > )\" || echo \"abort\"'
"
# set -g fish_key_bindings fish_vi_key_bindings
# source ~/.config/fish/myshortcuts.fish
# set -x LS_COLORS "$LS_COLORS:.ICEAuthority=38;2;255;184;108:"
# set -gx LS_COLORS (cat ~/.config/fish/.ls_colors)
# set -gx LS_COLORS (cat ~/dotfiles/fish/.config/fish/.ls_colors)
