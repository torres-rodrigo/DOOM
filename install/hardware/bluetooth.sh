#!/bin/bash
set -euo pipefail

echo "Configuring Bluetooth..."

# Enable and start bluetooth service
if sudo systemctl enable bluetooth.service; then
    echo "Bluetooth service enabled"
else
    echo "Warning: Failed to enable bluetooth service"
fi

# Unblock bluetooth if blocked
if command -v rfkill &>/dev/null; then
    sudo rfkill unblock bluetooth || {
        echo "Warning: Could not unblock bluetooth"
    }
else
    echo "Warning: rfkill not found, skipping bluetooth unblock"
fi

echo "Bluetooth configuration complete"
