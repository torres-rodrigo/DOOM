abort() {
  echo -e "\e[31mDOOM install requires: $1\e[0m"
  echo
  exit 1
}

# Must be an Arch distro
if [[ ! -f /etc/arch-release ]]; then
  abort "Vanilla Arch"
fi

# Must not be an Arch derivative distro
for marker in /etc/cachyos-release /etc/eos-release /etc/garuda-release /etc/manjaro-release; do
  if [[ -f "$marker" ]]; then
    abort "Vanilla Arch"
  fi
done

# Must not be running as root
if [ "$EUID" -eq 0 ]; then
  abort "Not running as root (run as user)"
fi

# Must be x86 only to fully work
if [ "$(uname -m)" != "x86_64" ]; then
  abort "x86_64 CPU"
fi

# Must have btrfs root filesystem
[ "$(findmnt -n -o FSTYPE /)" = "btrfs" ] || abort "Btrfs root filesystem" 

echo "Preflight checks: OK"
