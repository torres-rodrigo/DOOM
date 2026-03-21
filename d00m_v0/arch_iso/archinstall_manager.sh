#!/bin/bash
# =============================================================================
# doom_v0 — archinstall_manager.sh
# =============================================================================
# Run this from the Arch Linux live ISO before anything else.
#
# What it does:
#   1. Asks for username, hostname, and password
#   2. Detects available disks and asks which one to install on
#   3. Generates archinstall config files from those inputs
#   4. Runs archinstall (fully automated)
#   5. Copies the doom_v0 directory to ~/doom_v0 in the new system, ready for reboot
#
# Usage:
#   curl -O https://raw.githubusercontent.com/your/doom_v0/main/arch_iso/archinstall_manager.sh
#   bash archinstall_manager.sh
#
# Or if you cloned the repo already:
#   bash /path/to/doom_v0/arch_iso/archinstall_manager.sh
# =============================================================================

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOOM_REPO="https://github.com/your/doom_v0.git"

ARCHINSTALL_CONFIG_TEMPLATE="$SCRIPT_DIR/config.json"
ARCHINSTALL_CONFIG="/tmp/doom-archinstall-config.json"
ARCHINSTALL_CREDS="/tmp/doom-archinstall-creds.json"

# ── Colors ────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
  clear
  printf "${CYAN}${BOLD}"
  cat << 'EOF'
=================     ===============     ===============   ========  ========
\ . . . . . . .\   //. . . . . . .\   //. . . . . . .\  \. . .\// . . //
||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\/ . . .||
|| . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||
||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||
|| . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\. . . . ||
||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\_ . .|. .||
|| . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\ `-_/| . ||
||_-' ||  .|/    || ||    \|.  || `-_|| ||_-' ||  .|/    || ||   | \  / |-_.||
||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \  / |  `||
||    `'         || ||         `'    || ||    `'         || ||   | \  / |   ||
||            .===' `===.         .==='.`===.         .===' /==. |  \/  |   ||
||         .=='   \_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \/  |   ||
||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \/  |   ||
||   .=='    _-'          `-__\._-'         `-_./__-'         `' |. /|  |   ||
||.=='    _-'                                                     `' |  /==.||
=='    _-'                                                            \/   `==
\   _-'                                                                `-_   /
`''                                                                      ```
EOF
  printf "${RESET}\n"
  echo -e "  ${BOLD}Arch Linux installer${RESET}"
  echo -e "  ${YELLOW}This will wipe the selected disk and install doom_v0.${RESET}"
  echo ""
}

ask() {
  # ask <prompt> <variable_name> [default]
  # Uses a bash nameref (local -n) to write the result directly into
  # the caller's variable without a subshell.
  local prompt="$1"
  local -n _result=$2
  local default="${3:-}"

  if [[ -n "$default" ]]; then
    echo -ne "  ${BOLD}${prompt}${RESET} [${default}]: "
  else
    echo -ne "  ${BOLD}${prompt}${RESET}: "
  fi

  read -r _result
  if [[ -z "$_result" && -n "$default" ]]; then
    _result="$default"
  fi
}

ask_password() {
  # ask_password <variable_name>
  # Loops until the user enters the same password twice.
  # read -rs hides the input and suppresses the newline.
  local -n _pw=$1
  while true; do
    echo -ne "  ${BOLD}Password${RESET}: "
    read -rs _pw; echo

    echo -ne "  ${BOLD}Confirm password${RESET}: "
    read -rs confirm; echo

    if [[ "$_pw" == "$confirm" ]]; then
      break
    fi
    echo -e "  ${RED}Passwords do not match. Try again.${RESET}"
  done
}

# ── Prerequisites ─────────────────────────────────────────────────────────────
[[ -f /etc/arch-release ]] || { echo "Error: Not running on Arch Linux."; exit 1; }
command -v archinstall &>/dev/null || { echo "Error: archinstall not found. Boot from the official Arch ISO."; exit 1; }
command -v openssl    &>/dev/null || { echo "Error: openssl not found."; exit 1; }

