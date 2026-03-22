# Configure greetd for auto-login into mango WM via UWSM.
# After the LUKS passphrase, the session starts automatically — no greeter prompt.

echo "Configuring greetd for auto-login..."

# Create greetd config directory if needed
sudo mkdir -p /etc/greetd

# Write auto-login config
cat <<EOF | sudo tee /etc/greetd/config.toml >/dev/null
[terminal]
vt = 1

[default_session]
# Auto-login directly into mango WM via UWSM (no greeter prompt after LUKS)
command = "uwsm start mango"
user = "$USER"
EOF

# greetd must NOT be started with --now during install — it would immediately
# launch the Wayland session mid-installation. Enable only; start on reboot.
sudo systemctl enable greetd.service

echo "greetd configured: auto-login as $USER → mango"
