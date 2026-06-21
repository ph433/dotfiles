#!/bin/bash

set -e

git clone --depth 1 https://aur.archlinux.org/kanata-bin.git
cd kanata-bin
makepkg -si --noconfirm

UDEV_SRC="$HOME/dotfiles/kanata/99-input.rules"
UDEV_DST="/etc/udev/rules.d/99-input.rules"

# Tạo nhóm quyền và thêm user trước
sudo groupadd --force uinput
sudo usermod -aG input $USER
sudo usermod -aG uinput $USER

sudo cp "$UDEV_SRC" "$UDEV_DST"
sudo udevadm control --reload-rules && sudo udevadm trigger

cd "$HOME/dotfiles"
stow --adopt --no-folding -v kanata

systemctl --user daemon-reload
systemctl --user enable --now kanata.service
