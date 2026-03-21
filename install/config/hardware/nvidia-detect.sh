# Detect NVIDIA GPU and install the appropriate driver.
# Injects required NVIDIA environment variables into the UWSM env file
# so they are set for every Wayland session.

echo "Checking for NVIDIA GPU..."

NVIDIA="$(lspci | grep -i 'nvidia' || true)"

if [[ -z "$NVIDIA" ]]; then
  echo "No NVIDIA GPU detected — skipping."
  return 0 2>/dev/null || exit 0
fi

echo "NVIDIA GPU detected: $NVIDIA"

# Detect installed kernel for matching headers package
KERNEL_NAME="$(pacman -Qqs '^linux(-zen|-lts|-hardened)?$' | head -1 || true)"

if [[ -z "$KERNEL_NAME" ]]; then
  echo "ERROR: Could not detect installed kernel — install headers manually."
  return 1 2>/dev/null || exit 1
fi

KERNEL_HEADERS="${KERNEL_NAME}-headers"
echo "Kernel: $KERNEL_NAME — will install $KERNEL_HEADERS"

# Select driver package set based on GPU generation
if echo "$NVIDIA" | grep -qE "RTX [2-9][0-9]|GTX 16"; then
  echo "Modern GPU (Turing/Ampere/Ada) — using nvidia-open-dkms"
  sudo pacman -S --needed --noconfirm \
    "$KERNEL_HEADERS" nvidia-open-dkms nvidia-utils lib32-nvidia-utils libva-nvidia-driver

elif echo "$NVIDIA" | grep -qE "GTX 9|GTX 10|Quadro P"; then
  echo "Pascal/Maxwell GPU — using nvidia-580xx-dkms (AUR)"
  paru -S --needed --noconfirm \
    "$KERNEL_HEADERS" nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils

else
  echo "WARNING: GPU generation not recognised."
  echo "         Install drivers manually: https://wiki.archlinux.org/title/NVIDIA"
  return 0 2>/dev/null || exit 0
fi

# Early KMS — needed for proper Wayland startup
echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null

# Add NVIDIA modules to initramfs
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
NVIDIA_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
BACKUP="${MKINITCPIO_CONF}.backup-$(date +%Y%m%d-%H%M%S)"

sudo cp "$MKINITCPIO_CONF" "$BACKUP"

TEMP_CONF="$(mktemp)"
trap "rm -f '$TEMP_CONF'" EXIT

sudo cat "$MKINITCPIO_CONF" \
  | sed -E 's/ nvidia_drm//g; s/ nvidia_uvm//g; s/ nvidia_modeset//g; s/ nvidia//g' \
  | sed -E "s/^(MODULES=\\()/\\1${NVIDIA_MODULES} /" \
  | sed -E 's/  +/ /g' > "$TEMP_CONF"

if ! grep -q "^MODULES=(" "$TEMP_CONF" || ! grep -q "nvidia" "$TEMP_CONF"; then
  echo "ERROR: mkinitcpio patch failed — restoring backup."
  sudo cp "$BACKUP" "$MKINITCPIO_CONF"
  return 1 2>/dev/null || exit 1
fi

sudo cp "$TEMP_CONF" "$MKINITCPIO_CONF"
sudo mkinitcpio -P

# Inject NVIDIA env vars into the UWSM session environment
UWSM_ENV="$XDG_CONFIG_HOME/uwsm/env"
mkdir -p "$(dirname "$UWSM_ENV")"

if ! grep -q "NVD_BACKEND" "$UWSM_ENV" 2>/dev/null; then
  cat >> "$UWSM_ENV" <<'EOF'

# NVIDIA — required for Wayland + hardware video acceleration
export NVD_BACKEND=direct
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
EOF
  echo "NVIDIA env vars written to $UWSM_ENV"
fi

echo "NVIDIA: OK (reboot required)"
