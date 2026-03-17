# Set up prerequisites for mango WM.
# seatd manages DRM/KMS device access without requiring root or logind.
# The user must be in the seat group for mango to open the display.

echo "Setting up mango WM prerequisites..."

systemctl_enable seatd.service

if ! groups "$USER" | grep -qw "seat"; then
  sudo usermod -aG seat "$USER"
  echo "Added $USER to seat group (takes effect on next login)."
fi

echo "Mango WM prerequisites: OK"
