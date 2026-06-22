#!/bin/bash

# Thoát script ngay lập tức nếu có bất kỳ lệnh nào bị lỗi
set -e

echo "=================================================="
echo "   BẮT ĐẦU CÀI ĐẶT TỰ ĐỘNG ARCH LINUX + DWM"
echo "=================================================="

sudo pacman -Syu --noconfirm \
    xorg-server \
    xorg-xinit \
    base-devel \
    git \
    libx11 \
    libxinerama \
    libxft \
    imlib2 \
    stow \
    alacritty \
    eza \
    fd \
    ripgrep \
    bat \
    fish \
    zoxide \
    atuin \
    neovim \
    starship \
    yazi \
    copyq \
    tree \
    fzf \
    git-delta \
    mpv \
    firefox \
    fcitx5 \
    fcitx5-bamboo \
    fcitx5-configtool \
    fcitx5-gtk \
    fcitx5-qt \
    xclip \
    maim \
    ueberzugpp \
    ttf-jetbrains-mono-nerd \
    jq \
    yt-dlp
