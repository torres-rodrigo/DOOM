# doom_v0 — Documentation

This file tracks every component of the doom_v0 system: what each file does, how it is configured, and why each decision was made. Updated as new sections are added.

---

## Table of Contents

1. [Arch_ISO](#arch_iso)
   - [archinstall_manager.sh](#archinstall_managersh)
   - [config.json](#configjson)
2. [Install_Skeleton](#install_skeleton)
   - [doom_install.sh](#doom_installsh)
   - [helpers/000_doom.sh](#helpers000_doomsh)
   - [helpers/chroot.sh](#helperschrootsh)
   - [helpers/presentation.sh](#helpersPresentationsh)
   - [helpers/errors.sh](#helperserrorssh)
   - [helpers/logging.sh](#helperloggingsh)
3. [Preflight](#preflight)
   - [preflight/001_doom.sh](#preflight001_doomsh)
   - [preflight/guard.sh](#preflightguardsh)
   - [preflight/pacman.sh](#preflightpacmansh)
   - [preflight/markers.sh](#preflightmarkerssh)
4. [Packaging](#packaging)
   - [packaging/002_doom.sh](#packaging002_doomsh)
   - [packaging/base.sh](#packagingbasesh)
   - [packaging/packages.list](#packagingpackageslist)
   - [packaging/aur.sh](#packagingaursh)
   - [packaging/optional.sh](#packagingoptionalsh)

---

## Arch_ISO

Everything under `arch_iso/` is designed to run from the **Arch Linux live ISO**, before any system exists on disk. Its job is to drive `archinstall` non-interactively and then hand off to the doom_v0 installer inside the new system's chroot.

**Files:**
```
arch_iso/
├── archinstall_manager.sh   ← the script you run from the live ISO
└── config.json              ← static archinstall configuration template
```

The credentials file (`creds.json`) is **not stored here** — it is generated at runtime by `archinstall_manager.sh` and written to `/tmp` so passwords never touch the repository.

---

### archinstall_manager.sh

**Location:** `arch_iso/archinstall_manager.sh`
**Runs on:** Arch Linux live ISO (before install)
**Run with:** `bash arch_iso/archinstall_manager.sh`

The main entry point for installation. Collects three pieces of information from the user, builds the two JSON files that archinstall needs, runs archinstall non-interactively, then immediately chains into the doom_v0 installer inside the new system.

---

#### `set -euo pipefail`

```bash
set -euo pipefail
```

Safety flags that apply to the entire script:

- `-e` — exit immediately if any command returns a non-zero exit code
- `-u` — treat any reference to an unset variable as an error (prevents silent bugs from typos)
- `-o pipefail` — if any command in a pipe fails, the whole pipe fails (not just the last command)

Together these make the script fail loudly and early rather than silently continuing in a broken state.

---

#### Paths

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOOM_REPO="https://github.com/your/doom_v0.git"

ARCHINSTALL_CONFIG_TEMPLATE="$SCRIPT_DIR/config.json"
ARCHINSTALL_CONFIG="/tmp/doom-archinstall-config.json"
ARCHINSTALL_CREDS="/tmp/doom-archinstall-creds.json"
```

- **`SCRIPT_DIR`** — resolves the absolute path of the directory this script lives in, regardless of where you call it from. This is how the script finds `config.json` sitting next to it.
- **`DOOM_REPO`** — the GitHub URL of this project. Used in two places: as a fallback to clone `config.json` if the script is run standalone, and to clone the full project into the new system after archinstall.
- **`ARCHINSTALL_CONFIG_TEMPLATE`** — the static `config.json` that lives in the repo. It has placeholders (`__DEVICE__`, `__HOSTNAME__`, `__TIMEZONE__`) that get filled in at runtime.
- **`ARCHINSTALL_CONFIG`** — the working copy of the config written to `/tmp`. This is what archinstall actually reads.
- **`ARCHINSTALL_CREDS`** — the credentials file written to `/tmp`. Contains plaintext LUKS password and password hashes. Kept in `/tmp` so it never gets committed to the repo.

---

#### Colors

```bash
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'
```

ANSI escape codes stored as variables. Used throughout the script with `echo -e` to color the terminal output. `RESET` is always added at the end of a colored string to stop the color from bleeding into the next line.

---

#### `print_header()`

```bash
print_header() {
  clear
  printf "${CYAN}${BOLD}"
  cat << 'EOF'
=================     ===============  ...
`''                                      ```
EOF
  printf "${RESET}\n"
  echo -e "  ${BOLD}Arch Linux installer${RESET}"
  echo -e "  ${YELLOW}This will wipe the selected disk and install doom_v0.${RESET}"
}
```

Clears the terminal and prints the DOOM ASCII logo in cyan/bold. Called once at the start of the user-facing prompts. The wipe warning is shown here in yellow so the user sees it before entering anything.

The ASCII art is rendered using a **quoted heredoc** (`cat << 'EOF'`). The single-quoted delimiter prevents all shell interpretation — backticks, backslashes, and dollar signs inside the heredoc are treated as literal characters. This avoids the command substitution issue that would occur if the art were embedded in double-quoted `echo -e` strings.

---

#### `ask()`

```bash
ask() {
  local prompt="$1"
  local -n _result=$2
  local default="${3:-}"
  ...
  read -r _result
}
```

A reusable prompt function that takes three arguments: the prompt text, the name of the variable to write the answer into, and an optional default value.

The key mechanism is `local -n _result=$2` — this is a **bash nameref**. Instead of storing the value in `_result` locally, it makes `_result` a reference to whichever variable name was passed as `$2`. So when `read -r _result` runs, it writes directly into the caller's variable. For example, `ask "Username" username` causes `read` to populate the `username` variable in the outer script.

If the user presses Enter without typing anything and a default was provided, the default is assigned instead.

---

#### `ask_password()`

```bash
ask_password() {
  local -n _pw=$1
  while true; do
    read -rs _pw; echo
    read -rs confirm; echo
    if [[ "$_pw" == "$confirm" ]]; then break; fi
    echo -e "  ${RED}Passwords do not match. Try again.${RESET}"
  done
}
```

Same nameref mechanism as `ask()`, but specialized for passwords. `read -rs` does two things: `-r` disables backslash interpretation, `-s` puts the terminal in silent mode so characters are not echoed. The trailing `; echo` adds the newline that silent mode suppresses.

The function loops until the user types the same password twice. There is no character limit or complexity requirement — that is intentional, the user is responsible for choosing a strong password.

---

#### Prerequisites check

```bash
[[ -f /etc/arch-release ]] || { echo "Error: Not running on Arch Linux."; exit 1; }
command -v archinstall &>/dev/null || { echo "Error: archinstall not found."; exit 1; }
command -v openssl    &>/dev/null || { echo "Error: openssl not found."; exit 1; }
```

Three hard checks before any user interaction happens:

1. **`/etc/arch-release`** — this file only exists on Arch Linux. If it is missing, the script exits immediately. This prevents accidentally running the installer on the wrong system.
2. **`archinstall`** — the official Arch installer tool, present on the Arch live ISO. If missing, the user is not on the right ISO.
3. **`openssl`** — used later to hash passwords. Present on all Arch systems.

The `|| { ...; exit 1; }` pattern is a short-circuit: if the left side fails, the right side runs and exits.

---

#### Config template fallback

```bash
if [[ ! -f "$ARCHINSTALL_CONFIG_TEMPLATE" ]]; then
  git clone "$DOOM_REPO" /tmp/doom-repo
  ARCHINSTALL_CONFIG_TEMPLATE="/tmp/doom-repo/arch_iso/config.json"
fi
```

If the script is downloaded and run standalone (without the rest of the repo next to it), `config.json` won't be found at `$SCRIPT_DIR/config.json`. In that case, the script clones the full repo into `/tmp` just to get the config file, then points the template variable at that copy. This makes the script work whether you have the full repo or just the script file.

---

#### Step 1 — Username and hostname

```bash
ask "Username" username
ask "Hostname" hostname
```

Collects two strings with no validation beyond requiring they are non-empty (pressing Enter on a blank input with no default loops). The username becomes the login name for the user account created by archinstall. The hostname is the name the machine announces on the network and shows in the shell prompt.

---

#### Step 2 — Password

```bash
ask_password password
```

One password is collected and confirmed. That single value is used for three separate things:
- The **LUKS encryption password** (stored plaintext in the credentials JSON temporarily — archinstall needs it to format the encrypted partition)
- The **user account password** (hashed with SHA-512, passed to `useradd`)
- The **root account password** (hashed with SHA-512, passed to `chpasswd`)

Using one password for all three simplifies the install. It can be changed individually after the system is running.

---

#### Timezone

```bash
detected_tz=$(timedatectl show -p Timezone --value 2>/dev/null || echo "UTC")
ask "Timezone" timezone "$detected_tz"
```

`timedatectl show -p Timezone --value` reads the current timezone from the live ISO's systemd-timesyncd. The Arch ISO boots with UTC by default, so `detected_tz` will almost always be `UTC` unless you set it manually before running the script.

The detected value is shown as the default in brackets. Pressing Enter accepts it. Typing `America/Montevideo` (or any valid tz database name) overrides it. The value ends up as the `"timezone"` field in `config.json` and becomes the system timezone of the installed system.

---

#### Step 3 — Disk selection

```bash
mapfile -t disks < <(lsblk -d -o NAME,SIZE,MODEL --noheadings | grep -vE "^loop|^sr")
```

`lsblk -d` lists only physical disk devices (no partitions, no dm devices). `-o NAME,SIZE,MODEL` shows device name, total size, and hardware model string. `grep -vE "^loop|^sr"` removes loop devices (used by the live ISO's squashfs) and optical drives.

`mapfile -t disks` reads each line into the `disks` array. The script then prints them numbered and lets the user pick by number. If the user types a full path like `/dev/nvme0n1` instead, that is accepted directly.

After selection, `[[ -b "$disk" ]]` verifies the chosen path is an actual block device before continuing.

---

#### Confirmation

```bash
echo -e "    Disk : ${BOLD}${disk}${RESET}  ${RED}(will be wiped)${RESET}"
echo -ne "  ${BOLD}Continue? [y/N]${RESET}: "
read -r confirm
[[ "${confirm,,}" == "y" ]] || { echo "Aborted."; exit 0; }
```

Prints a summary of all collected values so the user can verify before anything destructive happens. The default is **N** (abort) — the user must explicitly type `y` to proceed. `${confirm,,}` lowercases the input so `Y` and `y` both work.

---

#### Password hashing

```bash
user_hash=$(openssl passwd -6 "$password")
root_hash=$(openssl passwd -6 "$password")
```

`openssl passwd -6` generates a SHA-512 shadow hash in the format `$6$salt$hash`. The `-6` flag selects SHA-512 (as opposed to `-5` for SHA-256 or `-1` for MD5). Each call generates a fresh random salt, so `user_hash` and `root_hash` are different strings even though both hash the same password.

SHA-512 (`$6$`) is a format that all Linux shadow password tools understand. archinstall passes these hashes directly to `chpasswd --encrypted` and `useradd -p` inside the new system — it never sees the plaintext password for the user/root accounts.

---

#### Credentials JSON generation

```bash
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
```

A bash heredoc (`<< EOF`) writes a JSON file to `/tmp/doom-archinstall-creds.json`. The variables embedded inside the heredoc are expanded at write time.

Three distinct password fields:

| Field | Format | Why |
|---|---|---|
| `encryption_password` | Plaintext | archinstall must pass this to `cryptsetup luksFormat` to encrypt the partition |
| `root_enc_password` | SHA-512 hash | archinstall passes to `chpasswd --encrypted` to set the root password |
| `enc_password` | SHA-512 hash | archinstall passes to `useradd -p` to set the user's password |

`sudo: true` adds the user to the `wheel` group, which the sudoers configuration grants full sudo access. `groups: []` means no additional groups beyond the default ones archinstall assigns.

This file is written to `/tmp` and is never committed to the repository. It exists only for the duration of the archinstall run.

---

#### Config template patching

```bash
cp "$ARCHINSTALL_CONFIG_TEMPLATE" "$ARCHINSTALL_CONFIG"

sed -i "s|__DEVICE__|${disk}|g"      "$ARCHINSTALL_CONFIG"
sed -i "s|__HOSTNAME__|${hostname}|g" "$ARCHINSTALL_CONFIG"
sed -i "s|__TIMEZONE__|${timezone}|g" "$ARCHINSTALL_CONFIG"
```

`config.json` is a static file with three placeholders that cannot be known ahead of time (they depend on the machine and the user's choices). The script copies the template to `/tmp` and uses `sed -i` (in-place replace) to substitute each placeholder.

The `|` delimiter in `s|old|new|g` is used instead of the traditional `/` because device paths like `/dev/sda` contain forward slashes, which would break a `/`-delimited sed expression.

---

#### Running archinstall

```bash
archinstall \
  --config "$ARCHINSTALL_CONFIG" \
  --creds  "$ARCHINSTALL_CREDS"
```

With both flags provided, archinstall runs completely non-interactively. It reads all configuration from `config.json` and all credentials from `creds.json` and proceeds without asking any questions.

archinstall handles: partitioning, formatting, LUKS setup, Btrfs subvolumes, mounting, pacstrap (base packages), bootloader installation, user creation, service enabling, and unmounting. When it finishes, the new system is fully installed and still mounted at `/mnt`.

---

#### Post-archinstall: clone repo and prepare for reboot

```bash
DOOM_CHROOT_PATH="/mnt/home/${username}/.local/share/doom_v0"

mkdir -p "$DOOM_CHROOT_PATH"
git clone "$DOOM_REPO" "$DOOM_CHROOT_PATH"

arch-chroot /mnt chown -R "${username}:${username}" "/home/${username}/.local"
```

archinstall leaves the new system still mounted at `/mnt` when it finishes. The script takes advantage of this to clone the doom_v0 repo directly into the new user's home directory before rebooting, so it is ready the moment the user logs in.

**Why not run the installer in the chroot?**

A chroot changes the filesystem root so paths resolve correctly, but it does not give you a running system. Systemd is not running, D-Bus is not available, and no services are active. For a desktop environment installer this matters significantly:

- `systemctl enable --now` does not work — services can only be enabled, not started or tested
- GPU drivers cannot be loaded or verified
- Hardware detection reads the live ISO's view, not the installed system's
- Tools like `hyprctl` and `pactl` have nothing to talk to
- AUR package builds that check for running system state may fail

Running the installer after a proper reboot means full systemd is active, services start immediately when enabled, the correct kernel and initramfs are loaded, and hardware is seen from the perspective of the actual installed system.

**Ownership fix**

The `git clone` is executed as root (the live ISO runs as root). Inside the new system the cloned directory would be owned by root, which the regular user cannot write to. `arch-chroot /mnt chown -R` corrects this before rebooting, ensuring the user owns their own files from first login.

**After the script finishes**, the user is shown:

```
Next steps:
  1. Remove the installation media
  2. reboot
  3. Log in as <username>
  4. Run: bash ~/.local/share/doom_v0/doom_install.sh
```

The doom_v0 installer is run manually by the user after logging in. What triggers that run (shell profile, systemd service, or manual command) is left to the user to configure.

---

### config.json

**Location:** `arch_iso/config.json`
**Read by:** `archinstall_manager.sh` (after placeholder substitution)

A static JSON file that tells archinstall everything about the system to install: disk layout, filesystem, bootloader, packages, locale, and more. Three values are placeholders replaced at runtime; everything else is fixed.

---

#### `app_config`

```json
"app_config": {
    "audio_config": {
        "audio": "pipewire"
    },
    "bluetooth_config": {
        "enabled": true
    }
}
```

**Audio — `pipewire`**
Tells archinstall to install the PipeWire audio stack: `pipewire`, `pipewire-alsa`, `pipewire-audio`, `pipewire-jack`, `pipewire-pulse`, and `wireplumber` (the session manager). PipeWire handles both audio and video capture, replaces PulseAudio, and is fully compatible with JACK and ALSA applications.

**Bluetooth — `enabled: true`**
Installs `bluez` and `bluez-utils` and enables `bluetooth.service`. This makes the Bluetooth hardware available on boot. Pairing and connecting devices is done afterwards with `bluetoothctl` or a GUI front-end.

---

#### `bootloader_config`

```json
"bootloader_config": {
    "bootloader": "Systemd-boot",
    "removable": false,
    "uki": false
}
```

**`Systemd-boot`** — a minimal EFI bootloader that is part of systemd itself. It installs into the EFI system partition (`/boot`) and reads boot entries from `/boot/loader/entries/`. It is simpler and faster than GRUB and requires no separate bootloader partition.

**`removable: false`** — installs the bootloader to the standard EFI path (`/EFI/systemd/`) rather than the fallback path (`/EFI/BOOT/BOOTX64.EFI`) used for removable media.

**`uki: false`** — does not create a Unified Kernel Image. The kernel, initramfs, and kernel command line are kept as separate files in `/boot`, which is the standard setup.

With LUKS encryption active, archinstall automatically adds the necessary kernel parameters (`rd.luks.name`, `root=`, `rootflags=`) to the boot entry so the system can decrypt the drive on startup.

---

#### `disk_config`

This is the most complex section. It fully describes the partition layout, filesystem configuration, and encryption setup.

```json
"config_type": "default_layout",
"wipe": true
```

`default_layout` tells archinstall to use the partition definitions exactly as written in the JSON. `wipe: true` means the entire target disk is wiped before partitioning — all existing data will be destroyed.

---

##### Partition 1 — EFI / Boot

```json
{
    "flags": ["boot"],
    "fs_type": "fat32",
    "mountpoint": "/boot",
    "obj_id": "doom-part-boot-0001",
    "size": {"unit": "GiB", "value": 1},
    "start": {"unit": "MiB", "value": 1}
}
```

- **`flags: ["boot"]`** — marks this as the EFI System Partition (ESP). Required for UEFI boot.
- **`fs_type: "fat32"`** — the EFI specification requires FAT32 for the ESP. The bootloader files and kernel images are stored here.
- **`mountpoint: "/boot"`** — the kernel (`vmlinuz-linux`), initramfs (`initramfs-linux.img`), and the systemd-boot loader all live here.
- **`size: 1 GiB`** — 1 GiB is generous for a boot partition but ensures space for multiple kernels and initramfs images without issues.
- **`start: 1 MiB`** — the 1 MiB offset from the start of the disk is standard alignment for modern GPT partitioning. Avoids the first sector which holds the partition table.
- **`obj_id: "doom-part-boot-0001"`** — an internal reference ID used only within this JSON file. Not a real disk UUID.

---

##### Partition 2 — Btrfs root (LUKS encrypted)

```json
{
    "fs_type": "btrfs",
    "mount_options": ["compress=zstd", "noatime"],
    "obj_id": "doom-part-root-0002",
    "size": {"unit": "Percent", "value": 100},
    "start": {"unit": "GiB", "value": 1}
}
```

- **`fs_type: "btrfs"`** — the root filesystem. Btrfs supports subvolumes, transparent compression, and snapshots natively.
- **`compress=zstd`** — all data written to the filesystem is transparently compressed with the Zstandard algorithm. This reduces disk usage and can improve read performance because less data is read from disk (decompression is fast). No application change is needed.
- **`noatime`** — disables writing the access time when a file is read. On a traditional filesystem, reading a file updates its `atime` metadata, which causes a write on every read. Disabling this eliminates a significant source of unnecessary disk writes.
- **`size: 100 Percent`** — uses all remaining space after the boot partition. This works regardless of the actual disk size, making the config portable to any drive.
- **`start: 1 GiB`** — starts immediately after the boot partition.
- **`obj_id: "doom-part-root-0002"`** — referenced in `disk_encryption.partitions` below to tell archinstall which partition to encrypt.

---

##### Btrfs subvolumes

```json
"btrfs": [
    {"mountpoint": "/",                     "name": "@"},
    {"mountpoint": "/home",                 "name": "@home"},
    {"mountpoint": "/var/log",              "name": "@log"},
    {"mountpoint": "/var/cache/pacman/pkg", "name": "@pkg"}
]
```

Btrfs subvolumes behave like separate filesystems within the same partition. They can be snapshotted and backed up independently. The `@` naming convention is the standard for Btrfs layouts:

| Subvolume | Mountpoint | Purpose |
|---|---|---|
| `@` | `/` | Root filesystem — the OS itself |
| `@home` | `/home` | User data — kept separate so snapshots of `/` don't include personal files |
| `@log` | `/var/log` | System logs — excluded from root snapshots so log growth doesn't affect them |
| `@pkg` | `/var/cache/pacman/pkg` | Pacman's package cache — excluded from snapshots since packages can be redownloaded |

Separating `@home`, `@log`, and `@pkg` from `@` is important for snapshots: when you snapshot `@` (the root), you get a clean image of the OS without capturing gigabytes of user data or log files.

---

##### LUKS encryption

```json
"disk_encryption": {
    "encryption_type": "luks",
    "lvm_volumes": [],
    "partitions": ["doom-part-root-0002"]
}
```

Tells archinstall to encrypt partition `doom-part-root-0002` (the Btrfs root) using LUKS2. `lvm_volumes: []` means no LVM is used — LUKS directly contains the Btrfs filesystem.

The boot partition (`doom-part-boot-0001`) is **not** encrypted. It does not need to be — the bootloader and kernel live there but no user data does. Encrypting `/boot` would require additional setup that is not necessary for this use case.

At boot, systemd-boot loads the kernel and initramfs from the unencrypted `/boot`. The kernel's initramfs then prompts for the LUKS password, decrypts the partition, and mounts the Btrfs subvolumes. Everything below `/boot` (your home directory, all installed software, logs, and cache) is encrypted.

---

#### `hostname`

```json
"hostname": "__HOSTNAME__"
```

Placeholder replaced at runtime by `sed` with the hostname the user typed. archinstall writes this to `/etc/hostname` and configures the local DNS resolver so `hostname` resolves to `127.0.1.1`.

---

#### `kernels`

```json
"kernels": ["linux"]
```

Installs the standard Arch Linux kernel (`linux` package). `linux` tracks the latest stable kernel. Alternatives like `linux-lts` (Long Term Support) or `linux-zen` (latency-optimized) can be added to the array to install multiple kernels simultaneously.

---

#### `locale_config`

```json
"locale_config": {
    "kb_layout": "us",
    "sys_enc": "UTF-8",
    "sys_lang": "en_US.UTF-8"
}
```

- **`kb_layout: "us"`** — sets the console keyboard layout to US QWERTY. Written to `/etc/vconsole.conf`. Does not affect graphical keyboard configuration (that is handled by the desktop environment later).
- **`sys_enc: "UTF-8"`** — the character encoding for the system locale.
- **`sys_lang: "en_US.UTF-8"`** — the full locale string written to `/etc/locale.conf`. Controls the language for system messages, date formats, number formats, etc.

---

#### `mirror_config`

```json
"mirror_config": {
    "custom_repositories": [],
    "custom_servers": [],
    "mirror_regions": {},
    "optional_repositories": []
}
```

All fields are empty. This means archinstall does not configure mirrors at all — it uses whatever is already in `/etc/pacman.d/mirrorlist` on the live ISO.

The Arch ISO runs `reflector` on boot, which fetches the full mirror list from archlinux.org, tests each mirror for speed and freshness, and writes the top-ranked results to `/etc/pacman.d/mirrorlist`. By the time `archinstall_manager.sh` runs, that file already contains the fastest mirrors for your geographic location. Leaving `mirror_regions` empty means we inherit that already-ranked list rather than overriding it with a hardcoded set.

---

#### `network_config`

```json
"network_config": {
    "type": "nm"
}
```

Installs and enables NetworkManager (`networkmanager` package, `NetworkManager.service`). NetworkManager handles both wired and wireless connections and provides `nmcli` (command-line) and `nmtui` (terminal UI) for managing them after boot. The `nm` shorthand is archinstall's identifier for NetworkManager.

---

#### `ntp`

```json
"ntp": true
```

Enables `systemd-timesyncd`, which keeps the system clock synchronized with internet time servers. archinstall runs `timedatectl set-ntp true` to activate this. On first boot the clock will be set automatically as soon as a network connection is available.

---

#### `packages`

```json
"packages": [
    "base",
    "base-devel",
    "neovim",
    "git",
    "lazygit"
]
```

Packages installed by archinstall as part of the base system via `pacstrap`. These are intentionally minimal — the doom_v0 installer adds the full package set afterwards.

| Package | Purpose |
|---|---|
| `base` | Core userland: glibc, bash, coreutils, systemd, pacman |
| `base-devel` | Build tools: gcc, make, binutils — needed to compile AUR packages |
| `neovim` | Text editor — available immediately after first boot before the doom_v0 installer runs |
| `git` | Required to clone the doom_v0 repo into the new system from the chroot |
| `lazygit` | Terminal Git UI — useful from first boot |

Note: `networkmanager` and `sudo` do not need to be listed here because they are pulled in automatically — `networkmanager` by `network_config.type: nm`, and `sudo` by archinstall when creating a user with `sudo: true`.

---

#### `swap`

```json
"swap": {
    "algorithm": "zstd",
    "enabled": true
}
```

Enables ZRAM-based swap. ZRAM creates a compressed block device in RAM that acts as a swap device. When the system needs to swap, pages are compressed with `zstd` and stored in RAM rather than written to disk. This is significantly faster than disk swap and works well on systems with limited RAM.

archinstall sets this up using `systemd-zram-generator`, which creates and manages the ZRAM device automatically. The size is typically set to half of physical RAM.

---

#### `timezone`

```json
"timezone": "__TIMEZONE__"
```

Placeholder replaced at runtime by `sed` with the timezone the user entered (or accepted as default). archinstall uses this value to create the symlink `/etc/localtime` → `/usr/share/zoneinfo/<timezone>` and writes it to `/etc/adjtime`. Combined with `ntp: true`, the system clock will be both set to the correct timezone and kept accurate via NTP.

---

## Install_Skeleton

The skeleton is the framework that all install phases plug into. It consists of the main entry point (`doom_install.sh`) and the helpers directory, which must be sourced first because every subsequent phase depends on the functions and variables they define.

**Files:**
```
doom_v0/
├── doom_install.sh
└── install/
    └── helpers/
        ├── 000_doom.sh
        ├── chroot.sh
        ├── presentation.sh
        ├── errors.sh
        └── logging.sh
```

**Load order matters.** `000_doom.sh` sources the helpers in a specific sequence because each one depends on the previous:

```
chroot.sh → presentation.sh → errors.sh → logging.sh
```

`presentation.sh` must come before `errors.sh` because the error handler calls `clear_logo`, `show_cursor`, and uses the color variables. `errors.sh` must come before `logging.sh` because the ERR trap must be in place before any logged command runs.

---

### doom_install.sh

**Location:** `doom_install.sh` (project root)
**Run with:** `bash ~/.local/share/doom_v0/doom_install.sh`

The main entry point for the doom_v0 installer. Its only job is to set environment variables and source the six install phases in order. It contains no install logic itself — all logic lives inside the phases.

#### Safety flags

```bash
set -eEo pipefail
```

- `-e` — exit on any command failure
- `-E` — ensures the ERR trap defined in `errors.sh` fires even inside functions and subshells, not just at the top level
- `-o pipefail` — a failed command inside a pipe fails the whole pipe

The `-E` flag is the key difference from `set -eo pipefail`. Without it, an error inside a function called from a subscript would not trigger the ERR trap, and the failure could go undetected.

#### Environment variables

All variables are exported so every sourced script and every subshell spawned during installation can see them without needing to redefine them.

**Project paths**

```bash
export DOOM_PATH="$HOME/.local/share/doom_v0"
export DOOM_INSTALL="$DOOM_PATH/install"
export DOOM_INSTALL_LOG_FILE="/var/log/doom-install.log"
```

| Variable | Value | Purpose |
|---|---|---|
| `DOOM_PATH` | `~/.local/share/doom_v0` | Root of the project |
| `DOOM_INSTALL` | `$DOOM_PATH/install` | Root of the install phases directory |
| `DOOM_INSTALL_LOG_FILE` | `/var/log/doom-install.log` | Where all install output is written |

**XDG Base Directories**

```bash
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
```

The `:-` syntax means a pre-existing value in the environment is respected — if the user already has `XDG_CONFIG_HOME` set to a non-standard path, it will not be overwritten.

| Variable | Default value | Purpose |
|---|---|---|
| `XDG_CONFIG_HOME` | `~/.config` | User configuration files |
| `XDG_CACHE_HOME` | `~/.cache` | Non-essential cached data |
| `XDG_DATA_HOME` | `~/.local/share` | User data files |
| `XDG_STATE_HOME` | `~/.local/state` | Persistent runtime state (logs, history) |

**Tool-specific directories (XDG-compliant)**

Many CLI tools default to writing their data directly into `$HOME` (e.g. `~/.cargo`, `~/.rustup`, `~/go`). Setting these variables before any package is installed redirects each tool to an XDG-compliant location so nothing ever scatters into the home root.

```bash
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export ZIG_GLOBAL_CACHE_DIR="$XDG_CACHE_HOME/zig"
export ZIG_GLOBAL_PACKAGE_DIR="$XDG_DATA_HOME/zig"
export NUGET_PACKAGES="$XDG_CACHE_HOME/nuget"
export DOTNET_CLI_HOME="$XDG_CONFIG_HOME/dotnet"
export DOTNET_CLI_CACHE_HOME="$XDG_CACHE_HOME/dotnet"
```

| Variable | Value | Tool |
|---|---|---|
| `ZDOTDIR` | `~/.config/zsh` | Zsh — config directory (`~/.zshrc`, `~/.zshenv`, etc.) |
| `CARGO_HOME` | `~/.local/share/cargo` | Rust — toolchain and installed binaries |
| `RUSTUP_HOME` | `~/.local/share/rustup` | Rustup — toolchain downloads |
| `GOPATH` | `~/.local/share/go` | Go — workspace and installed binaries |
| `GOMODCACHE` | `~/.cache/go/mod` | Go — module download cache |
| `ZIG_GLOBAL_CACHE_DIR` | `~/.cache/zig` | Zig — compilation cache |
| `ZIG_GLOBAL_PACKAGE_DIR` | `~/.local/share/zig` | Zig — global packages |
| `NUGET_PACKAGES` | `~/.cache/nuget` | .NET — NuGet package cache |
| `DOTNET_CLI_HOME` | `~/.config/dotnet` | .NET CLI — config and tools |
| `DOTNET_CLI_CACHE_HOME` | `~/.cache/dotnet` | .NET CLI — CLI cache |

**PATH**

```bash
export PATH="$DOOM_PATH/bin:$HOME/.local/bin:$CARGO_HOME/bin:$GOPATH/bin:$PATH"
```

Prepends four directories so install-time scripts and freshly-installed language binaries are found immediately without re-sourcing the shell.

| Entry | Purpose |
|---|---|
| `$DOOM_PATH/bin` | doom_v0 helper commands |
| `$HOME/.local/bin` | User-local binaries |
| `$CARGO_HOME/bin` | Rust binaries installed via `cargo install` |
| `$GOPATH/bin` | Go binaries installed via `go install` |

**Directory creation**

```bash
mkdir -p \
  "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" \
  "$ZDOTDIR" "$CARGO_HOME" "$RUSTUP_HOME" \
  "$GOPATH" "$GOMODCACHE" \
  "$ZIG_GLOBAL_CACHE_DIR" "$ZIG_GLOBAL_PACKAGE_DIR" \
  "$NUGET_PACKAGES" "$DOTNET_CLI_HOME" "$DOTNET_CLI_CACHE_HOME"
```

All directories are created immediately after the variables are set so that tools can write to them even before the packaging phase installs the tools themselves. This prevents any first-run directory creation from happening as root or in an unexpected location.

#### Phase sourcing

```bash
source "$DOOM_INSTALL/helpers/000_doom.sh"
source "$DOOM_INSTALL/preflight/001_doom.sh"
source "$DOOM_INSTALL/packaging/002_doom.sh"
source "$DOOM_INSTALL/config/003_doom.sh"
source "$DOOM_INSTALL/login/004_doom.sh"
source "$DOOM_INSTALL/post-install/005_doom.sh"
```

Each phase has a numbered orchestrator file (`000_doom.sh`, `001_doom.sh`, …) that acts as its internal loader. The `NNN_doom.sh` naming convention makes the load order explicit at a glance and groups the orchestrators visually at the top of each directory listing. `doom_install.sh` only knows about the six top-level phase files — it does not know or care about the individual scripts inside each phase directory. Adding a new script to any phase is done entirely within that phase's directory.

`source` is used instead of `bash` or executing subshells so that exported variables, functions, and traps defined in helpers remain active for every subsequent phase.

---

### helpers/000_doom.sh

**Location:** `install/helpers/000_doom.sh`

The helpers orchestrator. Sources the four helper files in the order they must be loaded. No logic of its own — purely a loader.

```bash
source "$DOOM_INSTALL/helpers/chroot.sh"
source "$DOOM_INSTALL/helpers/presentation.sh"
source "$DOOM_INSTALL/helpers/errors.sh"
source "$DOOM_INSTALL/helpers/logging.sh"
```

---

### helpers/chroot.sh

**Location:** `install/helpers/chroot.sh`

Provides two functions used by any install script that enables a systemd service.

#### `is_chroot()`

```bash
is_chroot() {
  [[ -f /proc/1/environ ]] && tr '\0' '\n' < /proc/1/environ | grep -q "container=systemd-nspawn" && return 0
  [[ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/. 2>/dev/null)" ]] && return 0
  return 1
}
```

Detects whether the script is running inside a chroot using two checks:

1. **systemd-nspawn check** — reads PID 1's environment variables. If `container=systemd-nspawn` is set, we are inside a systemd container (effectively a chroot).
2. **Filesystem root check** — compares the device and inode of `/` with those of `/proc/1/root`. On a normal booted system these are identical. Inside a chroot they differ because the outer system's PID 1 has a different root than the chroot's `/`.

#### `systemctl_enable()`

```bash
systemctl_enable() {
  if is_chroot; then
    sudo systemctl enable "$@"
  else
    sudo systemctl enable --now "$@"
  fi
}
```

A wrapper that every install script uses instead of calling `systemctl enable` directly. On a live booted system, `--now` starts the service immediately after enabling it. Inside a chroot, `--now` is omitted because systemd is not running and the service will start automatically on first real boot.

Both functions are exported with `export -f` so they are available in subshells spawned by `run_logged`.

---

### helpers/presentation.sh

**Location:** `install/helpers/presentation.sh`

Defines all visual output used throughout the installer: colors, the logo, layout constants, and print functions.

#### Terminal dimensions

```bash
export TERM_WIDTH=${COLUMNS:-80}
export TERM_HEIGHT=${LINES:-24}
```

Reads the terminal size from environment variables set by the shell. Falls back to 80×24 if they are not available. Used by the log tail display to calculate how many lines to show.

#### Colors

Standard ANSI escape codes stored as variables. Every script uses these instead of hardcoding escape sequences.

#### Logo and layout constants

```bash
export LOGO_WIDTH=80
export LOGO_HEIGHT=21
export PADDING_LEFT=4
export PADDING_LEFT_SPACES="    "
```

`LOGO_WIDTH` and `LOGO_HEIGHT` are used by the error handler and log monitor to calculate how much vertical space the logo takes and how wide to truncate log lines. `PADDING_LEFT_SPACES` is a literal string of spaces prepended to every printed line to give the output left margin.

#### Print functions

| Function | Prefix | Use |
|---|---|---|
| `print_step` | `==>` green bold | Major install steps — one per script |
| `print_info` | `→` cyan | Sub-messages within a step |
| `print_warn` | `!` yellow | Non-fatal warnings |
| `print_error` | `✗` red | Error messages (does not exit) |

#### Cursor control

`show_cursor` and `hide_cursor` send ANSI escape sequences to show or hide the terminal cursor. The log monitor hides it to prevent flickering during live log output, and `show_cursor` is always called on exit to ensure the cursor is restored.

---

### helpers/errors.sh

**Location:** `install/helpers/errors.sh`

The error recovery system. Sets up signal traps that catch failures anywhere in the install process and present the user with a recovery menu instead of a raw crash.

#### Output saving

```bash
save_original_outputs()  →  exec 3>&1 4>&2
restore_outputs()        →  exec 1>&3 2>&4
```

Before the installer starts logging, the original stdout (fd 1) and stderr (fd 2) are duplicated to file descriptors 3 and 4. During normal operation, stdout and stderr are redirected to the log file by `run_logged`. When an error occurs, `restore_outputs` reconnects fd 1 and fd 2 to the terminal so the error display is visible to the user.

#### `catch_errors()`

The main error handler. Called when the ERR trap fires. It:

1. Guards against running twice (`ERROR_HANDLING` flag)
2. Stops the live log monitor
3. Restores terminal output
4. Clears the screen and prints the failure message
5. Shows the tail of the log so the user can see what failed
6. Shows which script or command failed
7. Presents a recovery menu

**Recovery menu options:**

| Option | Action |
|---|---|
| Retry installation | Re-runs `doom_install.sh` from the beginning |
| View full log | Opens the full log in `less` (or `tail -40` as fallback) |
| Exit | Exits with code 1 |

The menu uses `gum` if available (installed in a later phase) and falls back to bash `select` otherwise.

#### Traps

```bash
trap catch_errors ERR INT TERM
trap exit_handler EXIT
```

- **`ERR`** — fires whenever any command exits non-zero (combined with `set -eE`)
- **`INT`** — fires on Ctrl+C
- **`TERM`** — fires when the process is killed with SIGTERM
- **`EXIT`** — fires on any exit, success or failure, to ensure cleanup always runs

`exit_handler` checks the exit code: if non-zero and `catch_errors` hasn't already run, it calls `catch_errors`. If the exit was clean, it just stops the log monitor and restores the cursor.

---

### helpers/logging.sh

**Location:** `install/helpers/logging.sh`

Manages the install log file and a live-tailing background process that shows install progress on screen.

#### `start_install_log()` / `stop_install_log()`

`start_install_log` creates the log file at `/var/log/doom-install.log`, records the start time, and launches the live monitor. `stop_install_log` kills the monitor, records the end time, and calculates total install duration.

#### Live log monitor (`start_log_output`)

```bash
(
  while true; do
    mapfile -t current_lines < <(tail -n $log_lines "$DOOM_INSTALL_LOG_FILE" 2>/dev/null)
    # ... format and print lines ...
    printf "${ANSI_RESTORE_CURSOR}%b" "$output"
    sleep 0.1
  done
) &
monitor_pid=$!
```

Runs as a background subshell (`&`) that loops every 100ms. On each iteration it reads the last 18 lines of the log file and reprints them in place using ANSI cursor-save/restore sequences (`\033[s` / `\033[u`). This gives the appearance of a live-updating display without clearing the whole screen. Lines longer than `LOGO_WIDTH - 4` characters are truncated with `...` to prevent wrapping.

The background process PID is stored in `monitor_pid` so `stop_log_output` can kill it cleanly.

#### `run_logged()`

```bash
run_logged() {
  local script="$1"
  export CURRENT_SCRIPT="$script"
  bash -c "source '$script'" </dev/null >> "$DOOM_INSTALL_LOG_FILE" 2>&1
  ...
}
```

The function every phase uses to execute its individual scripts. Key behaviors:

- Sets `CURRENT_SCRIPT` so `errors.sh` can report which script failed
- Redirects all stdout and stderr to the log file — the user sees the live log monitor instead of raw output
- Uses `bash -c "source '$script'"` rather than `bash '$script'` so the sourced script inherits all exported functions and variables from the current shell
- `</dev/null` prevents the subscript from accidentally reading from stdin
- Logs a timestamped start and completion (or failure) entry around every script

---

## Preflight

The preflight phase runs immediately after the helpers are loaded, before any package or system changes. Its job is to verify that the environment is suitable for installation, initialize pacman, and set up the state directory.

**Files:**
```
install/preflight/
├── 001_doom.sh  ← orchestrator: runs the three scripts in order
├── guard.sh     ← environment checks (abort or warn on bad conditions)
├── pacman.sh    ← keyring init, pacman.conf tweaks, database sync + upgrade
└── markers.sh   ← state dir creation, mkinitcpio hook suppression
```

**Load order matters.** `001_doom.sh` calls the three scripts in a fixed sequence: `guard.sh` runs first so the install aborts early if the environment is wrong, `pacman.sh` runs next so the package database is synced and upgraded and `gum` is available for recovery menus, and `markers.sh` runs last.

---

### preflight/001_doom.sh

**Location:** `install/preflight/001_doom.sh`

The preflight orchestrator. Calls `run_logged` for each script in sequence. Uses `run_logged` (defined in `logging.sh`) so all output goes to the install log and failures trigger the error recovery menu.

```bash
run_logged $DOOM_INSTALL/preflight/guard.sh
run_logged $DOOM_INSTALL/preflight/pacman.sh
run_logged $DOOM_INSTALL/preflight/markers.sh
```

---

### preflight/guard.sh

**Location:** `install/preflight/guard.sh`

Runs a series of environment checks. Each check calls `abort()` if it fails.

#### `abort()`

```bash
abort() {
  echo -e "\e[31mdoom_v0 requires: $1\e[0m"
  if command -v gum &>/dev/null; then
    gum confirm "Proceed anyway at your own risk?" || exit 1
  else
    read -rp "Proceed anyway? [y/N] " ans
    [[ "${ans,,}" == "y" ]] || exit 1
  fi
}
```

A **soft abort** — it warns the user and asks whether to continue rather than exiting unconditionally. This lets the user override a check they know does not apply to their situation. The check uses `gum confirm` if `gum` is available (installed in `pacman.sh`), otherwise falls back to a plain `read` prompt.

#### Guard checks

| Check | How | Why |
|---|---|---|
| Vanilla Arch Linux | `[[ -f /etc/arch-release ]]` | This file only exists on Arch. Prevents running on wrong distro. |
| No derivatives | Checks for `/etc/cachyos-release`, `/etc/eos-release`, `/etc/garuda-release`, `/etc/manjaro-release` | Derivatives patch internals in ways that break the installer assumptions. |
| Not root | `(( EUID == 0 ))` | The installer uses `sudo` for privileged commands. Running as root breaks relative paths and user-specific config deployment. |
| x86_64 CPU | `uname -m` | All packages and config assume a 64-bit x86 system. |
| Secure Boot disabled | `bootctl status \| grep 'Secure Boot: enabled'` | Unsigned custom kernels and third-party drivers (e.g. NVIDIA dkms) will not load with Secure Boot on. |
| No GNOME or KDE | `pacman -Qe gnome-shell`, `pacman -Qe plasma-desktop` | Installing a second desktop environment over an existing one causes conflicts. |
| Btrfs root | `findmnt -n -o FSTYPE /` | The post-install phase and snapshot commands assume a Btrfs root. The archinstall config always creates Btrfs, so this should always pass on a fresh install. |
| ≥ 15 GB free | `df -BG /` | The full package install requires significant space. Warns early rather than failing mid-install. |

**Note on Limine:** The hybrid project had a Limine bootloader guard. doom_v0 uses Systemd-boot, which is installed by archinstall before this script ever runs. If you booted into the system, the bootloader is working — no check needed.

---

### preflight/pacman.sh

**Location:** `install/preflight/pacman.sh`

Initializes the pacman package manager and syncs the package database.

```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux
```

Initializes the GPG keyring that pacman uses to verify package signatures. `--init` creates the keyring directory and generates the master key if it does not exist. `--populate archlinux` imports all the trusted Arch Linux developer keys from the keyring package. Both steps are required before any packages can be installed.

```bash
sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
```

Uncomments two options in `pacman.conf` that are commented out by default:
- **`ParallelDownloads`** — enables downloading multiple packages simultaneously (the default value in the file is 5). Significantly speeds up the packaging phase.
- **`Color`** — enables colored output in pacman's progress and status messages.

```bash
sudo pacman -Syu --noconfirm
```

Syncs the package database and upgrades all installed packages before anything new is installed. The flags:

- `-S` — sync (install/upgrade packages)
- `-y` — refresh the package database from mirrors
- `-u` — upgrade all installed packages that have newer versions available

Using `-Syu` rather than `-Sy` alone is critical. With `-Sy`, the local database is updated to reflect the latest package versions, but installed packages stay at their current (older) versions. If the packaging phase then installs something with a dependency on a newer library, the already-installed older version of that library conflicts — a **partial upgrade**, which can break the system. `-Syu` eliminates this by bringing all installed packages up to date first, so the entire system is at a consistent version level before new packages are added.

```bash
pacman -Qe gum &>/dev/null || sudo pacman -S --noconfirm gum
```

Installs `gum` if it is not already present. `gum` is a TUI toolkit used by the error recovery menu in `errors.sh` for the styled recovery prompt. Installing it here (before the packaging phase) ensures it is available if an error occurs during any subsequent phase.

---

### preflight/markers.sh

**Location:** `install/preflight/markers.sh`

Creates the doom_v0 state directory and suppresses mkinitcpio during package installs.

```bash
mkdir -p "$HOME/.local/state/doom_v0"
```

Creates the state directory that doom_v0 uses to track install-time information. Following the XDG Base Directory specification, state data goes in `~/.local/state/` rather than `~/.config/` (user configuration) or `~/.local/share/` (application data).

```bash
if [[ -f /etc/mkinitcpio.conf ]]; then
  sudo sed -i 's/^HOOKS=/#HOOKS=/' /etc/mkinitcpio.conf 2>/dev/null || true
fi
```

Comments out the `HOOKS=` line in `mkinitcpio.conf`. This prevents mkinitcpio from running a full initramfs rebuild every time a kernel or initramfs-related package is installed during the packaging phase. On a system with many packages, this can trigger dozens of rebuilds — each taking 30–60 seconds — that are completely wasted since the final rebuild in `post-install/initramfs.sh` overwrites them all anyway.

The `|| true` at the end ensures the script does not abort if the `sed` command fails for any reason (e.g. the file is read-only), since suppressing rebuilds is an optimization, not a requirement.

**Re-enabled by:** `post-install/initramfs.sh` (runs `mkinitcpio -P` once after all packages are installed).

---

## Packaging

The packaging phase installs every package the system needs: official repo packages from `packages.list`, AUR packages from `aur.sh`, and optionally-chosen extras from `optional.sh`. It runs after preflight so the package database is already synced and `paru` can be installed cleanly.

**Files:**
```
install/packaging/
├── 002_doom.sh    ← orchestrator: calls base, aur, optional in order
├── base.sh        ← reads packages.list, installs via pacman, installs paru
├── packages.list  ← curated list of official repo packages
├── aur.sh         ← AUR packages installed via paru
└── optional.sh    ← interactively prompted extras
```

---

### packaging/002_doom.sh

**Location:** `install/packaging/002_doom.sh`

The packaging orchestrator. Runs the three sub-scripts in sequence, each as a `run_logged` call so output goes to the install log.

```bash
print_step "Installing base packages"
run_logged $DOOM_INSTALL/packaging/base.sh

print_step "Installing AUR packages"
run_logged $DOOM_INSTALL/packaging/aur.sh

print_step "Installing optional packages"
run_logged $DOOM_INSTALL/packaging/optional.sh
```

`print_step` calls here (rather than inside the sub-scripts) mean the step headers appear in the live terminal display while the actual install output is captured in the log.

---

### packaging/base.sh

**Location:** `install/packaging/base.sh`

Reads `packages.list`, builds the package array, installs everything in one pacman invocation, then installs the `paru` AUR helper.

#### Reading packages.list

```bash
while IFS= read -r line; do
  line="${line%%#*}"    # Strip inline comments
  line="${line// /}"   # Strip spaces
  [[ -n "$line" ]] && packages+=("$line")
done < "$PACKAGES_LIST"
```

The loop handles two things: `${line%%#*}` strips everything from the first `#` onward (inline comments), and `${line// /}` removes all spaces. Lines that are empty after stripping are skipped. This lets `packages.list` use comments freely without affecting the package array.

#### Installing packages

```bash
sudo pacman -S --needed --noconfirm "${packages[@]}"
```

All packages are passed in a single `pacman -S` call. `--needed` skips packages that are already installed (makes the script idempotent — safe to re-run). `--noconfirm` suppresses all prompts.

#### Installing paru

```bash
if ! command -v paru &>/dev/null; then
  local tmpdir=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmpdir/paru"
  cd "$tmpdir/paru"
  makepkg -si --noconfirm
  cd -
  rm -rf "$tmpdir"
fi
```

`paru-bin` is the pre-compiled binary release of paru — it installs instantly without compiling Rust. `--depth 1` clones only the latest commit (no history) to minimize download size. `makepkg -si` builds the package and installs it with `--noconfirm`. The temp directory is cleaned up afterwards.

paru is installed here rather than via AUR because it is the tool that installs everything in `aur.sh` — it must exist before `aur.sh` runs.

---

### packaging/packages.list

**Location:** `install/packaging/packages.list`

The curated list of official Arch Linux repository packages. Grouped by category with inline comments explaining each entry.

**Format:** one package per line, `#` starts a comment (inline or full-line), blank lines ignored.

**Key decisions vs. the hybrid original:**

| Change | Reason |
|---|---|
| `limine` removed | doom_v0 uses Systemd-boot, which archinstall installs before first boot. No second bootloader needed. |
| `avahi` deduplicated | Appeared twice in the hybrid original (under Network and System Tools). One entry kept under Network. |
| `walker` removed | Hybrid-specific launcher tied to the hybrid command system. Not brought in for doom_v0. |
| `mise` removed from list | Available as `mise-bin` in AUR (pre-compiled binary, faster). Kept only in `aur.sh`. |

**Package groups summary:**

| Group | Count | Notable packages |
|---|---|---|
| Wayland/Display | 13 | hyprland, uwsm, hypridle, hyprlock, hyprsunset |
| Display Manager | 2 | sddm, plymouth |
| Status Bar | 1 | waybar |
| Notifications | 1 | mako |
| Launchers | 2 | rofi-wayland, cliphist |
| Terminals | 2 | kitty, alacritty |
| Shell | 6 | zsh, starship, zoxide, fzf |
| Editors | 3 | neovim, vi, nano |
| File Managers | 5 | yazi, thunar + gvfs |
| Audio | 6 | pipewire stack + wireplumber + pavucontrol |
| Theming | 7 | matugen, papirus-icon-theme, kvantum, nwg-look |
| Wallpaper | 3 | swww, waypaper, hyprpaper |
| Screenshots | 5 | grim, slurp, satty, gpu-screen-recorder |
| Fonts | 5 | JetBrains Mono Nerd, Noto, Font Awesome |
| Network | 8 | NetworkManager, bluez, tailscale, ufw, avahi |
| Security | 5 | gnome-keyring, polkit-gnome, openssh, gnupg |
| Development | 12 | git, docker, base-devel, rustup, lazygit |
| CLI Utilities | 16 | bat, eza, fd, ripgrep, tmux, curl |
| Media | 5 | ffmpeg, mpv, imagemagick |
| Browsers | 2 | chromium, firefox |
| Productivity | 5 | obsidian, libreoffice-fresh, zathura |
| System Tools | 9 | brightnessctl, playerctl, tlp, cups |
| Filesystem | 4 | btrfs-progs, snapper, ntfs-3g |
| Performance | 2 | zram-generator, preload |
| Misc | 6 | gum, xdg-user-dirs, wlr-randr |

---

### packaging/aur.sh

**Location:** `install/packaging/aur.sh`

Installs packages from the Arch User Repository using `paru`. Each package is installed individually so a single failure does not abort the rest.

```bash
for pkg in "${aur_packages[@]}"; do
  if paru -Qe "$pkg" &>/dev/null; then
    echo "  already installed: $pkg"
    continue
  fi
  paru -S --noconfirm --needed "$pkg" || echo "  WARNING: Failed to install $pkg (non-fatal)"
done
```

- **`paru -Qe`** — checks whether the package is already explicitly installed. Skips it if so (idempotent).
- **`|| echo "WARNING: ..."`** — AUR package failures are non-fatal. AUR packages can fail to build due to upstream changes, missing dependencies, or PKGBUILD issues outside our control. A warning is logged but the install continues.

**AUR package list:**

| Package | Purpose |
|---|---|
| `sddm-theme-astronaut` | SDDM login screen theme |
| `papirus-folders` | Colored folder icons matching the theme |
| `swaynotificationcenter` | Notification sidebar (SwayNC) |
| `wlogout` | Wayland logout / power menu screen |
| `claude-code` | Claude Code AI CLI |
| `mise-bin` | Dev tool version manager (pre-compiled binary) |
| `lazydocker` | TUI Docker management |
| `cava` | Terminal audio visualizer |
| `bluetui` | Bluetooth TUI manager |
| `impala` | WiFi TUI |
| `spotify` | Spotify desktop client |
| `spicetify-cli` | Spotify theme customization |
| `ttf-material-design-icons-webfont` | Material Design icon font for Waybar |
| `zsh-theme-powerlevel10k` | Powerlevel10k prompt (optional use) |
| `wtype` | Types text into Wayland windows programmatically |
| `hyprland-per-window-layout` | Keyboard layout switching per window |
| `makima-bin` | Steam game controller remapping |
| `asdcontrol` | ASUS keyboard backlight control |

---

### packaging/optional.sh

**Location:** `install/packaging/optional.sh`

Prompts the user to install extras that are useful for some but not everyone. Each item is a separate `ask_install` call — the user can pick and choose.

#### `ask_install()`

```bash
ask_install() {
  local pkg="$1"
  local description="$2"

  if command -v gum &>/dev/null; then
    gum confirm "Install $pkg? ($description)" && return 0 || return 1
  else
    read -rp "Install $pkg? ($description) [y/N] " ans
    [[ "${ans,,}" == "y" ]]
  fi
}
```

Uses `gum confirm` for a styled yes/no dialog if `gum` is available (it is, installed in `pacman.sh`). Falls back to a plain `read` prompt otherwise. Returns 0 for yes, 1 for no.

**Optional package groups:**

| Group | Packages |
|---|---|
| Development | nodejs/npm, go, jdk-openjdk, dotnet-runtime |
| Media production | obs-studio, kdenlive, gimp |
| Communication | signal-desktop, vesktop (Discord) |
| Gaming | steam, lutris + wine |
| Virtualization | virt-manager + qemu-full + libvirt |
| AI / ML | ollama, python-onnxruntime |

Virtualization is the only optional item that also enables a service (`libvirtd`) — it must be running for virtual machines to work.
