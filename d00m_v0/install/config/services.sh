# Enable user systemd services deployed by dotfiles.
# Note: --now is intentionally omitted — these services require a live Wayland
# session (wl-paste) which is not running during install. They start on next login.

echo "Enabling user services..."

systemctl --user enable doom-cliphist.service

echo "User services: OK"
