#!/bin/bash

echo "Setting Up PARU"

export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

mkdir -p "$CARGO_HOME"
mkdir -p "$RUSTUP_HOME"

pacman -S --noconfirm --needed rust

BUILD_DIR="$(mktemp -d)"
cd "$BUILD_DIR"

git clone https://aur.archlinux.org/paru.git
cd paru

# Build and install paru
makepkg -si --noconfirm

# Clean up
cd ~
rm -rf "$BUILD_DIR"

echo "PARU installed"
echo "=================================================="