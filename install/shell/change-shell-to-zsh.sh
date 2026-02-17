#!/bin/bash
set -euo pipefail

echo "Changing default shell to zsh..."

# Check if zsh is installed
if ! command -v zsh &>/dev/null; then
    echo "Error: zsh is not installed"
    echo "Please install zsh first: sudo pacman -S zsh"
    return 1
fi

# Get zsh path
ZSH_PATH=$(which zsh)
echo "Found zsh at: $ZSH_PATH"

# Check if zsh is in /etc/shells
if ! grep -q "^$ZSH_PATH$" /etc/shells; then
    echo "Warning: $ZSH_PATH not found in /etc/shells"
    echo "Adding it now..."
    echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

# Change default shell for current user
echo "Changing shell for user: $USER"
sudo chsh -s "$ZSH_PATH" "$USER"

echo "✓ Default shell changed to zsh"
