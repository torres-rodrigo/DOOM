#!/bin/bash

echo "Installing Core Packages..."

# Create an array of packages to install.
CORE_PACKAGES=(
    # --- SYSTEM & UTILITIES ---
    "base-devel"
    "curl"
    "wget"
    "unzip"
    "bat"
    "btop"
    "dust"
    "tree"
    "eza"
    "fastfetch"
    "ffmpeg"
    "fzf"
    "ripgrep"
    "gum"
    "yazi"
    "less"
    "man"
    "tree-sitter-cli"
    "jujutsu"
    "tealdeer"
    "lazygit"

    # --- XDG ---
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-hyprland"

    # --- TERMINAL & SHELL ---
    "ghostty"
    "zsh"

    # --- FONTS ---
    noto-fonts

    # --- EDITORS ---
    "neovim"

    # --- WEB ---
    "firefox"
    
    # --- AUDIO ---
    "pipewire"
    "wireplumber"
    "pavucontrol"

    # --- HYPR ---
    "hypridle"
    "hyprland"
    "hyprland-qtutils"
    "hyprlock"
    "hyprshot"

    # --- GENERAL ---
    "obsidian"
    "libreoffice-still"
    
)

pacman -S --noconfirm --needed "${CORE_PACKAGES[@]}"

echo "Core packages installed successfully."
echo "---------------------------------"
echo
