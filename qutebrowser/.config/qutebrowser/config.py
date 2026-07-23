# Tắt nạp autoconfig.yml bị dính tùy chọn cũ
config.load_autoconfig(False)

# Bật JavaScript
c.content.javascript.enabled = True
c.tabs.show = 'never'
# Phím tắt chuyển tab Ctrl + Left/Right trong Normal mode
config.bind('<Ctrl-Left>', 'tab-prev', mode='normal')
config.bind('<Ctrl-Right>', 'tab-next', mode='normal')
config.bind('<Ctrl-o>', 'set-cmd-text -s :open -w')
config.bind('D', 'close')
config.bind('<Backspace>', 'back')
config.bind('<Shift-Backspace>', 'forward')
# config.bind(';', 'spawn --userscript ~/.local/bin/qute-history.sh')
config.bind(';', 'spawn alacritty --class floating_fzf -e /home/phuong/.local/bin/qute-history.sh')
