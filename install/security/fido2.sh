#!/bin/bash
set -euo pipefail

# This script only ensures packages are installed
# User must run 'doom-setup-fido2' to register device

echo "Installing FIDO2/Yubikey support packages..."

if sudo pacman -S --noconfirm --needed libfido2 pam-u2f; then
    echo "FIDO2 packages installed successfully"
    echo "Run 'doom-setup-fido2' to register your FIDO2 device"
else
    echo "Error: Failed to install FIDO2 packages"
    exit 1
fi
