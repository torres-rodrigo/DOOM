# Install AUR packages via paru.
# Kept minimal intentionally — every AUR package is an unreviewed third-party
# build, so only install what cannot be sourced from official repos.

# Only install ufw-docker if Docker is present on the system
if command -v docker &>/dev/null; then
  echo "Docker detected — installing ufw-docker..."
  paru -S --noconfirm --needed ufw-docker
else
  echo "Docker not detected — skipping ufw-docker."
fi

paru -S --noconfirm --needed mangowm-git

echo "AUR packages: OK"
