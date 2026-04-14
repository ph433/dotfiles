#!/usr/bin/env bash

# 1. Reset danh sách phím tắt (Dọn dẹp "vỏ" ngoài)
gsettings set org.cinnamon.desktop.keybindings custom-list "[]"
gsettings set org.cinnamon.desktop.keybindings.media-keys terminal "['']"
sleep 0.3

# 2. Khai báo lại danh sách
gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0', 'custom1', 'custom2']"

# --- CUSTOM 0: Flameshot ---
P0="/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$P0 name 'Flameshot'
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$P0 command 'flameshot gui --accept-on-select --clipboard'
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$P0 binding "['<Alt>c']"

P00="/org/cinnamon/desktop/keybindings/custom-keybindings/custom1/"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$P00 name 'Flameshot'
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$P00 command 'flameshot gui'
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$P00 binding "['<Primary><Alt>c']"

# --- CUSTOM 2: Alacritty New ---
P2="/org/cinnamon/desktop/keybindings/custom-keybindings/custom2/"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$P2 name 'Alacritty New'
FORCE_CMD="bash -c 'alacritty & pid=\$!; xdotool search --sync --pid \$pid windowactivate'"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$P2 command "$FORCE_CMD"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:$P2 binding "['<Primary><Alt>t']"

# 3. Ép cấu hình hệ thống
gsettings set org.cinnamon.desktop.wm.preferences focus-new-windows 'smart'
gsettings set org.cinnamon.muffin focus-stealing-prevention false 2>/dev/null

echo "✅"