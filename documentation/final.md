ask if there are any easy configurations that cachy linux uses that are overall better than arch linux defaults
AUR improvements
Pacman verification that valid users set up the packages
loader.conf timeout 0, console-mode max editor no

systemctl enable systemd-boot-update.service 2>/dev/null || true
Enables a systemd service that automatically copies the latest systemd-boot EFI binary to the ESP whenever the `systemd` package is upgraded. Without this, a `pacman -Syu` that updates systemd updates the binary at `/usr/lib/systemd/boot/efi/systemd-bootx64.efi` but leaves the older copy on the ESP untouched — the firmware keeps booting the old version until someone manually runs `bootctl update`.

- `2>/dev/null` — suppresses output if the service isn't found.
- `|| true` — prevents `set -e` from aborting if the service doesn't exist on older systemd versions. Silently skips.
