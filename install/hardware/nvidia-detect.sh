#!/bin/bash
set -euo pipefail

echo "Checking for NVIDIA GPU..."

# Check for NVIDIA hardware
NVIDIA="$(lspci | grep -i 'nvidia' || true)"

if [[ -z "$NVIDIA" ]]; then
    echo "No NVIDIA GPU detected - skipping NVIDIA driver installation"
    return 0
fi

echo "NVIDIA GPU detected: $NVIDIA"
echo "Installing NVIDIA drivers..."

# Detect kernel and set headers package
KERNEL_NAME="$(pacman -Qqs '^linux(-zen|-lts|-hardened)?$' | head -1 || true)"

if [[ -z "$KERNEL_NAME" ]]; then
    echo "Error: Could not detect installed kernel"
    echo "Please install kernel headers manually"
    return 1
fi

KERNEL_HEADERS="${KERNEL_NAME}-headers"
echo "Detected kernel: $KERNEL_NAME (will install $KERNEL_HEADERS)"

# Determine appropriate driver based on GPU generation
if echo "$NVIDIA" | grep -qE "RTX [2-9][0-9]|GTX 16"; then
    # Turing (16xx, 20xx), Ampere (30xx), Ada (40xx) - use open-source modules
    PACKAGES=(nvidia-open-dkms nvidia-utils lib32-nvidia-utils libva-nvidia-driver)
    echo "Detected modern GPU (Turing/Ampere/Ada) - installing open-source drivers"
elif echo "$NVIDIA" | grep -qE "GTX 9|GTX 10|Quadro P"; then
    # Pascal (10xx) and Maxwell (9xx) - use legacy driver from AUR
    PACKAGES=(nvidia-580xx-dkms nvidia-580xx-utils lib32-nvidia-580xx-utils)
    echo "Detected Pascal/Maxwell GPU - installing legacy drivers from AUR"
else
    echo "GPU generation not recognized - please install drivers manually"
    echo "See: https://wiki.archlinux.org/title/NVIDIA"
    return 0
fi

# Install packages
if [[ "${PACKAGES[0]}" == nvidia-580xx-dkms ]]; then
    # Use paru for AUR packages
    paru -S --noconfirm --needed "$KERNEL_HEADERS" "${PACKAGES[@]}"
else
    # Use pacman for official packages
    sudo pacman -S --noconfirm --needed "$KERNEL_HEADERS" "${PACKAGES[@]}"
fi

# Configure early KMS
echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null

# Configure mkinitcpio for early loading
MKINITCPIO_CONF="/etc/mkinitcpio.conf"
NVIDIA_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"

# Create timestamped backup
BACKUP_FILE="${MKINITCPIO_CONF}.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp "$MKINITCPIO_CONF" "$BACKUP_FILE"

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: Backup creation failed"
    return 1
fi

echo "Created backup: $BACKUP_FILE"

# Create temporary file for safe editing
TEMP_CONF="$(mktemp)"
trap "rm -f \"$TEMP_CONF\"" EXIT

# Process the file: remove old nvidia modules, add new ones
sudo cat "$MKINITCPIO_CONF" | \
    sed -E 's/ nvidia_drm//g; s/ nvidia_uvm//g; s/ nvidia_modeset//g; s/ nvidia//g;' | \
    sed -E "s/^(MODULES=\\()/\\1${NVIDIA_MODULES} /" | \
    sed -E 's/  +/ /g' > "$TEMP_CONF"

# Validate that MODULES line exists
if ! grep -q "^MODULES=(" "$TEMP_CONF"; then
    echo "Error: Modified config is invalid (missing MODULES line)"
    echo "Keeping original configuration"
    return 1
fi

# Validate that nvidia modules were added
if ! grep -q "nvidia" "$TEMP_CONF"; then
    echo "Error: NVIDIA modules were not added correctly"
    return 1
fi

# Apply the changes
sudo cp "$TEMP_CONF" "$MKINITCPIO_CONF"
echo "Successfully updated mkinitcpio configuration"

# Rebuild initramfs
sudo mkinitcpio -P

# Add NVIDIA env vars to Hyprland config
HYPR_ENV="$HOME/.config/hypr/envs.conf"
if [[ -f "$HYPR_ENV" ]] && ! grep -q "NVD_BACKEND" "$HYPR_ENV"; then
    cat >> "$HYPR_ENV" <<'EOF'

# NVIDIA environment variables (auto-configured)
env = NVD_BACKEND,direct
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
EOF
    echo "NVIDIA environment variables added to Hyprland config"
fi

echo "NVIDIA drivers installed successfully"
echo "Reboot required for changes to take effect"
