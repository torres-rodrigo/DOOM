#!/bin/bash
set -euo pipefail

# This script only ensures packages are installed
# User must run 'doom-setup-fingerprint' to enroll

echo "Installing fingerprint support packages..."

if sudo pacman -S --noconfirm --needed fprintd usbutils; then
    echo "Fingerprint packages installed successfully"
    echo "Run 'doom-setup-fingerprint' to configure your fingerprint scanner"
else
    echo "Error: Failed to install fingerprint packages"
    exit 1
fi
