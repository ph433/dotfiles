if status is-interactive
    # --- Biệt danh (Aliases & Abbreviations) ---
    alias cat="bat"
    alias ls="eza --icons --group-directories-first"
    alias ll="eza -lah --icons --group-directories-first"
    alias lt="eza --tree --level=2 --icons --group-directories-first"
    alias lta="eza --tree --level=2 --icons --group-directories-first -a --color=always"
    
    alias grep="rg"
    alias find="fd"
    alias g="git"
    alias v="nvim"

    # --- Khởi tạo ứng dụng (App Inits) ---
    zoxide init fish | source
    atuin init fish | source
    starship init fish | source
end
