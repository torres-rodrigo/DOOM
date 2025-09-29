#!/bin/bash

echo "Installing Paru Packages..."

PARU_PACKAGES=(
    "oh-my-posh"
    "walker"
    #"zen-browser-bin"

)

paru -S --noconfirm --needed "${PARU_PACKAGES[@]}"

echo "Base packages installed successfully."
echo "=================================================="
echo