# Ensure config.json is present next to this script
if [[ ! -f "$ARCHINSTALL_CONFIG_TEMPLATE" ]]; then
  echo "config.json not found at: $ARCHINSTALL_CONFIG_TEMPLATE"
  echo "Cloning doom_v0 repo to get it..."
  git clone "$DOOM_REPO" /tmp/doom-repo
  ARCHINSTALL_CONFIG_TEMPLATE="/tmp/doom-repo/arch_iso/config.json"
fi

# ── Step 1 — System identity ──────────────────────────────────────────────────
print_header

echo -e "  ${CYAN}Step 1 of 3 — System identity${RESET}"
echo ""

ask "Username" username
ask "Hostname" hostname

# ── Step 2 — Password ─────────────────────────────────────────────────────────
echo ""
echo -e "  ${CYAN}Step 2 of 3 — Password${RESET}"
echo -e "  ${YELLOW}Used for: your user account, root account, and LUKS disk encryption.${RESET}"
echo ""

ask_password password

# ── Timezone ──────────────────────────────────────────────────────────────────
# Read the live ISO's current timezone as the default.
# The Arch ISO boots as UTC — type your own if needed (e.g. America/Montevideo).
detected_tz=$(timedatectl show -p Timezone --value 2>/dev/null || echo "UTC")
while true; do
  echo -e "  ${YELLOW}Hint: type --list to browse all available timezones${RESET}"
  ask "Timezone" timezone "$detected_tz"
  [[ "$timezone" != "--list" ]] && break
  timedatectl list-timezones | more
done

# ── Step 3 — Disk selection ───────────────────────────────────────────────────
echo ""
echo -e "  ${CYAN}Step 3 of 3 — Disk${RESET}"
echo -e "  ${RED}${BOLD}WARNING: The selected disk will be completely wiped.${RESET}"
echo ""
echo "  Available disks:"
echo ""

# lsblk -d lists physical disks only (no partitions).
# grep removes loop devices and optical drives (sr*).
mapfile -t disks < <(lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -vE "^loop|^sr")

i=1
for disk_line in "${disks[@]}"; do
  printf "    ${BOLD}%d)${RESET} /dev/%s\n" "$i" "$disk_line"
  ((i++))
done

echo ""
echo -ne "  ${BOLD}Select disk number${RESET}: "
read -r disk_choice

if [[ "$disk_choice" =~ ^[0-9]+$ ]] && (( disk_choice >= 1 && disk_choice < i )); then
  # Pull just the device name (first column) from the chosen line
  selected_disk_name=$(echo "${disks[$((disk_choice-1))]}" | awk '{print $1}')
  disk="/dev/$selected_disk_name"
else
  # Allow typing the path directly (e.g. /dev/nvme0n1)
  disk="$disk_choice"
fi

# Verify the path is an actual block device before continuing
[[ -b "$disk" ]] || { echo -e "  ${RED}Error: '$disk' is not a valid block device.${RESET}"; exit 1; }

# Calculate root partition size in GiB.
# Boot occupies [1 MiB, 1025 MiB], so root starts at 1025 MiB.
# archinstall 3.x dropped the "Percent" unit — sizes must be absolute.
disk_size_bytes=$(lsblk -b -d -o SIZE --noheadings "$disk" | tr -d '[:space:]')
root_size_gib=$(( (disk_size_bytes - 1025 * 1024 * 1024) / 1024 / 1024 / 1024 ))

# ── Confirmation ──────────────────────────────────────────────────────────────
echo ""
echo -e "  ${YELLOW}${BOLD}About to install with:${RESET}"
echo -e "    Username  : ${BOLD}${username}${RESET}"
echo -e "    Hostname  : ${BOLD}${hostname}${RESET}"
echo -e "    Disk      : ${BOLD}${disk}${RESET}  ${RED}(will be wiped)${RESET}"
echo -e "    Timezone  : ${BOLD}${timezone}${RESET}"
echo ""
echo -ne "  ${BOLD}Continue? [y/N]${RESET}: "
read -r confirm
[[ "${confirm,,}" == "y" ]] || { echo "Aborted."; exit 0; }

