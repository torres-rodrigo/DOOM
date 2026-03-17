# Install laptop-specific packages.
# Skipped entirely on desktops — detection is battery-based.

is_laptop() {
  local type_file
  for type_file in /sys/class/power_supply/*/type; do
    [[ -f "$type_file" ]] && [[ "$(cat "$type_file")" == "Battery" ]] && return 0
  done
  return 1
}

if ! is_laptop; then
  echo "No battery detected — skipping laptop packages."
  return 0 2>/dev/null || exit 0
fi

echo "Battery detected — installing laptop packages..."

laptop_packages=(
  acpi              # Battery and thermal info CLI
  brightnessctl     # Display backlight brightness control
  fprintd           # Fingerprint authentication daemon
  tlp               # Battery longevity optimization daemon
  tlp-rdw           # Radio device wizard for TLP (auto-toggles wifi/bt on power events)
)

sudo pacman -S --needed --noconfirm "${laptop_packages[@]}"

systemctl_enable tlp.service

echo "Laptop packages: OK"
