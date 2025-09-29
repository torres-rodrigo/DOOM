#!/bin/bash

echo "Installing Core Packages..."

# Create an array of packages to install.
CORE_PACKAGES=(
    "xdg-desktop-portal"
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-hyprland"
    #"btop"
    "uwsm"
    #"power-profiles-daemon"
    #"dust"
    "fastfetch"
    #"ffmpeg"
    #"yazi"
    #"qt5-wayland"
    "tree-sitter-cli"
    "jujutsu" 
    #"lazygit"
    #"mako"
    "luarocks"
    "rofi-wayland"

    # --- TERMINAL & SHELL ---
    "kitty"
    "ghostty"

    # --- FONTS ---
    #noto-fonts

    # --- WEB ---
    #"firefox"
    
    # --- AUDIO ---

    # --- HYPR ---
    "hyprland"
    #"hypridle"
    #"hyprland-qtutils"
    #"hyprlock"
    #"hyprshot"

    # --- GENERAL ---
    #"obsidian"
    #"libreoffice-still"
    #"thunar"
    #"inkscape"
    #"localsend"
    #"gimp"
)

sudo pacman -S --noconfirm --needed "${CORE_PACKAGES[@]}"

echo "Core packages installed successfully."
echo "=================================================="
echo
