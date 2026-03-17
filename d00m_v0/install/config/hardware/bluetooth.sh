# Enable the Bluetooth service.

echo "Configuring Bluetooth..."

systemctl_enable bluetooth.service

if command -v rfkill &>/dev/null; then
  sudo rfkill unblock bluetooth || echo "WARNING: Could not unblock bluetooth via rfkill."
fi

echo "Bluetooth: OK"
