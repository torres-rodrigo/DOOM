# Configure Plymouth boot splash.
# Hook order: plymouth MUST come before encrypt so the LUKS prompt is graphical.

echo "Configuring Plymouth boot splash..."

# ── 1. mkinitcpio hooks ───────────────────────────────────────────────────────
sudo mkdir -p /etc/mkinitcpio.conf.d

sudo tee /etc/mkinitcpio.conf.d/doom_plymouth.conf >/dev/null <<'EOF'
# Hook order matters: plymouth MUST come before encrypt for the graphical password prompt
HOOKS=(base udev plymouth autodetect microcode modconf kms keymap consolefont block encrypt filesystems fsck)
EOF

echo "mkinitcpio hooks: OK"

# ── 2. Plymouth theme ─────────────────────────────────────────────────────────
CURRENT_THEME=$(plymouth-set-default-theme 2>/dev/null || echo "none")

if [ "$CURRENT_THEME" != "doom" ]; then
  sudo mkdir -p /usr/share/plymouth/themes/doom
  sudo cp -r "$DOOM_INSTALL/login/assets"/* /usr/share/plymouth/themes/doom/
  sudo plymouth-set-default-theme doom
  echo "Plymouth theme: doom"
else
  echo "Plymouth theme already set to doom"
fi

# ── 3. Rebuild initramfs ──────────────────────────────────────────────────────
echo "Rebuilding initramfs..."
sudo mkinitcpio -P
echo "Initramfs: OK"

# ── 4. Bootloader kernel parameters ──────────────────────────────────────────
# Detect which bootloader is active
BOOTLOADER="unknown"

if [ -f /boot/grub/grub.cfg ] || [ -f /boot/grub2/grub.cfg ]; then
  BOOTLOADER="grub"
elif [ -d /boot/loader/entries ] || [ -f /boot/loader/loader.conf ]; then
  BOOTLOADER="systemd-boot"
fi

echo "Bootloader detected: $BOOTLOADER"

case $BOOTLOADER in
  grub)
    if ! grep -q "GRUB_CMDLINE_LINUX_DEFAULT.*splash" /etc/default/grub; then
      sudo cp /etc/default/grub /etc/default/grub.backup-$(date +%Y%m%d-%H%M%S)
      sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="splash /' /etc/default/grub
      sudo grub-mkconfig -o /boot/grub/grub.cfg
      echo "GRUB: splash added"
    else
      echo "GRUB: splash already present"
    fi
    ;;

  systemd-boot)
    for entry in /boot/loader/entries/*.conf; do
      if [ -f "$entry" ] && ! grep -q "splash" "$entry"; then
        sudo cp "$entry" "${entry}.backup-$(date +%Y%m%d-%H%M%S)"
        sudo sed -i '/^options/ s/$/ splash/' "$entry"
        echo "Updated: $(basename "$entry")"
      fi
    done
    echo "systemd-boot: splash added"
    ;;

  *)
    echo "WARNING: Could not detect bootloader — add 'splash' to kernel parameters manually"
    ;;
esac

# ── 5. Systemd verbose shutdown ───────────────────────────────────────────────
if [ ! -f /etc/systemd/system.conf.d/show-status.conf ]; then
  sudo mkdir -p /etc/systemd/system.conf.d
  sudo tee /etc/systemd/system.conf.d/show-status.conf >/dev/null <<'EOF'
[Manager]
ShowStatus=yes
EOF
  echo "Systemd: verbose shutdown enabled"
fi

echo "Plymouth: OK"
