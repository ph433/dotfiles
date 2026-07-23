# Tắt nạp autoconfig.yml bị dính tùy chọn cũ
config.load_autoconfig(False)

# Bật JavaScript
c.content.javascript.enabled = True
# c.tabs.show = 'never'
# Phím tắt chuyển tab Ctrl + Left/Right trong Normal mode
config.bind('<Ctrl-Left>', 'tab-prev', mode='normal')
config.bind('<Ctrl-Right>', 'tab-next', mode='normal')
config.bind('<Ctrl-o>', 'set-cmd-text -s :open -w')
config.bind('D', 'close')
config.bind('<Backspace>', 'back')
config.bind('<Shift-Backspace>', 'forward')
config.bind('<Ctrl-Backspace>', 'undo')
config.bind('x', 'tab-only')
config.bind('H', 'open -t qute://history')
config.bind('<Ctrl-Up>', 'tab-move -')
config.bind('<Ctrl-Down>', 'tab-move +')
config.bind(';', 'spawn alacritty --class floating_fzf -e /home/phuong/.local/bin/qute-history.sh')
config.bind('<Insert>', 'mode-enter insert', mode='normal')
config.bind('<Escape>', 'mode-leave', mode='insert')
config.unbind('<Return>', mode='normal')
c.input.insert_mode.auto_enter = False
c.input.insert_mode.auto_leave = False
c.input.insert_mode.auto_load = False
config.bind('<Escape>', 'clear-keychain ;; jseval --quiet document.activeElement.blur()', mode='normal')
