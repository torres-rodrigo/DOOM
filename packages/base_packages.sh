#!/bin/bash

echo "Installing Base Packages..."

BASE_PACKAGES=(
    "base-devel"
    "bat"
    "curl"
    "eza"
    "fd"
    "fzf"
    "gum"
    "less"
    "man"
    "neovim"
    "ripgrep"
    "tealdeer"
    "tree"
    "unzip"
    "wget"
    "zsh"
)

sudo pacman -S --noconfirm --needed "${BASE_PACKAGES[@]}"

echo "Base packages installed successfully."
echo "=================================================="
echo
