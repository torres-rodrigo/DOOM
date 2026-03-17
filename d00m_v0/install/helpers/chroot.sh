# Detects whether we are running inside a chroot vs. a live booted system.
#
# In chroot: services are enabled but NOT started (systemctl --now is unsafe
#            because systemd is not running inside a chroot)
# Live boot: services are enabled AND started immediately

is_chroot() {
  [[ -f /proc/1/environ ]] && tr '\0' '\n' < /proc/1/environ | grep -q "container=systemd-nspawn" && return 0
  [[ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null)" ]] && return 0
  return 1
}

# Use this instead of calling systemctl enable directly.
# Automatically adds --now when running on a live system.
systemctl_enable() {
  if is_chroot; then
    sudo systemctl enable "$@"
  else
    sudo systemctl enable --now "$@"
  fi
}

export -f is_chroot
export -f systemctl_enable
