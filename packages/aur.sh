#!/bin/bash
set -euo pipefail

# Validate required directories
if [[ -z "${CARGO_HOME:-}" ]]; then
    echo "Error: CARGO_HOME is not set"
    exit 1
fi

if [[ -z "${RUSTUP_HOME:-}" ]]; then
    echo "Error: RUSTUP_HOME is not set"
    exit 1
fi

mkdir -p "$CARGO_HOME"
mkdir -p "$RUSTUP_HOME"

sudo pacman -S --noconfirm --needed rust

BUILD_DIR="$(mktemp -d)"

# Cleanup on exit
cleanup() {
    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
    fi
}
trap cleanup EXIT INT TERM

cd "$BUILD_DIR"

git clone https://aur.archlinux.org/paru.git
cd paru

makepkg -si --noconfirm

echo "PARU AUR helper installed"
echo

# Install AUR packages
echo "Installing AUR packages..."

# Only install ufw-docker if Docker is present
if command -v docker &>/dev/null; then
    echo "Docker detected - installing ufw-docker..."
    paru -S --noconfirm --needed ufw-docker
else
    echo "Docker not detected - skipping ufw-docker"
fi

echo "AUR packages installed"
echo
