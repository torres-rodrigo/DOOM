#!/bin/bash

echo "Installing Core Packages..."

# Create an array of packages to install.
CORE_PACKAGES=(
    "base-devel"
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-hyprland"
    "git"
    "curl"
    "wget"
    "unzip"
    "less"
    "man"
    "bat"
    "btop"
    "uwsm"
    "power-profiles-daemon"
    "neovim"
    "dust"
    "tree"
    "fastfetch"
    "ffmpeg"
    "fd"
    "fzf"
    "ripgrep"
    "gum"
    "yazi"
    "qt5-wayland"
    "tree-sitter-cli"
    "jujutsu"
    "tealdeer"
    "lazygit"
    "mako"
    "luarocks"
    "eza"
    # --- XDG ---
    # --- TERMINAL & SHELL ---
    "ghostty"
    "zsh"

    # --- FONTS ---
    noto-fonts

    # --- WEB ---
    "firefox"
    
    # --- AUDIO ---

    # --- HYPR ---
    "hyprland"
    "hypridle"
    "hyprland-qtutils"
    "hyprlock"
    "hyprshot"

    # --- GENERAL ---
    #"obsidian"
    #"libreoffice-still"
    "thunar"
    #"inkscape"
    #"localsend"
    #"gimp"
    
)

pacman -S --noconfirm --needed "${CORE_PACKAGES[@]}"

echo "Core packages installed successfully."
echo "---------------------------------"
echo
