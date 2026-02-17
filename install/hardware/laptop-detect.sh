#!/bin/bash
set -euo pipefail

echo "Detecting laptop/battery configuration..."

# Check if running on battery-powered device
# Use compgen for safe glob matching (|| echo 0 handles no matches)
BATTERY_COUNT=$(compgen -G "/sys/class/power_supply/BAT*" 2>/dev/null | wc -l || echo 0)

if [[ "$BATTERY_COUNT" -gt 0 ]]; then
    echo "Laptop/battery detected ($BATTERY_COUNT battery/batteries) - configuring power management"

    # Set balanced power profile for laptops
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set balanced || {
            echo "Warning: Could not set power profile to balanced"
        }
    else
        echo "Warning: powerprofilesctl not found, skipping power profile setup"
    fi

    # Enable battery monitoring for low battery notifications
    if systemctl --user enable --now doom-battery-monitor.timer; then
        echo "Battery monitoring enabled"
    else
        echo "Warning: Failed to enable battery monitoring timer"
    fi
else
    echo "Desktop system detected - setting performance profile"
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set performance || {
            echo "Warning: Could not set power profile to performance"
        }
    else
        echo "Warning: powerprofilesctl not found, skipping power profile setup"
    fi
fi

echo "Power profile configured"
