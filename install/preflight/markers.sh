# Install markers — set up state tracking and speed up package installs.

print_step "Setting install markers"

# Create the doom_v0 state directory
mkdir -p "$HOME/.local/state/doom_v0"

# Disable mkinitcpio hooks to speed up package installs.
# Each kernel or initramfs package install normally triggers a full initramfs rebuild.
# We suppress that here and do one final rebuild in post-install/initramfs.sh.
if [[ -f /etc/mkinitcpio.conf ]]; then
  sudo sed -i 's/^HOOKS=/#HOOKS=/' /etc/mkinitcpio.conf 2>/dev/null || true
fi

echo "Markers: OK"
