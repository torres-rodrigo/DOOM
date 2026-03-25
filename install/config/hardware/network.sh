# Enable network services and disable WiFi power saving.
# NetworkManager defaults to power-save on; without this fix iwd also inherits
# kernel power management defaults that cause ping spikes and dropped packets.
# A udev rule is used so it fires at device-add time, before iwd takes over,
# and works regardless of which network manager is in use.

echo "Enabling network services..."

systemctl_enable iwd.service

echo "Disabling WiFi power saving..."

printf 'ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="/usr/bin/iw dev %%k set power_save off"\n' \
  | sudo tee /etc/udev/rules.d/81-wifi-powersave.rules >/dev/null

sudo udevadm control --reload-rules

echo "Network services: OK"
