# Enable network services, configure DNS, and disable WiFi power saving.

echo "Enabling network services..."

systemctl_enable iwd.service

# ── DNS: systemd-resolved stub resolver ──────────────────────────────────────
# archinstall leaves /etc/resolv.conf pointing directly at the router with no
# caching, no fallback, and no DNS leak protection.
# systemd-resolved adds local caching, DNSSEC validation, fallback servers
# (so DNS survives a dead router), and proper per-interface routing for VPNs.
#
# The stub resolver at 127.0.0.53 intercepts all queries — the symlink below
# makes every tool on the system use it automatically.
echo "Configuring DNS resolver..."

sudo mkdir -p /etc/systemd/resolved.conf.d

printf '[Resolve]\n# Primary: Cloudflare + Quad9\nDNS=1.1.1.1 9.9.9.9\n# Fallback if primary unreachable\nFallbackDNS=1.0.0.1 149.112.112.112\n# Validate when possible, downgrade gracefully if upstream does not support it\nDNSSEC=allow-downgrade\n# Use DNS-over-TLS when the server supports it, plain otherwise\nDNSOverTLS=opportunistic\nCache=yes\n' \
  | sudo tee /etc/systemd/resolved.conf.d/doom.conf >/dev/null

systemctl_enable systemd-resolved.service

# Point /etc/resolv.conf at the stub resolver — replaces whatever archinstall wrote
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# ── WiFi: disable power saving ────────────────────────────────────────────────
# Without this iwd inherits kernel power management defaults that cause ping
# spikes and dropped packets on idle connections. The udev rule fires at
# device-add time, before iwd takes ownership of the interface.
echo "Disabling WiFi power saving..."

printf 'ACTION=="add", SUBSYSTEM=="net", KERNEL=="wlan*", RUN+="/usr/bin/iw dev %%k set power_save off"\n' \
  | sudo tee /etc/udev/rules.d/81-wifi-powersave.rules >/dev/null

sudo udevadm control --reload-rules

echo "Network services: OK"
