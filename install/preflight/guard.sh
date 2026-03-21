# Guard checks — abort or warn if system preconditions are not met.
# Each check is a soft abort: the user can override and proceed at their own risk.

abort() {
  echo -e "\e[31mdoom_v0 requires: $1\e[0m"
  echo
  if command -v gum &>/dev/null; then
    gum confirm "Proceed anyway at your own risk?" || exit 1
  else
    read -rp "Proceed anyway? [y/N] " ans
    [[ "${ans,,}" == "y" ]] || exit 1
  fi
}

# Must be vanilla Arch Linux
[[ -f /etc/arch-release ]] || abort "Vanilla Arch Linux"

# Reject known derivatives
for marker in /etc/cachyos-release /etc/eos-release /etc/garuda-release /etc/manjaro-release; do
  [[ -f $marker ]] && abort "Vanilla Arch (no derivatives)"
done

# Must not run as root
(( EUID == 0 )) && abort "Non-root user (run as your regular user)"

# Must be x86_64
[[ $(uname -m) == "x86_64" ]] || abort "x86_64 CPU"

# Secure Boot must be disabled
if bootctl status 2>/dev/null | grep -q 'Secure Boot: enabled'; then
  abort "Secure Boot disabled"
fi

# No competing desktop environments
if pacman -Qe gnome-shell &>/dev/null || pacman -Qe plasma-desktop &>/dev/null; then
  abort "Fresh Arch without GNOME/KDE already installed"
fi

# Must have btrfs root
[[ $(findmnt -n -o FSTYPE /) == "btrfs" ]] || abort "Btrfs root filesystem"

# Disk space check (warn if < 15 GB free)
free_gb=$(df -BG / | awk 'NR==2 {gsub("G",""); print $4}')
if (( free_gb < 15 )); then
  abort "At least 15 GB free disk space (have ${free_gb}GB)"
fi

echo "Guards: OK"