# ── Password hashing ──────────────────────────────────────────────────────────
# openssl passwd -6 produces a SHA-512 shadow hash ($6$salt$hash).
# archinstall passes these directly to chpasswd inside the new system.
# Two separate hashes are generated (same password, different random salts).
echo ""
echo -e "  ${GREEN}Generating password hashes...${RESET}"

user_hash=$(openssl passwd -6 "$password")
root_hash=$(openssl passwd -6 "$password")

# ── Generate credentials JSON ─────────────────────────────────────────────────
# This file is written to /tmp and never stored on disk permanently.
#
# encryption_password  — plaintext. archinstall needs it to run cryptsetup
#                        and format the LUKS container during partitioning.
# root_enc_password    — SHA-512 hash. Passed to chpasswd for the root account.
# enc_password         — SHA-512 hash. Passed to useradd for the user account.
# sudo: true           — adds the user to the wheel group.
cat > "$ARCHINSTALL_CREDS" << EOF
{
    "encryption_password": "${password}",
    "root_enc_password": "${root_hash}",
    "users": [
        {
            "enc_password": "${user_hash}",
            "groups": [],
            "sudo": true,
            "username": "${username}"
        }
    ]
}
EOF

# ── Patch config template ─────────────────────────────────────────────────────
# config.json stores static configuration. The three values that change
# per-machine are injected here via sed placeholders.
cp "$ARCHINSTALL_CONFIG_TEMPLATE" "$ARCHINSTALL_CONFIG"

sed -i "s|__DEVICE__|${disk}|g"           "$ARCHINSTALL_CONFIG"
sed -i "s|__HOSTNAME__|${hostname}|g"      "$ARCHINSTALL_CONFIG"
sed -i "s|__TIMEZONE__|${timezone}|g"      "$ARCHINSTALL_CONFIG"
sed -i "s|__ROOT_SIZE__|${root_size_gib}|g" "$ARCHINSTALL_CONFIG"

echo -e "  ${GREEN}Config files ready.${RESET}"
echo ""

# ── Run archinstall ───────────────────────────────────────────────────────────
# --config  provides all system configuration (disk layout, packages, etc.)
# --creds   provides credentials (passwords and user accounts)
# With both flags set, archinstall runs fully non-interactively.
echo -e "  ${CYAN}${BOLD}Starting archinstall...${RESET}"
echo ""

archinstall \
  --config "$ARCHINSTALL_CONFIG" \
  --creds  "$ARCHINSTALL_CREDS"

# ── Post-archinstall: copy repo and prepare for reboot ───────────────────────
# archinstall leaves the new system mounted at /mnt.
# The repo is already on disk (we ran from it), so copy it directly
# rather than re-cloning. No network or credentials needed.
echo ""
echo -e "  ${CYAN}${BOLD}archinstall complete. Preparing for reboot...${RESET}"
echo ""

DOOM_CHROOT_PATH="/mnt/home/${username}/d00m_v0"

cp -r "$(realpath "$SCRIPT_DIR/..")" "$DOOM_CHROOT_PATH"

# Fix ownership — the live ISO runs as root, so any files written to the
# mounted system are root-owned. Chown the entire home directory so that
# ~/.local and any other directories created during the copy are user-owned.
arch-chroot /mnt chown -R "${username}:${username}" "/home/${username}"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${GREEN}${BOLD}Base system installed.${RESET}"
echo ""
echo -e "  doom_v0 is ready at: ${BOLD}~/d00m_v0${RESET}"
echo ""
echo -e "  Next steps:"
echo -e "    1. Remove the installation media"
echo -e "    2. ${BOLD}reboot${RESET}"
echo -e "    3. Log in as ${BOLD}${username}${RESET}"
echo -e "    4. Run: ${BOLD}bash ~/d00m_v0/doom_install.sh${RESET}"
echo ""
