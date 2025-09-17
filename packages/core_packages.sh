#!/bin/bash

echo "Installing Core Packages..."

# Create an array of packages to install.
CORE_PACKAGES=(
    # --- SYSTEM & UTILITIES ---
    "base-devel"
    "git"
    "curl"
    "wget"
    "unzip"
    "bat"
    "btop"
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
    "less"
    "man"
    "tree-sitter-cli"
    "jujutsu"
    "tealdeer"
    "lazygit"
    "power-profiles-daemon"
    "mako"
    "uwsm"
    "luarocks"
    "eza"

    # --- XDG ---
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-hyprland"

    # --- TERMINAL & SHELL ---
    "ghostty"
    "zsh"

    # --- FONTS ---
    noto-fonts

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
    "thunar"
    "inkscape"
    "localsend"
    "gimp"
    
)

pacman -S --noconfirm --needed "${CORE_PACKAGES[@]}"

echo "Core packages installed successfully."
echo "---------------------------------"
echo
