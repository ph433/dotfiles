#!/usr/bin/env bash

gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0']"

# Đặt tên cho phím tắt
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ name 'Flameshot Screenshot'

# Đặt lệnh thực thi
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ command 'flameshot gui'

# Đặt tổ hợp phím (Sử dụng <Alt>c)
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ binding "['<Alt>c']"