# Laptop-specific configuration: power management, battery monitor, lid behaviour.
# All changes are gated on battery detection — skipped entirely on desktops.

is_laptop() {
  local type_file
  for type_file in /sys/class/power_supply/*/type; do
    [[ -f "$type_file" ]] && [[ "$(cat "$type_file")" == "Battery" ]] && return 0
  done
  return 1
}

if ! is_laptop; then
  echo "Desktop detected — laptop configuration not applicable."
  echo "Power management: OK"
  return 0 2>/dev/null || exit 0
fi

echo "Laptop detected."

# ── TLP ───────────────────────────────────────────────────────────────────────
if command -v tlp &>/dev/null; then
  sudo tlp start
  echo "TLP started for current session."
fi

# ── Battery monitor ───────────────────────────────────────────────────────────
systemctl --user enable doom-battery-monitor.timer
echo "Battery monitor: enabled."

# ── Lid switch: screen off only, no suspend ───────────────────────────────────
# Tell logind to do nothing on lid close — we handle it ourselves via acpid.
sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/lid.conf > /dev/null <<'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
EOF
echo "logind lid policy: set to ignore."

# Deploy the acpid event rule.
sudo mkdir -p /etc/acpi/events
sudo tee /etc/acpi/events/lid-switch > /dev/null <<'EOF'
event=button/lid.*
action=/etc/acpi/actions/lid-switch.sh %e
EOF

# Deploy the acpid action script.
# Finds the active Wayland session, then uses wlr-randr to toggle the internal
# display (eDP — the connector type used by all embedded laptop panels).
sudo mkdir -p /etc/acpi/actions
sudo tee /etc/acpi/actions/lid-switch.sh > /dev/null <<'EOF'
#!/bin/bash
lid_state="${3}"  # "close" or "open" (from the ACPI event string passed via %e)

# Find the user running an active Wayland session.
wayland_user=""
while IFS=' ' read -r session_id uid user _rest; do
  type=$(loginctl show-session "$session_id" -p Type --value 2>/dev/null)
  if [[ "$type" == "wayland" ]]; then
    wayland_user="$user"
    break
  fi
done < <(loginctl list-sessions --no-legend)

[[ -z "$wayland_user" ]] && exit 0

uid_num=$(id -u "$wayland_user")
runtime_dir="/run/user/$uid_num"

# Resolve the active Wayland socket (wayland-0, wayland-1, etc.).
wayland_display=$(ls "$runtime_dir"/wayland-[0-9] 2>/dev/null | head -1 | xargs -r basename)
[[ -z "$wayland_display" ]] && exit 0

run_as_user() {
  sudo -u "$wayland_user" \
    WAYLAND_DISPLAY="$wayland_display" \
    XDG_RUNTIME_DIR="$runtime_dir" \
    "$@"
}

# Target the internal display — eDP (embedded DisplayPort) is used by all
# modern laptop panels. External monitors use HDMI, DP, etc. and are unaffected.
internal_output=$(run_as_user wlr-randr 2>/dev/null | grep -m1 "^eDP" | awk '{print $1}')
[[ -z "$internal_output" ]] && exit 0

case "$lid_state" in
  close) run_as_user wlr-randr --output "$internal_output" --off ;;
  open)  run_as_user wlr-randr --output "$internal_output" --on  ;;
esac
EOF
sudo chmod +x /etc/acpi/actions/lid-switch.sh
echo "Lid switch handler: deployed."

echo "Power management: OK"
