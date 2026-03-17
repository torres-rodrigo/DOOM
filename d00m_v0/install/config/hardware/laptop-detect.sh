# Activate TLP for the current session.
# TLP is already installed and enabled as a service by the packaging phase.
# This starts it immediately so it takes effect without requiring a reboot.

is_laptop() {
  local type_file
  for type_file in /sys/class/power_supply/*/type; do
    [[ -f "$type_file" ]] && [[ "$(cat "$type_file")" == "Battery" ]] && return 0
  done
  return 1
}

if is_laptop; then
  echo "Laptop detected."
  if command -v tlp &>/dev/null; then
    sudo tlp start
    echo "TLP started for current session."
  fi
else
  echo "Desktop detected — TLP not applicable."
fi

echo "Power management: OK"
