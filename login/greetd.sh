#!/bin/bash

echo "Configuring greetd with auto-login..."

# Remove the default agreety greeter if present
sudo pacman -Rdd greetd-agreety --noconfirm 2>/dev/null || true

# Create greetd config directory if needed
sudo mkdir -p /etc/greetd

# Create auto-login configuration
cat <<EOF | sudo tee /etc/greetd/config.toml
[terminal]
# Virtual terminal to run greeter on
vt = 1

[default_session]
# Auto-login directly to Hyprland via UWSM
command = "uwsm start hyprland"
user = "$USER"
EOF

# Enable greetd service to start at boot
sudo systemctl enable greetd.service

echo "greetd configured for auto-login as: $USER"
echo "After LUKS password, you will be automatically logged into Hyprland"
