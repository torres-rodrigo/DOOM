#!/bin/bash
set -euo pipefail

echo "Configuring Plymouth boot splash..."

# ============================================
# 1. CONFIGURE MKINITCPIO HOOKS
# ============================================
echo "Configuring mkinitcpio hooks for Plymouth + encryption..."

# Create mkinitcpio config directory if it doesn't exist
sudo mkdir -p /etc/mkinitcpio.conf.d

# Configure hooks with Plymouth BEFORE encrypt (critical for graphical password prompt)
sudo tee /etc/mkinitcpio.conf.d/doom_plymouth.conf >/dev/null <<'EOF'
# DOOM Plymouth + Encryption Hooks
# Hook order matters: plymouth MUST come before encrypt for graphical password prompt

HOOKS=(base udev plymouth autodetect microcode modconf kms keymap consolefont block encrypt filesystems fsck)
EOF

echo "✓ mkinitcpio hooks configured"

# ============================================
# 2. INSTALL PLYMOUTH THEME
# ============================================
echo "Installing DOOM Plymouth theme..."

# Check if Plymouth theme is already set to DOOM
CURRENT_THEME=$(plymouth-set-default-theme 2>/dev/null || echo "none")

if [ "$CURRENT_THEME" != "doom" ]; then
  # Copy DOOM Plymouth theme to system directory
  sudo mkdir -p /usr/share/plymouth/themes/doom
  sudo cp -r "$DOOM_DIR/default/plymouth"/* /usr/share/plymouth/themes/doom/

  # Set DOOM as the default Plymouth theme
  sudo plymouth-set-default-theme doom

  echo "✓ Plymouth theme set to DOOM"
else
  echo "✓ Plymouth theme already set to DOOM"
fi

# ============================================
# 3. REBUILD INITRAMFS
# ============================================
echo "Rebuilding initramfs with Plymouth support..."
sudo mkinitcpio -P

echo "✓ Initramfs rebuilt"

# ============================================
# 4. CONFIGURE BOOTLOADER KERNEL PARAMETERS
# ============================================
echo "Configuring bootloader for Plymouth..."

# Detect which bootloader is in use
BOOTLOADER="unknown"

if [ -f /boot/grub/grub.cfg ] || [ -f /boot/grub2/grub.cfg ]; then
    BOOTLOADER="grub"
elif [ -d /boot/loader/entries ] || [ -f /boot/loader/loader.conf ]; then
    BOOTLOADER="systemd-boot"
elif [ -f /boot/limine.cfg ]; then
    BOOTLOADER="limine"
fi

echo "Detected bootloader: $BOOTLOADER"

case $BOOTLOADER in
    grub)
        echo "Configuring GRUB..."

        # Check if splash is already in GRUB config
        if ! grep -q "GRUB_CMDLINE_LINUX_DEFAULT.*splash" /etc/default/grub; then
            # Backup GRUB config
            sudo cp /etc/default/grub /etc/default/grub.backup-$(date +%Y%m%d-%H%M%S)

            # Add splash to GRUB_CMDLINE_LINUX_DEFAULT (without quiet, to show boot messages)
            sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="splash /' /etc/default/grub

            # Regenerate GRUB config
            sudo grub-mkconfig -o /boot/grub/grub.cfg

            echo "✓ GRUB configured with 'splash' parameter (boot messages will be visible)"
        else
            echo "✓ GRUB already has 'splash' parameter"
        fi
        ;;

    systemd-boot)
        echo "Configuring systemd-boot..."

        # Find all .conf files in loader/entries
        for entry in /boot/loader/entries/*.conf; do
            if [ -f "$entry" ]; then
                # Check if splash is already present
                if ! grep -q "splash" "$entry"; then
                    # Backup entry
                    sudo cp "$entry" "${entry}.backup-$(date +%Y%m%d-%H%M%S)"

                    # Add splash to options line (without quiet)
                    sudo sed -i '/^options/ s/$/ splash/' "$entry"

                    echo "✓ Updated $(basename "$entry")"
                fi
            fi
        done

        echo "✓ systemd-boot configured with 'splash' parameter (boot messages will be visible)"
        ;;

    limine)
        echo "Configuring Limine..."

        # Check if splash is in default config
        if [ -f /etc/default/limine ]; then
            if ! grep -q "splash" /etc/default/limine; then
                # Backup limine config
                sudo cp /etc/default/limine /etc/default/limine.backup-$(date +%Y%m%d-%H%M%S)

                # Add splash to KERNEL_CMDLINE (without quiet)
                sudo sed -i '/KERNEL_CMDLINE\[default\]/ s/"$/ splash"/' /etc/default/limine

                # Rebuild limine config
                if command -v limine-mkinitcpio &>/dev/null; then
                    sudo limine-mkinitcpio
                else
                    echo "Warning: limine-mkinitcpio not found, manual config update may be needed"
                fi

                echo "✓ Limine configured with 'splash' parameter (boot messages will be visible)"
            else
                echo "✓ Limine already has 'splash' parameter"
            fi
        else
            echo "Warning: /etc/default/limine not found"
        fi
        ;;

    *)
        echo "Warning: Could not detect bootloader automatically"
        echo ""
        echo "MANUAL ACTION REQUIRED:"
        echo "Add 'splash' to your kernel boot parameters:"
        echo ""
        echo "For GRUB:"
        echo "  1. Edit /etc/default/grub"
        echo "  2. Add 'splash' to GRUB_CMDLINE_LINUX_DEFAULT"
        echo "  3. Run: sudo grub-mkconfig -o /boot/grub/grub.cfg"
        echo ""
        echo "For systemd-boot:"
        echo "  1. Edit /boot/loader/entries/*.conf"
        echo "  2. Add 'splash' to the 'options' line"
        echo ""
        echo "Optional: Add 'quiet' before 'splash' to hide boot messages"
        echo ""
        ;;
esac

# ============================================
# 5. CONFIGURE SYSTEMD FOR VERBOSE SHUTDOWN
# ============================================
echo "Configuring systemd for verbose shutdown messages..."

# Enable showing shutdown messages
if [ ! -f /etc/systemd/system.conf.d/show-status.conf ]; then
    sudo mkdir -p /etc/systemd/system.conf.d

    sudo tee /etc/systemd/system.conf.d/show-status.conf >/dev/null <<'EOF'
[Manager]
# Show detailed status messages during boot and shutdown
ShowStatus=yes
EOF

    echo "✓ Systemd configured for verbose shutdown"
else
    echo "✓ Systemd already configured for verbose shutdown"
fi

# ============================================
# 6. FINAL SUMMARY
# ============================================
echo ""
echo "============================================="
echo "    Plymouth Configuration Complete!"
echo "============================================="
echo ""
echo "✓ mkinitcpio hooks configured (plymouth before encrypt)"
echo "✓ DOOM theme installed and set as default"
echo "✓ DOOM theme configured to show boot/shutdown messages"
echo "✓ Initramfs rebuilt with Plymouth support"
echo "✓ Bootloader configured with 'splash' parameter"
echo "✓ Systemd configured for verbose shutdown"
echo ""
echo "What to expect on next boot:"
echo "1. Boot messages scrolling with [OK] indicators (visible!)"
echo "2. DOOM splash screen appears ONLY for password prompt"
echo "3. Graphical password prompt for LUKS encryption with DOOM logo"
echo "4. More boot messages after password (visible!)"
echo "5. Boot into Hyprland"
echo ""
echo "What to expect on shutdown:"
echo "1. Shutdown messages scrolling with [OK] indicators (visible!)"
echo "2. Clean shutdown without Plymouth covering messages"
echo ""
echo "Tip: Run 'doom-toggle-boot-messages' to hide boot messages completely"
echo "     if you prefer Plymouth to cover everything"
echo ""
echo "NOTE: Reboot required for changes to take effect"
echo "============================================="
echo ""
