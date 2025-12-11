#!/bin/bash

mkdir -p "$CARGO_HOME"
mkdir -p "$RUSTUP_HOME"

sudo pacman -S --noconfirm --needed rust

BUILD_DIR="$(mktemp -d)"
cd "$BUILD_DIR"

git clone https://aur.archlinux.org/paru.git
cd paru

makepkg -si --noconfirm

cd $HOME
rm -rf "$BUILD_DIR"

echo "PARU AUR helper installed"
echo
