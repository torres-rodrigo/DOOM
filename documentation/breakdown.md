# Breakdown

---

## `templates/arch_iso/pre_chroot/001_ISO_ORCHESTRA.sh`

This is the **entry point for the entire ISO phase**. It doesn't do any system configuration itself — its sole job is to run the other pre-chroot scripts in the correct order, with safety checks, user control, and error handling. Think of it as a runner script that manages a list of workers.

---

### Shebang & Shell Options

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `#!/usr/bin/env bash` — tells the OS to run this with bash, found via PATH (more portable than hardcoding `/bin/bash`).
- `set -e` — if any command returns a non-zero exit code, the script stops immediately. Prevents silently continuing after a failure.
- `set -u` — treats any reference to an unset variable as an error. Catches typos like `$SCRITPS` instead of `$SCRIPTS`.
- `set -o pipefail` — if a command inside a pipe fails (e.g. `foo | bar`), the whole pipe is treated as failed. Without this, only the exit code of the last command in a pipe is checked.

---

### Working Directory

```bash
cd "$(dirname "$(readlink -f "$0")")"
```

Forces the script to run from the directory it lives in, no matter where you call it from.

- `$0` — the path to this script as given on the command line.
- `readlink -f "$0"` — resolves symlinks and relative paths to an absolute path.
- `dirname "..."` — strips the filename, giving just the directory.
- `cd "..."` — changes into that directory.

**Why this matters:** The main loop calls scripts by filename only (e.g. `bash "002_environment_prep.sh"`). If the working directory isn't the same folder as the scripts, those calls would fail. This line guarantees they're always found.

---

### Install Sequence

```bash
INSTALL_SEQUENCE=(
    "002_environment_prep.sh"
    "003_partitioning.sh"
    "004_disk_mount.sh"
    "005_mirrorlist.sh"
    "006_console_fix.sh"
    "007_pacstrap.sh"
    "008_copy_to_chroot.sh"
    "009_fstab.sh"
)
```

An ordered bash array that defines **what runs and in what order**. This is the only place you need to edit to add, remove, or reorder steps. Each entry is just a filename — the main loop handles finding and executing them.

The numeric prefixes (`002_`, `003_`, ...) are a convention for readability and sorting, not a functional requirement. The actual order is determined by position in this array.

---

### State Tracking Variables

```bash
EXECUTED=()
SKIPPED=()
FAILED=()
AUTO_MODE=0
```

Three arrays and a flag used to track what happened during the run:

- `EXECUTED` — scripts that ran and returned exit code 0 (success).
- `SKIPPED` — scripts that were intentionally not run (missing file, user skipped, or user chose to skip after a failure).
- `FAILED` — scripts that exited with a non-zero code and weren't retried to success. Note: if a script is retried and succeeds, it's moved to `EXECUTED`; if the user chooses to skip after failure, it moves to `SKIPPED` and is removed from `FAILED`.
- `AUTO_MODE=0` — flag for non-interactive mode. `0` means interactive (default), `1` means fully automated.

---

### Auto Mode Detection

```bash
[[ "${1:-}" == "--auto" || "${1:-}" == "-a" ]] && AUTO_MODE=1
```

Checks the first argument passed to the script. If it's `--auto` or `-a`, sets `AUTO_MODE=1`.

- `${1:-}` — reads the first positional argument. The `:-` means "use empty string if unset", preventing a crash under `set -u` when no argument is provided.
- The `&&` means "only run the right side if the left side is true" — a compact if-then without a full `if` block.

---

### Preflight Check

```bash
missing=0
for script in "${INSTALL_SEQUENCE[@]}"; do
    if [[ ! -f "$script" ]]; then
        echo "[MISSING] $script"
        ((++missing))
    fi
done

if ((missing > 0)); then
    read -r -p "$missing script(s) missing. Continue anyway? [y/N]: " choice
    [[ "${choice,,}" != "y" ]] && exit 1
fi
```

Before running anything, scans the entire `INSTALL_SEQUENCE` to check every script file actually exists on disk.

- Counts how many are missing and prints each one.
- If any are missing, asks the user whether to continue anyway. The default answer is **No** (`[y/N]` — capital N means enter/empty = No).
- `${choice,,}` — converts the user's input to lowercase before comparing, so `Y`, `y`, and `YES` all work.
- `[[ ... != "y" ]] && exit 1` — exits if the answer is anything other than `y`.

**Why this matters:** Without this check, you'd only discover a missing script when the orchestrator tries to run it, potentially mid-installation after earlier steps have already made changes to the disk.

---

### Execution Mode Selection

```bash
interactive=1
if ((AUTO_MODE)); then
    interactive=0
    echo "Running in auto mode (no prompts)."
else
    read -r -p "Run interactively (prompt before each)? [Y/n]: " mode
    [[ "${mode,,}" =~ ^(n|no)$ ]] && interactive=0
fi
```

Decides whether the user gets prompted before each individual script runs.

- If `--auto` was passed, `interactive` is set to `0` (no prompts at all).
- Otherwise, asks the user once upfront. Default is **Yes** (`[Y/n]` — capital Y = enter/empty = Yes).
- `=~ ^(n|no)$` — a regex match. Only sets non-interactive if the answer is exactly `n` or `no` (case-insensitive after `,,` lowercasing). Anything else keeps interactive mode.

This gives two levels of control:
1. `--auto` flag: no prompts at all, runs everything.
2. No flag: asks once whether to prompt before each script (interactive) or just run them all in sequence (non-interactive but without the flag).

---

### Main Loop

```bash
total=${#INSTALL_SEQUENCE[@]}
current=0

for script in "${INSTALL_SEQUENCE[@]}"; do
    ((++current))
    ...
done
```

Iterates through every entry in `INSTALL_SEQUENCE`. `total` and `current` exist purely for the progress display (`[1/8]`, `[2/8]`, etc.).

#### Missing file skip

```bash
if [[ ! -f "$script" ]]; then
    echo "[${current}/${total}] SKIP (missing): $script"
    SKIPPED+=("$script")
    continue
fi
```

Even though the preflight already warned about missing files (and the user chose to continue), the loop still checks again before trying to run each one. If missing, it records it in `SKIPPED` and moves on.

#### Interactive prompt

```bash
if ((interactive)); then
    read -r -p "[${current}/${total}] Run $script? [Y/s/q] (proceed/skip/quit): " confirm
    case "${confirm,,}" in
        s|skip) SKIPPED+=("$script"); continue ;;
        q|quit) break ;;
    esac
fi
```

If in interactive mode, asks before each script. Three options:
- **Enter / anything else** — runs the script.
- `s` or `skip` — adds to `SKIPPED` and moves to next script.
- `q` or `quit` — exits the loop entirely (stops the orchestrator, no more scripts run).

#### Script execution & retry loop

```bash
echo "[${current}/${total}] Running: $script"
chmod +x "$script"

while true; do
    set +e
    bash "$script"
    rc=$?
    set -e

    if ((rc == 0)); then
        echo "[OK] $script"
        EXECUTED+=("$script")
        break
    else
        echo "[FAIL] $script (exit $rc)"
        FAILED+=("$script")
        read -r -p "[R]etry, [S]kip, or [A]bort? " action
        case "${action,,}" in
            r|retry) unset 'FAILED[-1]'; continue ;;
            s|skip)  unset 'FAILED[-1]'; SKIPPED+=("$script"); break ;;
            *)       echo "Aborted."; exit "$rc" ;;
        esac
    fi
done
```

This is the core execution block. Key points:

- `chmod +x "$script"` — ensures the script is executable before running it.
- `bash "$script"` — runs the script as a subprocess (not `source`). This means each script gets its own shell environment — variables set inside one script don't leak into the next.
- `set +e` / `set -e` — temporarily disables the "exit on error" behaviour around the script call, so a failing script doesn't kill the orchestrator before it can ask the user what to do. `rc=$?` captures the exit code.
- On **success** (`rc == 0`): records in `EXECUTED`, breaks out of the retry loop.
- On **failure**: three options:
  - `r` / `retry` — `unset 'FAILED[-1]'` removes the last entry from `FAILED` (since we're going to try again), then `continue` goes back to the top of the `while true` loop to run the script again.
  - `s` / `skip` — removes from `FAILED`, adds to `SKIPPED`, breaks out of the retry loop.
  - Anything else (including `a` / `abort`) — exits the entire orchestrator with the same exit code the failed script returned.

---

### Summary

```bash
echo "=== SUMMARY ==="
echo "Executed: ${#EXECUTED[@]}"
((${#SKIPPED[@]} > 0)) && echo "Skipped:  ${SKIPPED[*]}"
((${#FAILED[@]} > 0))  && echo "Failed:   ${FAILED[*]}"
```

---

## `templates/arch_iso/pre_chroot/002_environment_prep.sh`

This is the **first script the orchestrator runs**. Before anything touches the disk, the live ISO environment itself needs to be in a usable state — readable terminal, correct time, a trusted package manager, and a few essential tools. That's all this script does.

---

### Shebang, Comment & Shell Options

```bash
#!/usr/bin/env bash
# Set console font, sync time, init keyring, install base tools
set -euo pipefail
```

Same shebang and `set -euo pipefail` as the orchestrator (see `001` breakdown for the full explanation). The inline comment is just a quick description of what the script does — useful when reading the file without context.

---

### Console Font

```bash
setfont latarcyrheb-sun32 || echo "   (font not available, skipping)"
```

Sets the terminal font in the live ISO environment.

- `setfont` — a Linux utility that loads a console font from the kernel's font table.
- `latarcyrheb-sun32` — a large, high-contrast bitmap font. The `32` refers to its pixel height, making it significantly more readable on HiDPI screens or modern high-resolution displays where the default tiny font is hard to read.
- `|| echo "..."` — the `||` means "run the right side only if the left side fails". If the font file isn't available on this particular ISO (it's optional), the script prints a note and carries on instead of crashing. This is a deliberate graceful fallback — the font is a comfort improvement, not a hard requirement.

---

### NTP Time Sync

```bash
timedatectl set-ntp true
```

Enables automatic clock synchronization over the network using NTP (Network Time Protocol).

- `timedatectl` — systemd's tool for managing the system clock and timezone.
- `set-ntp true` — instructs systemd-timesyncd to start syncing the clock with internet time servers.

**Why this matters more than it looks:** If the system clock is wrong, several things break silently:
- **TLS/SSL certificates** have validity windows. A clock that's off by even a day can cause `curl`, `wget`, and package downloads to reject perfectly valid certificates with a "certificate not yet valid" or "certificate expired" error.
- **Pacman's signature verification** checks that package signatures were created at a reasonable time. A skewed clock can cause signature validation failures.
- **`/mnt/etc/fstab`** timestamps from `genfstab` would be wrong, causing confusion when diagnosing issues later.

---

### Pacman Keyring Initialization

```bash
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm archlinux-keyring
pacman -Syy --noconfirm
```

This block initializes and refreshes pacman's cryptographic trust chain. It's four steps with a specific reason for each:

#### `pacman-key --init`

Creates a fresh GPG keyring for pacman from scratch. The live ISO ships with a keyring that may be months old. This command:
- Generates a new master signing key for this machine.
- Sets up the keyring directory structure (`/etc/pacman.d/gnupg/`).

Without this, the next commands have nowhere to put keys.

#### `pacman-key --populate archlinux`

Imports the official Arch Linux developer and trusted-user public keys into the keyring, then cross-signs them with the local master key created above.

This is what gives pacman the ability to verify that a package like `linux-6.x.tar.zst` was actually signed by an Arch developer and hasn't been tampered with. Without this, every package download would be untrusted.

#### `pacman -Sy --noconfirm archlinux-keyring`

Downloads and installs the latest `archlinux-keyring` package. This is necessary because:
- The ISO might be 6–12 months old.
- Arch developers rotate keys, add new trusted users, and revoke old keys regularly.
- An outdated keyring means some recently-signed packages will fail signature verification even though they're legitimate.

`-Sy` = sync (download) the package database (`-S`) and refresh it first (`y`).

#### `pacman -Syy --noconfirm`

Forces a **full refresh** of all package databases from the configured mirrors.

- `-S` = sync operation.
- `-yy` = double-`y` forces re-download of the database even if pacman thinks it's already up to date. This is important on a fresh ISO where the cached database may be stale.

After this command, pacman knows about all currently available packages and their latest versions.

---

### Install Base Tools

```bash
pacman -S --needed --noconfirm neovim git curl
```

Installs three tools into the live ISO environment that are used during the installation process itself.

- `--needed` — skip any package that's already installed at the correct version. Avoids redundant reinstalls since the ISO may already include some of these.
- `--noconfirm` — suppresses the "Proceed with installation? [Y/n]" prompt. Safe here because we've already synced the database and know what we're installing.

**Why each tool:**
- `neovim` — a text editor. During installation, you may need to manually inspect or edit config files (e.g. peek at `/mnt/etc/fstab`, edit a broken config). The ISO's default `vi` is often minimal; `nvim` is more usable.
- `git` — needed to clone the project repo into the live environment if it isn't already there. Also used by `008_copy_to_chroot.sh` to have the full project available before chroot.
- `curl` — a general-purpose HTTP tool for downloading files, checking connectivity, or fetching scripts. Useful as a diagnostic tool and potentially needed by other steps.

---


## `templates/arch_iso/pre_chroot/003_partitioning.sh`

This script handles **disk partitioning** — the step where you carve up your drive into the sections the system needs. Unlike every other script in the chain, this one is almost entirely interactive by design. It cannot be automated because it needs a human to make decisions about their own hardware. It acts as a guided wrapper around `cfdisk`, a terminal-based partitioning tool.

---

### UEFI vs BIOS Detection

```bash
if [[ -d /sys/firmware/efi/efivars ]]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi
```

Detects how the machine actually booted — UEFI or legacy BIOS — by checking for the existence of a specific directory.

- `/sys/firmware/efi/efivars` — this is a special virtual filesystem that the Linux kernel only creates when it boots via UEFI. It exposes UEFI variables from the motherboard firmware (things like boot order entries, secure boot state, etc.). If this directory exists, the machine is in UEFI mode. If it doesn't exist at all, it booted in legacy BIOS mode.

**Why this check matters:** UEFI and BIOS require fundamentally different partition layouts and bootloaders. Getting this wrong means the system won't boot. By detecting it upfront, the script can show the correct instructions and the rest of the ISO chain (`007_systemd_boot.sh` vs `008_grub.sh`) can make the right choices downstream.

---

### Partition Instructions

```bash
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    echo "Required partitions:"
    echo "  1. EFI Partition:  >= 512MB  (Type: EFI System)"
    echo "  2. Root Partition: >= 15GB   (Type: Linux Filesystem)"
else
    echo "Required partitions (GPT):"
    echo "  1. BIOS Boot: 1MB exact      (Type: BIOS Boot)"
    echo "  2. Root Partition: >= 15GB    (Type: Linux Filesystem)"
    echo "For MBR/DOS: just create one Linux partition."
fi
```

Prints what partitions need to be created before the user opens `cfdisk`. Different requirements for each boot mode:

**UEFI layout:**
- **EFI System Partition (ESP)** — a FAT32 partition where the bootloader (`systemd-boot` in this setup) installs itself and stores boot entries. The firmware reads this partition directly at startup. Must be typed as "EFI System" in cfdisk so the firmware recognizes it. 512MB is the recommended minimum; larger is fine.
- **Root partition** — where the OS lives. Typed as "Linux Filesystem". This is where BTRFS with the `@` and `@home` subvolumes will be created in the next script.

**BIOS/GPT layout:**
- **BIOS Boot partition** — a tiny 1MB partition with **no filesystem**. When a GPT-partitioned disk is used with a BIOS system, there is no MBR gap (the traditional 512-byte region after the master boot record where GRUB wrote its stage 2 bootloader). This 1MB partition serves as a substitute for that gap — GRUB writes its core image directly into it. Must be exactly 1MB; no more, no less.
- **Root partition** — same as UEFI.

**BIOS/MBR (DOS) layout:**
- With an old-style MBR partition table, the traditional boot gap still exists, so GRUB doesn't need a dedicated BIOS Boot partition. One Linux partition is enough.

---

### Safety Note & Pause

```bash
echo "NOTE: Data is safe until you select [Write] inside cfdisk."
read -r -p "Press [Enter] to list drives..." _
```

Reassures the user before showing drives, then pauses to let them read the instructions before continuing.

- The note is important: `cfdisk` only commits changes when you explicitly choose `[Write]` from its menu. Just opening it and navigating around doesn't touch the disk. This is not obvious to someone who hasn't used it before.
- `read -r -p "..." _` — the `_` is just a throwaway variable name for the input. The user just hits Enter; the value is discarded. It's a common convention for "pause and wait for any key".
- `-r` — raw mode, disables backslash interpretation. Without it, a user typing `\n` would be treated as a literal newline instead of two characters.

---

### Drive Selection Loop

```bash
while true; do
    ...
done
```

A `while true` loop that repeats the entire selection and partitioning process until the user is satisfied with the result. The only exits are `break` (accepted) or the script being aborted. This means the user can re-run `cfdisk` as many times as they need to get the layout right.

#### Listing available drives

```bash
lsblk -d -e 7,11 -o NAME,SIZE,MODEL,TYPE
```

Displays a clean list of drives (not partitions) for the user to pick from.

- `-d` — show only whole disks, not their individual partitions. Without this, you'd see `nvme0n1`, `nvme0n1p1`, `nvme0n1p2`, etc. — cluttered and confusing when you just need to pick a drive.
- `-e 7,11` — exclude device types by number. `7` = loop devices (used by snap packages and mounted ISOs — not real disks), `11` = optical drives (CD/DVD — not relevant for installation). Without this, `loop0`, `loop1`, `sr0` etc. would appear in the list.
- `-o NAME,SIZE,MODEL,TYPE` — show only these four columns instead of the default verbose output. Makes it easy to identify the right drive by model name and size.

#### Input sanitization

```bash
read -r -p "Drive to partition (e.g. nvme0n1 or sda): " DRIVE_INPUT
TARGET_DEV="/dev/${DRIVE_INPUT#/dev/}"
```

Accepts the user's input and constructs a valid `/dev/` path regardless of how they typed it.

- `${DRIVE_INPUT#/dev/}` — this is bash's **prefix stripping** syntax. The `#` means "strip the shortest match of the following pattern from the start of the variable". So:
  - If the user typed `nvme0n1` → strips nothing → result is `nvme0n1`
  - If the user typed `/dev/nvme0n1` → strips `/dev/` → result is `nvme0n1`
- Then `/dev/` is prepended back, so in both cases `TARGET_DEV` becomes `/dev/nvme0n1`. The user can type either form and it works correctly.

#### Block device validation

```bash
if [[ -b "$TARGET_DEV" ]]; then
    ...
else
    echo "Device '$TARGET_DEV' not found. Try again."
fi
```

- `-b "$TARGET_DEV"` — tests whether the path exists **and** is a block device (as opposed to a regular file, directory, or character device). If the user typed a typo or a name that doesn't exist, `-b` returns false and the loop simply prints an error and restarts, asking for a drive name again.

#### Launching cfdisk

```bash
cfdisk "$TARGET_DEV" < /dev/tty > /dev/tty 2>&1
```

Opens `cfdisk`'s full-screen partition editor for the chosen drive. The TTY redirections are the critical and non-obvious part:

- `cfdisk` is a **TUI** (terminal user interface) — it takes over the entire terminal, draws menus, and responds to keyboard input. It requires a real terminal to function.
- When scripts are run from within the orchestrator using `bash "$script"`, stdin and stdout may be connected to a pipe rather than the actual terminal. `cfdisk` would fail to render or receive input in that situation.
- `< /dev/tty` — forces stdin to come directly from the physical terminal (`/dev/tty` always refers to the controlling terminal of the current process), bypassing any pipe. This is what lets `cfdisk` receive arrow keys and Enter.
- `> /dev/tty` — forces stdout to go directly to the physical terminal, bypassing any pipe. This is what lets `cfdisk` draw its UI on screen.
- `2>&1` — redirects stderr to wherever stdout is currently pointing (the terminal), so error messages from `cfdisk` also appear on screen.

#### Post-cfdisk layout display

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE "$TARGET_DEV"
```

After the user exits `cfdisk`, shows the resulting partition table for the chosen drive so they can verify the layout looks correct before confirming.

Unlike the earlier `lsblk` command, this one:
- Has no `-d` flag — so it shows the drive **and** its partitions.
- Scoped to just `$TARGET_DEV` — only shows the one drive that was just partitioned, not every device on the system.
- Adds `FSTYPE` column — shows whether any existing filesystems are already on the partitions (useful for rescue scenarios).

#### Confirmation

```bash
read -r -p "Happy with this layout? [Y/n]: " confirm
[[ "${confirm,,}" =~ ^(n|no)$ ]] && continue
break
```

Asks the user to confirm the layout.

- `${confirm,,}` — lowercases the input.
- `=~ ^(n|no)$` — regex match. Only triggers a redo on an explicit `n` or `no`. Anything else — including just pressing Enter — is treated as yes.
- `continue` — jumps back to the top of the `while true` loop, restarting from the drive listing. The user can re-open `cfdisk` and redo the partitioning.
- `break` — exits the loop entirely. The script ends with `echo ">> Partitioning complete."` and returns control to the orchestrator, which moves on to `004_disk_mount.sh`.

Printed after the loop ends (either all scripts ran, or the user quit).

- `${#EXECUTED[@]}` — the count of elements in the array.
- `${SKIPPED[*]}` — all elements joined by spaces (the full list of skipped script names).
- The `Skipped` and `Failed` lines only print if those arrays are non-empty, keeping the output clean when everything succeeded.

## `templates/arch_iso/pre_chroot/004_disk_mount.sh`

This script does the heaviest lifting in the pre-chroot phase. It formats the partitions, creates the BTRFS subvolume structure, and mounts everything at `/mnt` — which is the target the rest of the install writes into. After this script completes, the installer has a fully prepared filesystem ready to receive the base system.

---

### Helper Functions

Two small utility functions are defined at the top before anything else runs, so they're available throughout the script.

#### `sanitize_dev`

```bash
sanitize_dev() {
    local input="${1#/dev/}"
    echo "/dev/$input"
}
```

Same input-normalisation logic as in `003`, but here it's been extracted into a named function rather than repeated inline — because it's called twice (once for the ROOT partition, once for the EFI partition).

- `local input` — `local` scopes the variable to inside the function only. It won't leak into or overwrite anything in the outer script.
- `${1#/dev/}` — strips the `/dev/` prefix from the first argument if it's there. If it isn't, nothing is stripped.
- The result always starts with `/dev/`, regardless of what the user typed.

#### `is_ssd`

```bash
is_ssd() {
    local parent
    parent=$(lsblk -no PKNAME "$1" | head -n1)
    [[ "$(cat "/sys/block/$parent/queue/rotational" 2>/dev/null)" == "0" ]]
}
```

Detects whether a given partition lives on a solid-state drive. The return value is the exit code of the `[[ ]]` test — `0` (true) for SSD, `1` (false) for HDD — so it can be used directly in `if is_ssd ...; then`.

- `lsblk -no PKNAME "$1"` — given a partition like `/dev/nvme0n1p2`, gets the name of the parent disk. `-n` suppresses the header row, `-o PKNAME` outputs only the "parent kernel name" column. Result: `nvme0n1`.
- `head -n1` — takes only the first line in case `lsblk` returns multiple results.
- `/sys/block/<disk>/queue/rotational` — a file exposed by the Linux kernel's sysfs virtual filesystem. It contains a single character: `0` if the device doesn't rotate (SSD or NVMe), `1` if it does (spinning hard disk). This is the most reliable way to detect an SSD from a script.
- `2>/dev/null` — suppresses any errors from `cat` if the file doesn't exist (e.g. on unusual hardware or virtual machines).

---

### UEFI / BIOS Detection

```bash
if [[ -d /sys/firmware/efi/efivars ]]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi
```

Identical to `003_partitioning.sh`. Each script re-detects independently rather than relying on a variable passed from the orchestrator — because scripts run as separate subprocesses, they don't share environment state.

---

### Pre-flight Unmount

```bash
umount -R /mnt 2>/dev/null || true
```

Wipes the slate clean before doing anything else. If a previous run of this script or manual mounting left filesystems mounted under `/mnt`, this removes them all first.

- `-R` — recursive. Unmounts `/mnt` and every filesystem mounted beneath it (`/mnt/home`, `/mnt/boot`, etc.) in the correct order.
- `2>/dev/null` — discards the "not mounted" error message if `/mnt` was never mounted. Without this you'd see an error on a clean system.
- `|| true` — prevents `set -e` from aborting the script if `umount` exits non-zero (which it will if nothing was mounted). The goal is just "make sure nothing is mounted", not "fail if nothing was mounted".

---

### Partition Selection

#### ROOT partition

```bash
while true; do
    read -rp "ROOT partition (e.g. nvme0n1p2): " raw_root
    ROOT_PART=$(sanitize_dev "$raw_root")
    [[ -b "$ROOT_PART" ]] && break
    echo "Invalid device: $ROOT_PART"
done
```

Loops until the user provides a valid block device for the root partition. The pattern is the same as `003`: sanitize the input, test with `-b`, break on success or print an error and retry. The loop means a typo doesn't abort the script — it just asks again.

#### EFI partition (UEFI only)

```bash
ESP_PART=""
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    while true; do
        read -rp "EFI partition (e.g. nvme0n1p1): " raw_esp
        ESP_PART=$(sanitize_dev "$raw_esp")
        [[ "$ESP_PART" == "$ROOT_PART" ]] && echo "EFI cannot be ROOT." && continue
        [[ -b "$ESP_PART" ]] && break
        echo "Invalid device: $ESP_PART"
    done
fi
```

- `ESP_PART=""` — initialised to empty string so that BIOS systems have a defined (empty) value for the `${ESP_PART:+...}` expansion used later. Without this, referencing it under `set -u` would crash the script.
- The loop adds one extra check not present in the ROOT loop: `[[ "$ESP_PART" == "$ROOT_PART" ]] && ... && continue`. This prevents the user from accidentally specifying the same partition for both roles. If they match, it prints a message and `continue`s — going back to the top of the `while true` to ask again.
- The `&&` chain on that line runs left to right: if the equality check is true, run the echo, then run continue. All three only execute if the first condition is true.

---

### Format or Mount Branch

```bash
read -r -p "FORMAT these partitions? (n = mount existing) [y/N]: " fmt_choice
if [[ "${fmt_choice,,}" =~ ^(y|yes)$ ]]; then
    ...
else
    ...
fi
```

The script has two paths here: **format** (fresh install) or **mount existing** (rescue / resume a previous attempt). The default is **No** — the capital `N` in `[y/N]` signals that pressing Enter without typing anything is treated as no. You must explicitly type `y` or `yes` to format.

#### Double confirmation

```bash
read -r -p "Confirm FORMAT (data will be wiped)? [y/N]: " confirm
[[ "${confirm,,}" != "y" ]] && exit 1
```

A second prompt specifically for the destructive path. This one is intentionally stricter — it only accepts exactly `y` (after lowercasing). Anything else — including `yes`, an empty Enter, or any other input — exits the script with code `1`. You have to be deliberate.

#### Formatting the EFI partition

```bash
[[ "$BOOT_MODE" == "UEFI" ]] && mkfs.fat -F 32 -n "EFI" "$ESP_PART"
```

- Only runs on UEFI systems (no EFI partition on BIOS).
- `mkfs.fat -F 32` — formats as FAT32. The UEFI specification requires the ESP to be FAT32; FAT12 and FAT16 are not valid.
- `-n "EFI"` — sets the volume label to `"EFI"`. Purely cosmetic — it appears in tools like `lsblk -f` and file managers, but has no functional effect.

#### Formatting the ROOT partition as BTRFS

```bash
mkfs.btrfs -f -L "ROOT" "$ROOT_PART"
```

- `mkfs.btrfs` — creates a BTRFS filesystem.
- `-f` — force. Without this, `mkfs.btrfs` refuses to overwrite an existing filesystem and asks for confirmation. Since the user has already confirmed twice, forcing here is intentional.
- `-L "ROOT"` — sets the filesystem label to `"ROOT"`. Used later by `genfstab` and visible in `lsblk`.

#### Creating BTRFS subvolumes

```bash
mount -t btrfs "$ROOT_PART" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt
```

This is a two-mount process. To create subvolumes, you first mount the raw partition without specifying any subvolume — this gives you access to the BTRFS "top-level" namespace where subvolumes live.

- `mount -t btrfs "$ROOT_PART" /mnt` — mounts the bare BTRFS partition (no subvolume specified). The `-t btrfs` explicitly specifies the filesystem type.
- `btrfs subvolume create /mnt/@` — creates a subvolume named `@` at the top level. By convention, `@` maps to the root `/` of the installed system.
- `btrfs subvolume create /mnt/@home` — creates a subvolume named `@home`. By convention, `@home` maps to `/home`.
- `umount /mnt` — unmounts the temporary top-level mount. The subvolumes are now permanently part of the BTRFS filesystem and will be mounted properly with their own options in the next block.

**Why separate subvolumes for `/` and `/home`?** Each subvolume can be snapshotted, restored, and configured independently. Taking a system snapshot before an upgrade doesn't need to capture your entire home directory. And if you want to reinstall the OS, you can wipe and recreate `@` while leaving `@home` and all your personal data untouched.

#### Mount existing path

```bash
read -r -p "Proceed with MOUNTING existing system? [Y/n]: " confirm
[[ "${confirm,,}" =~ ^(n|no)$ ]] && exit 1
```

The non-destructive path — for mounting a previously installed system (e.g. re-running the script after an interrupted install). Default is **Yes**. Only exits if the user explicitly says `n` or `no`.

---

### BTRFS Mount Options

```bash
BTRFS_OPTS="rw,noatime,compress=zstd:3,space_cache=v2"
if is_ssd "$ROOT_PART"; then
    echo ">> SSD detected. Adding ssd,discard=async."
    BTRFS_OPTS+=",ssd,discard=async"
fi
```

A string of comma-separated mount options built up before any mounting happens. `+=` appends to the existing string. Each option explained:

- `rw` — mounts read-write. Technically the default but stated explicitly for clarity.
- `noatime` — disables access time updates. Normally Linux writes a new timestamp to a file's metadata every time it is read. On BTRFS (a copy-on-write filesystem) every metadata write triggers CoW overhead. `noatime` eliminates these writes entirely, reducing write amplification and improving read performance with no meaningful downside.
- `compress=zstd:3` — enables transparent, automatic compression on all new data using the zstd algorithm at level 3. Files are compressed before being written to disk and decompressed on read, completely invisibly to applications. Level 3 is a deliberate middle ground: noticeably better compression ratios than the default level 1, without the high CPU cost of levels 6+. Files that are already compressed (images, videos, archives) are detected and stored uncompressed automatically by BTRFS.
- `space_cache=v2` — BTRFS tracks which disk blocks are free using an in-memory cache, which it also persists to disk. Version 2 of this cache is a complete rewrite of v1, which had known correctness bugs. v2 is faster, more reliable, and the current recommendation.
- `ssd` (SSD only) — activates BTRFS's SSD-aware block allocator. On HDDs, BTRFS tries to keep related data physically close together to reduce seek time. On SSDs there are no seeks, so this hint lets BTRFS use a different allocation strategy better suited to flash storage.
- `discard=async` (SSD only) — enables asynchronous TRIM. When the filesystem deletes data, it eventually needs to tell the SSD which blocks are now free (so the drive's firmware can clean and recycle them for future writes). `async` means these TRIM commands are batched and sent in the background rather than blocking each individual delete. This gives SSDs the information they need for wear leveling and garbage collection without any noticeable impact on delete performance.

---

### Mounting Everything

#### Root subvolume

```bash
mount -o "${BTRFS_OPTS},subvol=@" "$ROOT_PART" /mnt
```

Mounts the `@` subvolume at `/mnt`. The `subvol=@` option tells BTRFS which subvolume to present as the root of this mount. All the optimized options from `$BTRFS_OPTS` apply. `/mnt` is the conventional install target in the Arch live ISO.

#### Creating mount point directories

```bash
mkdir -p /mnt/{home,boot}
```

Bash **brace expansion** — `{home,boot}` expands to two separate arguments, making this equivalent to `mkdir -p /mnt/home /mnt/boot`. The `-p` flag creates directories without erroring if they already exist.

These directories must exist before the next two mounts can use them as mount points.

#### Home subvolume

```bash
mount -o "${BTRFS_OPTS},subvol=@home" "$ROOT_PART" /mnt/home
```

Mounts the `@home` subvolume at `/mnt/home` with the same options. Notice it's the same physical partition (`$ROOT_PART`) mounted a second time but presenting a different subvolume — BTRFS supports multiple concurrent mounts of the same partition, each showing a different subvolume.

#### EFI partition

```bash
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    mount "$ESP_PART" /mnt/boot
fi
```

Mounts the FAT32 ESP at `/mnt/boot` with no special options — the kernel's `vfat` driver uses sensible defaults. This is where `systemd-boot` will install itself in `007_systemd_boot.sh`, and where the kernel image and initramfs will live.

---

### Final Verification

```bash
lsblk -f "$ROOT_PART" ${ESP_PART:+"$ESP_PART"}
```

Prints a summary of the mounted filesystems so the user can verify everything looks right before the orchestrator moves on.

- `-f` — shows filesystem type, label, UUID, and mount points for each device.
- `${ESP_PART:+"$ESP_PART"}` — the `:+` operator is bash's **conditional expansion**: "if `$ESP_PART` is set and non-empty, substitute `"$ESP_PART"`; otherwise substitute nothing". On a BIOS system `ESP_PART` is an empty string, so nothing extra is passed to `lsblk`. On a UEFI system it expands to the EFI device path, so both the root and EFI partitions appear in the output.

---

## `templates/arch_iso/pre_chroot/005_mirrorlist.sh`

This script updates pacman's mirror list — the ranked list of servers that packages get downloaded from. A good mirror list means faster downloads throughout the entire installation. It uses `reflector`, a tool that fetches, filters, and benchmarks Arch mirrors automatically.

---

### Reflector Availability Check

```bash
if ! command -v reflector &>/dev/null; then
    echo ">> Installing reflector..."
    pacman -S --needed --noconfirm reflector
fi
```

Before using `reflector`, checks whether it's already installed and installs it if not.

- `command -v reflector` — a bash builtin that searches PATH for an executable named `reflector` and prints its path if found. It's preferred over `which` because `which` is an external binary and can behave differently across systems, while `command` is always built into bash.
- `&>/dev/null` — shorthand for `>/dev/null 2>&1`. Redirects both stdout (the path that `command -v` would print) and stderr to `/dev/null`, silencing all output. We only care about the exit code.
- `if !` — inverts the test. The block runs only if `reflector` is **not** found.

The live Arch ISO doesn't include `reflector` by default, so this check and install will almost always trigger on a fresh ISO boot.

---

### Country Code Input

```bash
read -r -p "Country code for mirrors (e.g. US, DE, IN) [leave empty for global]: " COUNTRY
```

Asks the user for an optional country code to restrict mirror selection geographically.

- If the user types a country code (e.g. `PT`, `US`, `DE`), only mirrors from that country are considered — these will generally be the fastest since they're physically closer.
- If the user just presses Enter, `COUNTRY` is set to an empty string and reflector searches globally. Global mode casts a wider net but the speed benchmark (`--sort rate`) still ensures fast mirrors are chosen.

---

### Reflector Arguments Array

```bash
REFLECTOR_ARGS=(
    --protocol https
    --age 12
    --sort rate
    --save /etc/pacman.d/mirrorlist
)
```

Builds the base set of arguments as a bash **array** rather than a plain string. This is the correct pattern for constructing command arguments dynamically — array elements are always properly quoted and space-safe when expanded with `"${REFLECTOR_ARGS[@]}"`.

Each argument explained:

- `--protocol https` — only include mirrors that serve over HTTPS. Excludes plain HTTP mirrors. Even though pacman verifies package signatures cryptographically, HTTPS adds a layer of transport security that prevents ISPs or attackers from seeing which packages you're downloading or injecting modified data mid-transfer.
- `--age 12` — only consider mirrors that have been synced within the last 12 hours. Arch packages are released continuously; a mirror that synced 2 days ago could be serving outdated package databases, causing `pacman` to see packages that don't actually exist on that server yet. 12 hours is a reasonable freshness window.
- `--sort rate` — benchmark each candidate mirror by download speed and rank them fastest-first. This is what makes the generated mirrorlist actually useful — without it, mirrors would be in arbitrary order and you might end up downloading from a slow server on the other side of the world.
- `--save /etc/pacman.d/mirrorlist` — write the result directly to the mirrorlist file, overwriting whatever was there. Without this flag, `reflector` prints to stdout and nothing is saved.

---

### Conditional Country Append

```bash
if [[ -n "$COUNTRY" ]]; then
    REFLECTOR_ARGS+=(--country "$COUNTRY")
    echo ">> Fetching best mirrors for: $COUNTRY"
else
    echo ">> Fetching best mirrors globally..."
fi
```

Adds the `--country` flag to the arguments array only if the user provided one.

- `[[ -n "$COUNTRY" ]]` — the `-n` test checks that the string is **non-zero length** (non-empty). True if the user typed something, false if they pressed Enter without input.
- `REFLECTOR_ARGS+=(--country "$COUNTRY")` — **array append** syntax. Adds two new elements to the end of the existing array: the flag `--country` and the value `"$COUNTRY"`. Adding them as separate elements (not concatenated into one string) is important — the command expects `--country PT`, not `--countryPT`.

---

### Running Reflector

```bash
reflector "${REFLECTOR_ARGS[@]}"
```

Executes reflector with all the assembled arguments.

- `"${REFLECTOR_ARGS[@]}"` — the `[@]` expands the array to its individual elements, each separately quoted. This is the safe way to pass an array as command arguments. If you used `"${REFLECTOR_ARGS[*]}"` instead, all elements would be joined into a single string, breaking multi-word arguments.

Reflector connects to the Arch mirror status API, filters by age and protocol, downloads a test file from each candidate to measure speed, ranks them, and writes the result to `/etc/pacman.d/mirrorlist`. This can take 30–60 seconds depending on network speed and how many mirrors are being tested.

---

### Verification Output

```bash
echo "[OK] Mirrorlist updated."
echo ">> Top 5 mirrors:"
head -7 /etc/pacman.d/mirrorlist
```

After reflector completes, prints the top of the generated mirrorlist for visual confirmation.

- `head -7` — prints the first 7 lines of the file. The mirrorlist starts with a few comment lines (generated by reflector, showing timestamp and the options used), followed by the ranked `Server =` entries. 7 lines captures the header comments and the first 1–2 mirrors, which is enough to verify reflector ran successfully and the file isn't empty.

---

## `templates/arch_iso/pre_chroot/006_console_fix.sh`

This is the shortest script in the chain. Its only job is to write a single keyboard layout configuration file into the new system before `pacstrap` runs. It has no interactive prompts and no branching logic.

---

### Writing vconsole.conf

```bash
mkdir -p /mnt/etc
echo "KEYMAP=us" > /mnt/etc/vconsole.conf
```

Creates the virtual console configuration file for the installed system.

- `mkdir -p /mnt/etc` — creates `/mnt/etc` if it doesn't exist yet. At this point in the sequence `pacstrap` hasn't run, so the directory structure under `/mnt` may be incomplete. `-p` prevents an error if the directory already exists (idempotent).
- `echo "KEYMAP=us" > /mnt/etc/vconsole.conf` — writes a single line to the file, creating it if it doesn't exist or overwriting it if it does. `>` is a plain redirect, not append (`>>`).

**What `vconsole.conf` does:** This file is read by `systemd-vconsole-setup.service` at boot time to configure the virtual console — the text-mode terminal you see before a display manager starts. `KEYMAP=us` sets the keyboard layout to US. Without this file, the console defaults to whatever the kernel compiled in (usually US anyway, but not guaranteed).

**Why write to `/mnt/etc/` and not `/etc/`:** Everything under `/mnt` is the new system being built. `/etc/vconsole.conf` would configure the live ISO's console — which is already running and irrelevant. Writing to `/mnt/etc/vconsole.conf` means the file will be present in the installed system after reboot.

**Why is this hardcoded to `us`?** This is a template — the expectation is that the person adapting it changes this value if they need a different layout. For a DOOM-style project targeting a specific user, hardcoding a known layout is simpler than adding an interactive prompt for a setting that almost never changes. The equivalent interactive version would be something like `localectl list-keymaps` piped to `fzf`.

---

## `templates/arch_iso/pre_chroot/007_pacstrap.sh`

This script installs the base Arch Linux system into `/mnt`. It's the moment the target disk goes from a blank formatted filesystem to something that can actually boot. Every package installed here is the absolute minimum needed for a functioning, bootable system — everything else is installed later in the post-chroot phase.

---

### Mount Verification

```bash
MOUNT_POINT="/mnt"

if ! mountpoint -q "$MOUNT_POINT"; then
    echo "[ERROR] $MOUNT_POINT is not mounted. Mount partitions first."
    exit 1
fi
```

A hard guard before anything runs. If `/mnt` isn't mounted, `pacstrap` would silently install the entire base system into the live ISO's root filesystem — a serious mistake that would pollute the running ISO and install nothing useful.

- `mountpoint` — checks whether a path is an active mount point. Unlike checking `[[ -d /mnt ]]`, which would pass even when nothing is mounted there (the directory always exists on the ISO), `mountpoint` checks the kernel's actual mount table.
- `-q` — quiet mode, suppresses output. We only care about the exit code: `0` if mounted, `1` if not.
- `exit 1` — exits with a non-zero code, which the orchestrator's `set -e` will catch, treating this script as failed and offering the retry/skip/abort prompt.

---

### Base Package Array

```bash
PACKAGES=(
    base base-devel linux linux-headers linux-firmware
    neovim btrfs-progs dosfstools git
    networkmanager yazi
)
```

The minimum set of packages for a working, bootable, network-connected system. Each one earns its place:

- `base` — a package group containing the absolute essentials that define an Arch Linux installation: `systemd`, `glibc`, `bash`, `coreutils`, `util-linux`, `shadow`, and more. Without this, nothing functions.
- `base-devel` — another package group: `gcc`, `make`, `binutils`, `patch`, `pkgconf`, `autoconf`, etc. Required for compiling packages from source. If you ever install anything from the AUR (which requires building from source), you need this.
- `linux` — the Linux kernel itself. The actual kernel binary, loadable modules, and related files that go into `/boot`.
- `linux-headers` — kernel header files. Required by DKMS-based drivers (like the proprietary NVIDIA driver, VirtualBox guest additions, etc.) that compile kernel modules on-the-fly.
- `linux-firmware` — a large collection of firmware blobs for hardware: WiFi cards, Bluetooth, GPUs, SSDs, and more. Without this, many devices simply won't initialise at boot.
- `neovim` — a text editor available immediately after entering the chroot, for editing configuration files during the post-chroot phase.
- `btrfs-progs` — userspace utilities for the BTRFS filesystem (`btrfs`, `btrfsck`, `btrfs-convert`, etc.). Since the root filesystem is BTRFS, these are required — the kernel knows BTRFS but the management tools live in userspace.
- `dosfstools` — tools for FAT/FAT32 filesystems (`mkfs.fat`, `fsck.fat`). Required for managing the EFI partition after reboot.
- `git` — version control. Needed to clone repos after the system is booted.
- `networkmanager` — the network management daemon. Without this, the new system has no way to connect to the internet after rebooting. It handles both ethernet and WiFi, and its `nmtui` provides a simple terminal interface.
- `yazi` — a terminal file manager. Less essential than the others but useful for navigating the filesystem during setup; included as a quality-of-life tool for this project.

---

### CPU Microcode Detection

```bash
CPU_VENDOR=$(awk -F': ' '/^vendor_id/{print $2; exit}' /proc/cpuinfo)
```

Reads the CPU vendor string from the kernel's CPU information file to decide which microcode package to install.

- `/proc/cpuinfo` — a virtual file maintained by the kernel, updated in real time, containing detailed information about every CPU core. On a 12-core system, it has 12 sections — but they all report the same vendor, so we only need the first match.
- `awk -F': '` — sets the field separator to `": "` (colon followed by a space). Lines in `/proc/cpuinfo` look like `vendor_id	: GenuineIntel`, which splits into field 1 (`vendor_id`) and field 2 (`GenuineIntel`).
- `/^vendor_id/` — matches only lines whose content starts with `vendor_id`.
- `{print $2; exit}` — prints the second field (the actual vendor string) and immediately stops processing. The `exit` is important — without it, awk would continue reading all remaining lines and potentially print the vendor for every CPU core.

```bash
case "$CPU_VENDOR" in
    GenuineIntel)
        echo ">> CPU: Intel - adding intel-ucode"
        PACKAGES+=("intel-ucode")
        ;;
    AuthenticAMD)
        echo ">> CPU: AMD - adding amd-ucode"
        PACKAGES+=("amd-ucode")
        ;;
    *)
        echo ">> CPU: Unknown vendor ($CPU_VENDOR)"
        ;;
esac
```

- `GenuineIntel` and `AuthenticAMD` are not display names — they are the exact strings that Intel and AMD CPUs expose in the `CPUID` instruction and which the kernel reports verbatim. Matching against these strings is reliable.
- **Microcode** is low-level firmware that runs inside the CPU itself, sitting below the OS and everything else. CPU manufacturers release microcode updates to fix errata (hardware bugs) and security vulnerabilities like Spectre, MDS, and others. The bootloader loads the microcode update from the initramfs into the CPU during early boot, before any userspace code runs.
- `PACKAGES+=("intel-ucode")` — appends a single element to the array. Note the quotes around the package name and the parentheses — this is the array append syntax. Without parentheses, `+=` would perform string concatenation, corrupting the array.
- `*)` — the catch-all pattern. On a VM, unusual hardware, or non-x86 CPU, the vendor string won't match either known value. The script prints an informational note and continues — not having microcode is acceptable; it just means the CPU won't receive firmware updates during boot.

---

### Package List Display & Confirmation

```bash
echo "Packages to install:"
printf '  %s\n' "${PACKAGES[@]}"
echo ""

read -r -p "Run pacstrap? [Y/n]: " confirm
if [[ "${confirm,,}" =~ ^(n|no)$ ]]; then
    echo "Aborted."
    exit 0
fi
```

Prints the complete final package list before doing anything, then asks for confirmation.

- `printf '  %s\n' "${PACKAGES[@]}"` — prints each package on its own indented line. More controlled than `echo "${PACKAGES[@]}"` which would print everything space-separated on one long line. The format string `'  %s\n'` is applied once per argument when multiple arguments are passed to `printf`.
- `exit 0` on abort — exits cleanly with success code (`0`) rather than failure (`1`). The user chose to skip, not a failure. The orchestrator sees it as a completed step and moves on.

---

### Running pacstrap

```bash
pacstrap -K "$MOUNT_POINT" "${PACKAGES[@]}" --needed
```

The core command that actually installs the system.

- `pacstrap` — an Arch-specific tool for bootstrapping a new system. Unlike `pacman`, which installs into the running system's root, `pacstrap` targets a specified directory — treating it as the root of the installation target.
- `-K` — initialises a new, independent pacman keyring inside the target system at `/mnt/etc/pacman.d/gnupg/`. This is separate from the live ISO's keyring. Without it, the installed system would have no keyring and `pacman` would refuse to install anything after first boot.
- `"${PACKAGES[@]}"` — the full package array, expanded as individual quoted arguments.
- `--needed` — skips packages that are already installed at the current version in the target. Makes the command safely re-runnable if the installation was interrupted partway through.

---

## `templates/arch_iso/pre_chroot/008_copy_to_chroot.sh`

This script copies the project files from the live ISO into the new system at `/mnt`, so they're available inside the chroot environment. Without this step, you'd enter `arch-chroot /mnt` and have no scripts to run.

---

### Path Variables

```bash
MNT_POINT="/mnt"
SRC_DIR="dusky"
POST_CHROOT_SRC="${SRC_DIR}/user_scripts/arch_iso_scripts/001_post_chroot"
```

All paths are defined at the top as variables for easy adaptation.

- `SRC_DIR="dusky"` — the project directory name. This is a **relative path**, resolved from whatever directory the script runs in. This is why `001_ISO_ORCHESTRA.sh` changes to its own directory first — without that `cd`, this would look for `dusky` relative to wherever the user invoked the orchestrator, which is unpredictable.
- `POST_CHROOT_SRC` — the specific subdirectory containing the post-chroot scripts. These need to be placed directly at `/mnt/` root level so they're immediately runnable after `arch-chroot /mnt`.

**When adapting this for DOOM:** `SRC_DIR` is the key value to change — it should be the name of your project's root directory as it exists in the live environment.

---

### Mount & Source Verification

```bash
mountpoint -q "$MNT_POINT" || { echo "[ERROR] $MNT_POINT not mounted."; exit 1; }
[[ -d "$SRC_DIR" ]] || { echo "[ERROR] '$SRC_DIR' not found in $(pwd). Run from repo root."; exit 1; }
```

Two guard checks using the `||` short-circuit pattern instead of `if/then` blocks — functionally identical, just more compact.

- `|| { ...; }` — the `{ }` is a **command group**: multiple commands treated as one unit. Both `echo` and `exit` only run if the left-hand test fails. The semicolons inside are required — bash needs them to delimit commands within a group.
- `$(pwd)` inside the error message — embeds the current working directory in the error output. Immediately tells the user exactly where the script was looking, making the mistake obvious to diagnose.
- `[[ -d "$SRC_DIR" ]]` — tests that the path exists and is a directory. Fails on a missing directory or if the path points to a file.

---

### Copying Post-Chroot Scripts

```bash
if [[ -d "$POST_CHROOT_SRC" ]]; then
    echo ">> Copying post-chroot scripts to ${MNT_POINT}/..."
    cp -Rfp -- "${POST_CHROOT_SRC}/." "${MNT_POINT}/"
fi
```

Copies only if the subdirectory exists — a soft check, not a hard error. The important detail is the source path:

- `"${POST_CHROOT_SRC}/."` — the trailing `/.` is the key. In `cp -R`, there's an important distinction:
  - `cp -R dir/ /mnt/` → creates `/mnt/dir/` and copies contents inside it.
  - `cp -R dir/. /mnt/` → copies the **contents** of `dir` directly into `/mnt/`, without creating the subdirectory.

  The `/.` form is used here so the post-chroot scripts land at `/mnt/001_CHROOT_ORCHESTRA.sh`, `/mnt/003_post_chroot.sh`, etc. — directly runnable after entering the chroot — rather than being nested inside `/mnt/001_post_chroot/`.

---

### Copying the Full Project

```bash
cp -Rfp -- "$SRC_DIR" "${MNT_POINT}/"
```

Copies the entire project directory into `/mnt`. This time **without** the `/.` — the full directory is copied as a named subdirectory, so it lands at `/mnt/dusky/` (or `/mnt/DOOM/` in the adapted version). This makes the complete project available inside the chroot at `/dusky/`, which the post-chroot scripts can reference.

**The `cp` flags:**

- `-R` — recursive. Copies directories and everything inside them, preserving the tree structure.
- `-f` — force. Overwrites existing files without prompting. Safe here because we're in control of what's being copied.
- `-p` — preserve. Maintains original file permissions, timestamps, and ownership. Critically important for scripts — without this, execute permissions (`chmod +x`) aren't carried over and every script would need to be made executable again inside the chroot.
- `--` — end-of-options marker. Everything after this is treated as a positional argument (a filename), not a flag. Prevents filenames or directory names that start with `-` from being misinterpreted as options.

---

## `templates/arch_iso/pre_chroot/009_fstab.sh`

The final pre-chroot script. It generates the filesystem table that tells the kernel what to mount and how at every boot. It also marks the end of the pre-chroot phase by telling the user to run `arch-chroot /mnt`.

---

### Optional Skip

```bash
read -r -p "Generate a new fstab? [Y/n]: " response
if [[ "${response,,}" =~ ^(n|no)$ ]]; then
    echo ">> Skipped fstab generation."
    exit 0
fi
```

Default is yes. The skip path exists for rescue or re-entry scenarios — if you've already generated an fstab and manually fine-tuned it, you don't want this script to overwrite your edits.

---

### Generating the fstab

```bash
genfstab -U /mnt > /mnt/etc/fstab
```

The single most important line in this script.

- `genfstab` — an Arch Linux tool that reads the currently active mounts and generates the corresponding `/etc/fstab` entries automatically.
- `-U` — use **UUIDs** to identify partitions. This is non-negotiable. Device path names like `/dev/nvme0n1p2` are assigned by the kernel at boot based on detection order — adding a drive, changing a USB port, or certain hardware changes can cause devices to be renumbered. UUIDs are burned into the filesystem by `mkfs` and never change, making them the only reliable way to identify a partition across reboots.
- `/mnt` — the root from which `genfstab` scans. It detects every mount point under `/mnt` (root at `/mnt`, home at `/mnt/home`, EFI at `/mnt/boot`) and generates one `fstab` entry for each. Crucially, it records the exact mount options that are currently active — the `noatime`, `compress=zstd:3`, `subvol=@`, etc. set in `004_disk_mount.sh` — so the installed system boots with all those optimisations automatically.
- `> /mnt/etc/fstab` — writes to the **new system's** fstab, not the live ISO's. The live ISO's fstab is at `/etc/fstab`; the new system's is at `/mnt/etc/fstab`.

---

### Displaying the Result

```bash
echo ">> /mnt/etc/fstab contents:"
cat /mnt/etc/fstab
```

Prints the full generated fstab immediately after creation so the user can inspect it before proceeding. A malformed or missing fstab is one of the most common causes of a system failing to boot — showing it here gives the user a chance to spot problems before rebooting.

---

### Next Step Instructions

```bash
echo "========================================="
echo "  NEXT STEP: Enter the chroot with:"
echo ""
echo "    arch-chroot /mnt"
echo ""
echo "========================================="
```

Marks the boundary between the two phases. The orchestrator cannot automate `arch-chroot` — it fundamentally changes the process's root directory, environment, and running context. The user must run it manually.

**What `arch-chroot /mnt` does:** It's a wrapper around the Linux `chroot` syscall. It changes the root directory of the current process and all its children to `/mnt`, so that `/` inside the chroot now refers to `/mnt` outside it. It also mounts several virtual filesystems into the chroot automatically (`/proc`, `/sys`, `/dev`, `/run`) so systemd and other tools work correctly inside. Once you run this command, you are effectively "inside" the newly installed system, and `001_CHROOT_ORCHESTRA.sh` takes over.

---

## PRE-CHROOT NOTES

The short answer to the overarching question: **yes, almost everything in the pre-chroot phase can be skipped by using `archinstall`**. The ISO scripts exist as an alternative path — a fully scripted, no-TUI install. But as `GUIDE.md` notes, `archinstall` is the recommended approach. The tradeoff is that `archinstall` leaves some optimisations at defaults that the ISO scripts set explicitly. Those gaps are addressed below.

---
#### Response

##### 1. BTRFS Mount Options (`004_disk_mount.sh`)

**Does `archinstall` apply these automatically?**

Partially. According to `GUIDE.md`, `archinstall` uses `compress=zstd,noatime` — it gets `noatime` and compression right, but with important differences from what `004_disk_mount.sh` sets:

| Option | `archinstall` | `004_disk_mount.sh` |
|---|---|---|
| `noatime` | ✓ yes | ✓ yes |
| `compress=zstd` | ✓ yes (level 1) | ✓ yes (level 3) |
| `space_cache=v2` | ✗ no | ✓ yes |
| `ssd` | ✗ no | ✓ yes (if SSD detected) |
| `discard=async` | ✗ no | ✓ yes (if SSD detected) |

**Can you apply the missing options after rebooting and logging in?**

Yes — entirely. The process is:
1. Edit `/etc/fstab` as root and change the options on the BTRFS lines.
2. Run `sudo mount -o remount /` and `sudo mount -o remount /home` to apply without rebooting (or just reboot).

One important caveat: **`compress=zstd:3` only applies to data written after the option is set**. Existing files on disk stay as they are. On a fresh install this doesn't matter — all your files will be written after the option is active. If you were applying it to an existing system with data, you'd need to run `btrfs filesystem defragment -r -czstd /` to recompress everything, which can take hours.

---

###### `compress=zstd:3` — Pros, Cons, and Alternatives

**What it does:** Every file written to the BTRFS partition is automatically compressed by the zstd algorithm before being stored, and transparently decompressed on read. Applications never know this is happening.

**Pros:**
- Meaningful disk space savings for compressible data — source code, config files, logs, and documents can compress 2–4x.
- Can actually improve performance on slower drives (SATA SSDs, HDDs) because less data moves through the I/O path even though the CPU does extra work.
- BTRFS is smart about it — files that compress poorly (images, videos, zip archives) are detected after the first compressed extent and stored uncompressed, so no space is wasted.
- Level 3 gives noticeably better compression ratios than level 1 (the default) at a modest CPU cost.

**Cons:**
- CPU overhead on every write (compression) and read (decompression). On a fast NVMe drive where storage I/O is no longer the bottleneck, the CPU overhead can actually reduce throughput.
- Compression is per-extent, not per-file retroactively. You can't easily "undo" it for specific files after the fact.
- Level 3 uses more CPU than level 1. On a battery-powered laptop this has a small but real power consumption impact.

**Alternatives:**

| Option | Compression Ratio | CPU Cost | Best For |
|---|---|---|---|
| `compress=zstd:1` | Good | Very Low | Fast NVMe, battery-sensitive laptops |
| `compress=zstd:3` | Better | Low-Medium | General use, SATA SSDs |
| `compress=zstd:6` | Best practical | High | Archival, lots of free CPU |
| `compress=lzo` | Moderate | Minimal | Very CPU-limited systems |
| *(none)* | None | None | Very fast NVMe where I/O is not the bottleneck |

**Recommendation:** `compress=zstd:1` is what archinstall uses and it's genuinely fine. The real-world difference between level 1 and level 3 on a general-use desktop is small — around 5–15% better compression ratio at the cost of slightly more CPU time per write. Level 3 is a reasonable choice for a SATA SSD where storage speed is more of a factor. If you have a fast NVMe, level 1 is probably the better choice.

---

###### `space_cache=v2` — Pros, Cons, and Alternatives

**What it does:** BTRFS needs to track which blocks on disk are free so it knows where to write new data. It maintains an in-memory cache of this information (for speed) and persists it to disk. `v2` is the second-generation implementation of this cache.

**Pros:**
- Faster free space lookups than v1, especially on large or fragmented filesystems.
- More reliable — v1 had known correctness bugs that could, in rare cases, lead to space accounting errors.
- Actively maintained and recommended by BTRFS developers.
- On Linux 5.15+, it is essentially the default anyway.

**Cons:**
- On a filesystem previously using v1, the first mount with `v2` triggers a one-time migration that can add a few seconds to boot. Not relevant on a fresh install.
- On Linux kernels before 5.15, you had to specify it explicitly. On modern Arch (which tracks the latest stable kernel), this is irrelevant.

**Alternatives:** `space_cache=v1` (the old implementation). There is no reason to choose v1 on a fresh install with a modern kernel. Specify v2 explicitly to be certain, even if it's now the default — explicit configuration doesn't break anything and makes your intent clear.

---

###### `ssd` and `discard=async` — Are These Relevant for a SATA Drive?

**Yes, both apply to SATA SSDs.**

The `is_ssd()` function in `004_disk_mount.sh` checks `/sys/block/<disk>/queue/rotational`. A SATA SSD returns `0` there (non-rotating), the same as an NVMe drive. So the script would correctly detect your SATA SSD and add both options.

**`ssd`:** Activates BTRFS's SSD-aware block allocator. This is beneficial on any solid-state drive regardless of interface (SATA or NVMe). The allocation strategy is different from HDD mode and better suited to flash storage.

**`discard=async` on SATA:** SATA SSDs support TRIM and benefit from it in the same way as NVMe drives. TRIM keeps the drive healthy by letting its firmware know which blocks are free, enabling better wear leveling and garbage collection. The `async` variant queues TRIM commands in the background rather than blocking on each delete — this is both safe and efficient on SATA SSDs.

One thing worth knowing: the `010_services.sh` post-chroot script also enables `fstrim.timer` — a systemd timer that runs `fstrim` (a manual TRIM sweep) once a week on all mounted filesystems. This is compatible with `discard=async`. Using both together is safe and slightly redundant — `discard=async` handles deletes continuously, `fstrim.timer` does a periodic sweep to catch anything missed. There's no harm in having both.

**Bottom line for your SATA drive:** Yes, add both `ssd` and `discard=async` to your fstab BTRFS entries. You can edit `/etc/fstab` after running `archinstall` and rebooting.

---

##### 2. Running Reflector Before `archinstall` (`005_mirrorlist.sh`)

`archinstall` reads directly from `/etc/pacman.d/mirrorlist` — whatever is in that file when you launch `archinstall` is what it uses for downloads. So the workflow is simply: **run reflector first, then run `archinstall`**.

The Arch ISO includes reflector, so no installation is needed. From the live ISO shell:

```bash
# Step 1 — update the mirrorlist for US mirrors only
reflector --country US --protocol https --age 12 --sort rate --save /etc/pacman.d/mirrorlist

# Step 2 — view the results and pick your top mirrors
cat /etc/pacman.d/mirrorlist
```

For your workflow of US + 2 additional specific ones, there are two approaches:

**Option A — let reflector pick from multiple countries:**
```bash
reflector --country US,DE,FR --protocol https --age 12 --sort rate --number 10 --save /etc/pacman.d/mirrorlist
```
`--number 10` limits the output to the 10 fastest mirrors across all specified countries, sorted by speed. You can then inspect the file and manually delete any entries you don't want.

**Option B — run reflector for US only, then manually add 2 more:**
```bash
# Run reflector for US
reflector --country US --protocol https --age 12 --sort rate --number 5 --save /etc/pacman.d/mirrorlist

# Open the mirrorlist and manually add extra Server = lines from https://archlinux.org/mirrors/status/
nvim /etc/pacman.d/mirrorlist
```

After either approach, run `archinstall` — it will use the updated mirrorlist automatically. No configuration needed inside `archinstall` itself for this; the "Mirrors" step in `archinstall` just lets you pick a region to re-run its own mirror selection, which you can skip since you've already done it manually.

---

##### 3. `dosfstools` (`007_pacstrap.sh`)

**What it is:** A package providing tools for FAT and FAT32 filesystems — specifically `mkfs.fat` (format), `fsck.fat` (check and repair), and `fatlabel` (rename).

**Is it necessary on a UEFI system?**

Yes, and for a non-obvious reason. The EFI partition is FAT32. At boot, systemd runs filesystem checks (`fsck`) on partitions listed in `/etc/fstab`. For the EFI partition, it looks for `fsck.vfat` (which is provided by `dosfstools`). If `dosfstools` isn't installed and systemd tries to check the EFI partition, it either skips it silently or throws an error.

Additionally, if you ever need to reformat or repair the EFI partition — after a botched bootloader install, for example — you need `mkfs.fat` and `fsck.fat` to do it. These tools live in `dosfstools`.

**Is it a hard dependency of anything?**

Not a hard dependency in pacman's dependency tree (nothing in `base` lists it as required). But it is a **functional dependency** of having a healthy UEFI system — systemd expects it to be present for EFI partition health checks.

**On a BIOS system:** Not needed (no FAT32 EFI partition). Safe to install anyway — it's a tiny package with no downside.

**Does `archinstall` install it?** Yes — `archinstall` installs it as part of its standard UEFI setup. You don't need to add it manually.

---

##### 4. Microcode Packages (`intel-ucode` / `amd-ucode`)

**What microcode actually is:**

CPUs are extraordinarily complex — billions of transistors executing an instruction set that has accumulated 40+ years of extensions. Despite extensive testing, CPUs ship with bugs in their execution logic, called *errata*. Microcode is a layer of firmware that lives inside the CPU itself, translating the x86 instructions you send into the CPU's internal micro-operations. Manufacturers release microcode updates that patch this translation layer — effectively fixing bugs in the CPU without replacing the hardware.

**How it's loaded:**

Microcode is loaded by the bootloader (systemd-boot or GRUB) during the very early boot process, before the kernel even starts executing — this is why the boot entry in `007_systemd_boot.sh` includes an `initrd /intel-ucode.img` line *before* the main `initrd /initramfs-linux.img`. The CPU detects the update blob in memory and applies it immediately. This happens on every boot — microcode is not permanently flashed into the CPU like a BIOS update. Remove the package and the next boot runs without it.

**What kinds of bugs it fixes:**

- **Computation errors** — incorrect arithmetic results in edge cases, rare but possible.
- **Speculative execution vulnerabilities** — the most significant category in recent years:
  - *Spectre* (2018) — allows a process to read memory from other processes by exploiting speculative branch execution.
  - *Meltdown* (2018) — allows reading kernel memory from userspace.
  - *MDS / RIDL / Fallout* (2019) — various microarchitectural data sampling attacks via CPU internal buffers.
  - *TAA* (2019), *SRBDS* (2020), *MMIO Stale Data* (2022) — further variants.

  Microcode updates provide CPU-level mitigations for these. The kernel also implements software mitigations (at a performance cost), but microcode fixes are cleaner and often faster.
- **Stability** — some "random" kernel panics and system freezes on otherwise healthy hardware are actually CPU errata being triggered. A microcode update silently fixes them.

**What happens without it:**

The system boots and runs normally in the vast majority of cases. But:
- Known security vulnerabilities remain at the hardware level (the kernel's software mitigations still apply, but they're imperfect and have performance costs).
- Edge-case CPU bugs may trigger unpredictably.
- You're running a CPU in a known-buggy state that the manufacturer has already patched.

**Does `archinstall` install the correct microcode?**

Yes. `archinstall` detects your CPU vendor and installs `intel-ucode` or `amd-ucode` automatically as part of the base system. You do not need to add this manually.

**On a VM:** Microcode packages don't do anything meaningful inside a virtual machine — the hypervisor manages the physical CPU's microcode. Safe to install, does nothing.

#### TAKEAWAYS

1.
    `noatime` is set on both
    `compress=zstd`: I decide for level 1 which is archinstalls default
    `space_cache=v2`: If i understood correctly this is the default since kernel version Linux 5.15+ so i shouldnt need to put it
    `ssd` & `discard=async` Add both, tell me how to add this settings after running the arch install script

    **`space_cache=v2` — your understanding is correct.** Arch always ships the latest stable kernel (currently 6.x, well past 5.15), so v2 is already the default. You don't need to add it manually.

    **How to add `ssd` and `discard=async` after `archinstall` and rebooting:**

    After you log in, open `/etc/fstab` as root:

    ```bash
    sudo nvim /etc/fstab
    ```

    The file will have lines that look roughly like this (UUIDs will differ):

    ```
    UUID=xxxx-xxxx  /       btrfs  rw,noatime,compress=zstd,subvol=/@        0 0
    UUID=xxxx-xxxx  /home   btrfs  rw,noatime,compress=zstd,subvol=/@home    0 0
    ```

    Add `ssd,discard=async` to the options field (the 4th column) of every BTRFS line:

    ```
    UUID=xxxx-xxxx  /       btrfs  rw,noatime,compress=zstd,ssd,discard=async,subvol=/@        0 0
    UUID=xxxx-xxxx  /home   btrfs  rw,noatime,compress=zstd,ssd,discard=async,subvol=/@home    0 0
    ```

    Save the file, then **reboot**. Don't try to remount `/` in-place — remounting the root filesystem live can behave unexpectedly. A clean reboot is safer and also verifies the fstab is valid (if it has a syntax error the system will drop into emergency mode, telling you immediately).

    To confirm the options are active after rebooting:

    ```bash
    findmnt -o TARGET,OPTIONS /
    findmnt -o TARGET,OPTIONS /home
    ```

    Both should show `ssd` and `discard=async` in the options list.

---

2.
    'reflector --protocol https --age 12 --sort rate --save /etc/pacman.d/mirrorlist'
    I want to run this command not to save the mirror list but to know which are high performining mirriros i can add besides the US one while using the archinstall script

    Simply drop the `--save` flag and reflector prints to stdout instead of writing to any file:

    ```bash
    reflector --protocol https --age 12 --sort rate --number 20
    ```

    This shows the top 20 fastest mirrors globally, formatted as `Server = https://...` lines. You can read off which countries appear and pick your preferred ones.

    If you want to narrow it down to specific regions you're likely to get good latency from:

    ```bash
    reflector --protocol https --age 12 --sort rate --country US,PT,ES,DE,FR,NL --number 20
    ```

    The output will be ranked by speed. Note the top 2–3 non-US URLs, then when `archinstall` reaches the Mirrors step, select those countries in addition to US. Archinstall will run its own mirror fetch for those countries and pick from them.

    Alternatively — and this is simpler — just run reflector with `--save` before launching `archinstall` (as covered earlier), skip archinstall's mirror step entirely, and you're done. The effect is the same.

---

3.
dosfstools get installed automatically by archinstall script

4.
micro code package get installed automatically by archinstall script

PACKAGES
base base-devel linux linux-headers linux-firmware neovim btrfs-progs dosfstools git lazygit intel-ucode

---

## `templates/arch_iso/post_chroot/001_CHROOT_ORCHESTRA.sh`

This is the **Phase 2 orchestrator** — the direct counterpart to `001_ISO_ORCHESTRA.sh`, but running inside the `arch-chroot` environment. The context is fundamentally different: you are now inside the new system, `/` is the installed root, and the scripts here configure everything that needs to be done before the first real reboot. The engine is more polished than the ISO orchestrator — it adds colour output, structured logging, a dry-run mode, and uses absolute path resolution.

---

### Shebang, Shell Options & Script Directory

```bash
#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

The `set -euo pipefail` is identical to the ISO orchestrator — same guarantees, same reasoning. What's different is how the script locates itself.

- `BASH_SOURCE[0]` — unlike `$0`, which holds whatever string was used to invoke the script (could be a relative path, a symlink, or just the name if it's on `PATH`), `BASH_SOURCE[0]` always holds the path to the actual source file being executed. More reliable when scripts are called from other scripts or sourced.
- `"$(dirname "${BASH_SOURCE[0]}")"` — strips the filename to get just the directory portion.
- `cd "..." && pwd` — changes into that directory and then prints the absolute path. The `&&` ensures `pwd` only runs if `cd` succeeded. The result is always a clean, absolute, symlink-free path.
- `readonly` — marks `SCRIPT_DIR` as immutable. Any attempt to reassign it later in the script causes an immediate error. Since this is a constant that other parts of the script depend on, preventing accidental overwriting is good practice.

**Comparison with `001_ISO_ORCHESTRA.sh`:** The ISO orchestrator used `cd "$(dirname "$(readlink -f "$0")")"` at the top level, changing the working directory globally and then using relative paths everywhere. This orchestrator keeps the working directory unchanged and stores the absolute path in `SCRIPT_DIR`, constructing full paths explicitly. Both approaches work; this one is cleaner because it doesn't have a hidden side effect on the working directory.

---

### Terminal Detection & Colour Variables

```bash
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m' BOLD='\033[1m' RESET='\033[0m'
else
    readonly RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi
```

Detects whether output is going to a real terminal, and only sets colour codes if it is.

- `[[ -t 1 ]]` — the `-t` test checks whether file descriptor `1` (stdout) is connected to a terminal (TTY). If stdout is being redirected to a file or a pipe (e.g. `./001_CHROOT_ORCHESTRA.sh > install.log`), `-t 1` returns false.
- When piped or redirected, the colour escape sequences (`\033[0;31m` etc.) would appear as literal garbage characters in the log file. The `else` branch sets all colour variables to empty strings, so the logging functions still work but produce clean, undecorated output.
- `\033[0;31m` — an ANSI escape sequence. `\033` is the ESC character (octal 33). `[0;31m` sets the colour: `0` resets any previous style, `31` sets foreground to red. The full set: `31`=red, `32`=green, `33`=yellow (with `1;` bold), `34`=blue.
- `\033[0m` (`RESET`) — resets all terminal formatting back to default. Every coloured string must end with this, otherwise the colour bleeds into all subsequent output.

**Why `readonly` here:** The colour variables are set once and should never change during execution. `readonly` enforces that.

---

### Logging Functions

```bash
log_info()  { printf "${BLUE}[INFO]${RESET}  %s\n" "$*"; }
log_ok()    { printf "${GREEN}[OK]${RESET}    %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[WARN]${RESET}  %s\n" "$*" >&2; }
log_error() { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; }
```

Four wrapper functions that standardise all output from the orchestrator with consistent prefixes, colour coding, and routing.

- `printf "..." "$*"` — `$*` expands all arguments to the function as a single string, which becomes the `%s`. Using `printf` over `echo` is more predictable — `echo` interprets flags like `-e` and `-n` inconsistently across shells and systems.
- `>&2` on `log_warn` and `log_error` — redirects output to **stderr** (file descriptor 2) rather than stdout. This is the Unix convention: normal output goes to stdout, diagnostic messages and errors go to stderr. It means you can redirect stdout to a log file while still seeing warnings and errors in the terminal, or filter them separately.
- The spacing after `[OK]` and `[INFO]` etc. is deliberate — it aligns the message text at the same column regardless of the prefix length, making the output easier to scan.

---

### Install Sequence

```bash
declare -ra INSTALL_SEQUENCE=(
    "003_post_chroot.sh"
    "004_mkinitcpio_config.sh"
    "005_package_installer.sh"
    "007_systemd_boot.sh"
    "008_grub.sh"
    "009_zram_config.sh"
    "010_services.sh"
)
```

- `declare -r` — makes the variable **readonly** after declaration. Attempting to modify `INSTALL_SEQUENCE` anywhere later causes an immediate error.
- `declare -a` — explicitly declares it as an **array**. Without this, bash could interpret the assignment differently in some edge cases.
- `-ra` combines both flags. This is the correct way to declare a constant array in bash.

Note the gap in numbering: `005` is followed by `007`. Script `006` doesn't exist in the post-chroot sequence — the number is reserved (following the same convention as the pre-chroot scripts, where gaps allow inserting steps later without renaming everything).

---

### Execution Engine

#### Counter Variables

```bash
declare -i executed=0 skipped=0 failed=0
```

- `declare -i` — declares the variables as **integers**. Bash normally treats everything as a string; with `-i`, arithmetic operations work directly without `$(( ))` syntax, and assigning a non-integer value would result in `0`. More importantly, it makes the intent explicit: these are numeric counters, not strings.
- Contrast with `001_ISO_ORCHESTRA.sh`, which used arrays (`EXECUTED=()`, `SKIPPED=()`, `FAILED=()`) to track the actual script names. This orchestrator only tracks counts — simpler, but you lose the ability to print exactly which scripts failed by name in the summary.

#### `handle_failure`

```bash
handle_failure() {
    local script="$1"
    ((failed++))
    log_error "Script failed: $script"
    printf "  ${BOLD}[R]${RESET}etry  |  ${BOLD}[S]${RESET}kip  |  ${BOLD}[A]${RESET}bort\n"
    read -rp "  Choice: " choice
    case "${choice,,}" in
        r) return 0 ;;
        s) return 1 ;;
        a|*) exit 1 ;;
    esac
}
```

Called whenever a script exits with a non-zero code. Returns `0` for retry, `1` for skip, or exits the entire orchestrator.

- `((failed++))` — increments the counter immediately on entry, **before** knowing whether the user will retry. This means if a script fails, the user retries it, and it then succeeds, `failed` still shows `1` in the final summary. It counts failure *events*, not final-state failed scripts. A subtle design choice worth being aware of.
- `a|*)` — the catch-all case. `a` is the explicit abort option, and `*` catches everything else — including empty input, typos, or Ctrl+C being awkward. Any unrecognised input aborts. This is more conservative than `001_ISO_ORCHESTRA.sh` where only specific inputs triggered abort.
- The function's return value is what drives the loop in `run_sequence`: `return 0` = retry, `return 1` = skip.

#### `run_sequence`

```bash
run_sequence() {
    local auto_mode="${1:-false}"

    for script in "${INSTALL_SEQUENCE[@]}"; do
        local script_path="${SCRIPT_DIR}/${script}"

        if [[ ! -f "$script_path" ]]; then
            log_warn "Not found: $script (skipping)"
            ((skipped++))
            continue
        fi

        if [[ "$auto_mode" == false ]]; then
            read -rp "Run this step? [Y/n/q]: " choice
            case "${choice,,}" in
                n) ((skipped++)); continue ;;
                q) break ;;
            esac
        fi

        local success=false
        while [[ "$success" == false ]]; do
            if bash "$script_path"; then
                success=true
                ((executed++))
                log_ok "Completed: $script"
            else
                if ! handle_failure "$script"; then
                    ((skipped++))
                    break
                fi
            fi
        done
    done
}
```

- `local auto_mode="${1:-false}"` — takes the first argument with a default of `"false"` if none is passed. The `:-` default prevents `set -u` from crashing when the function is called without arguments.
- `"${SCRIPT_DIR}/${script}"` — constructs an absolute path. Unlike `001_ISO_ORCHESTRA.sh` which relied on having `cd`'d into the right directory, this uses the stored `SCRIPT_DIR` to build a full path. Cleaner and side-effect free.
- `local success=false` / `while [[ "$success" == false ]]` — the retry loop uses a boolean string flag rather than `while true` + `break`. Slightly more readable — the loop condition directly expresses the intent ("keep going until success").
- `if ! handle_failure "$script"` — the `!` inverts the return value. `handle_failure` returns `0` for retry (which `if` sees as true, so `!` makes it false — loop continues) and `1` for skip (which `if` sees as false, so `!` makes it true — `skipped++` and `break`). It's an elegant use of return codes as booleans.

---

### `main` — Argument Handling

```bash
main() {
    local auto_mode=false

    for arg in "$@"; do
        case "$arg" in
            --auto)    auto_mode=true ;;
            --dry-run) ... ;;
            --help|-h) ... ;;
        esac
    done
    ...
}
```

Iterates over all arguments with `for arg in "$@"` rather than `shift`-based parsing. This means all flags are processed regardless of order — `--auto --dry-run` and `--dry-run --auto` are equivalent.

#### `--dry-run` Mode

```bash
--dry-run)
    log_info "=== DRY RUN ==="
    for s in "${INSTALL_SEQUENCE[@]}"; do
        local status="READY"
        [[ ! -f "${SCRIPT_DIR}/${s}" ]] && status="MISSING"
        printf "  [%7s] %s\n" "$status" "$s"
    done
    exit 0 ;;
```

A mode not present in `001_ISO_ORCHESTRA.sh`. Scans every script in the sequence, checks whether the file exists, prints `READY` or `MISSING` for each one, then exits without running anything.

- `printf "  [%7s] %s\n"` — `%7s` right-aligns the status string in a 7-character field. Both `"READY  "` and `"MISSING"` are 7 characters or fewer, so the script names always start at the same column — clean, readable output.
- `exit 0` — exits cleanly after printing. This is a diagnostic tool, not an execution path.

**Why this is useful:** Before running the full post-chroot setup, you can verify that all the expected scripts are present and nothing is accidentally missing — especially important if `008_copy_to_chroot.sh` didn't copy everything correctly.

#### `--help`

```bash
--help|-h)
    echo "Usage: $(basename "$0") [--auto] [--dry-run] [--help]"
    exit 0 ;;
```

- `basename "$0"` — strips the directory portion from `$0`, printing just the filename (`001_CHROOT_ORCHESTRA.sh`). Makes the usage line accurate regardless of how the script was invoked.
- Accepts both `--help` and `-h` as the same case via `|` in the `case` pattern.

---

### Summary Output

```bash
log_info "Executed: $executed | Skipped: $skipped | Failed: $failed"

if [[ $failed -eq 0 ]]; then
    echo ""
    log_ok "Phase 2 complete!"
fi
```

- The summary line always prints, showing all three counters on one line.
- The `Phase 2 complete!` message only prints if `failed` is exactly `0`. If any script failed (even if the user retried it to success), this line is suppressed — because `failed` counts failure events, not final state. A stricter definition of "complete" than you might expect.

---

## `templates/arch_iso/post_chroot/003_post_chroot.sh`

This script configures the **core identity** of the new system — the six things that make it a uniquely yours rather than a generic installation: timezone, locale, hostname, root password, your user account, and sudo access. It's entirely interactive by design; every value it sets is personal.

Note: colours and logging functions follow the exact same pattern as `001_CHROOT_ORCHESTRA.sh`. That section covers them in full — they won't be repeated here.

---

### 1. Timezone

```bash
DEFAULT_TZ="Asia/Kolkata"
read -rp "Enter timezone [${DEFAULT_TZ}]: " USER_TZ
TARGET_TZ="${USER_TZ:-$DEFAULT_TZ}"

ln -sf "/usr/share/zoneinfo/${TARGET_TZ}" /etc/localtime
hwclock --systohc
```

- `DEFAULT_TZ="Asia/Kolkata"` — the hardcoded fallback. This is a template from a project with Indian origins; when adapting for DOOM, change this to your own timezone (e.g. `Europe/Lisbon`, `America/New_York`).
- `${USER_TZ:-$DEFAULT_TZ}` — the `:-` **default substitution**: if `USER_TZ` is unset or empty (the user just pressed Enter), use `DEFAULT_TZ` instead. This is the standard bash pattern for optional input with a fallback.
- `ln -sf "/usr/share/zoneinfo/${TARGET_TZ}" /etc/localtime` — sets the timezone by creating a symbolic link. The Linux timezone system works through `/etc/localtime` always being a symlink pointing at one of the tz database files under `/usr/share/zoneinfo/`. `-s` = create a symbolic link. `-f` = force, replacing the existing symlink if one already exists.
- `hwclock --systohc` — synchronises the **hardware clock** from the system clock. Your motherboard has a battery-backed RTC (Real-Time Clock) chip that keeps time when the computer is off. `--systohc` means "set the hardware clock to match the current system time". Without this, after a reboot the RTC might restore a wrong time, causing the system clock to be incorrect on the next boot.

---

### 2. Locale

```bash
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
printf "LANG=en_US.UTF-8\n" > /etc/locale.conf
```

Three distinct steps for locale configuration, each doing a different thing:

- `sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen` — `/etc/locale.gen` is a file full of commented-out locale definitions, one per line. This `sed` command removes the `#` prefix from the `en_US.UTF-8` line, enabling it. `-i` = edit in-place (modifies the file directly rather than printing to stdout). The substitution is exact — `#en_US.UTF-8` becomes `en_US.UTF-8`.

- `locale-gen` — reads the now-uncommented lines in `/etc/locale.gen` and generates the binary locale data files in `/usr/lib/locale/`. These compiled files are what programs actually load when they need locale-aware behaviour (date formatting, number formatting, character sorting, etc.). Without running this command, enabling the locale in `locale.gen` has no effect.

- `printf "LANG=en_US.UTF-8\n" > /etc/locale.conf` — sets the system-wide default locale. `/etc/locale.conf` is read by `systemd` at boot and exported as environment variables for all processes. `LANG` is the master setting — it controls the language, character encoding, and formatting defaults for everything that doesn't have a more specific override.

---

### 3. Hostname

```bash
DEFAULT_HOST="workstation"
read -rp "Enter hostname [${DEFAULT_HOST}]: " USER_HOST
FINAL_HOST="${USER_HOST:-$DEFAULT_HOST}"

printf "%s\n" "$FINAL_HOST" > /etc/hostname
```

- `${USER_HOST:-$DEFAULT_HOST}` — same `:-` default pattern as the timezone. Empty input = use the default.
- `printf "%s\n" "$FINAL_HOST" > /etc/hostname` — writes the hostname to the file. `printf "%s\n"` is used instead of `echo` because `echo` can behave inconsistently with certain strings (e.g. strings starting with `-` are misread as flags). `printf "%s\n"` always treats its argument as a plain string.
- `/etc/hostname` is a one-line file read by `systemd` at boot to set the machine's hostname — the name that appears in your shell prompt and on the network.

**Note:** This script does not update `/etc/hosts`. Some older guides add a `127.0.1.1 yourhostname` entry there, but modern systemd with `systemd-resolved` handles local hostname resolution automatically without needing it.

---

### 4. Root Password

```bash
while true; do
    set +e
    passwd
    ret=$?
    set -e
    if [[ $ret -eq 0 ]]; then
        log_ok "Root password set."
        break
    fi
    log_error "Password mismatch. Try again."
done
```

- `passwd` with no arguments sets the password for the **currently running user** — inside the chroot, that's root.
- `set +e` / `set -e` around `passwd` — temporarily disables exit-on-error so that a failed `passwd` (mismatched password entry) doesn't abort the script. `ret=$?` captures the exit code.
- `$ret -eq 0` — `passwd` returns `0` on success, non-zero if the user mismatched their input. The loop retries until they get it right.

---

### 5. User Creation

#### Installing zsh first

```bash
pacman -S --needed --noconfirm zsh
```

Zsh is installed **before** `useradd` because the user will be created with `/usr/bin/zsh` as their login shell. If that binary doesn't exist when `useradd` runs, either the command fails or it creates the user with an invalid shell path that causes login errors later. Installing zsh first guarantees the shell exists.

#### Checking for an existing user

```bash
if id "$FINAL_USER" &>/dev/null; then
    log_info "User '${FINAL_USER}' already exists. Skipping creation."
else
    useradd ...
fi
```

- `id "$FINAL_USER"` — prints user identity information (UID, GID, groups) for the given username. Returns exit code `0` if the user exists, `1` if not.
- `&>/dev/null` — discards both stdout and stderr. We only care about the exit code, not the output.
- The `if/else` makes the script idempotent for user creation — re-running it won't fail or try to create a duplicate user.

#### `useradd`

```bash
useradd -m \
    -G wheel,input,audio,video,storage,optical,network,power \
    -s /usr/bin/zsh \
    "$FINAL_USER"
```

- `-m` — creates the user's home directory (`/home/username`). Without this flag, the user account is created but no home directory is made — the user would have nowhere to store files or configs.
- `-s /usr/bin/zsh` — sets zsh as the default login shell. Must be an absolute path to a valid, installed shell.
- `-G wheel,input,audio,...` — adds the user to these **supplementary groups** in addition to their auto-created primary group. Each group grants access to specific resources:

| Group | Grants access to |
|---|---|
| `wheel` | sudo (the sudoers rule added in step 6 uses this group) |
| `input` | raw input devices — mice, keyboards, joysticks. Needed by Hyprland and some Wayland compositors for direct device access |
| `audio` | audio hardware. Some audio configurations use group-based permissions |
| `video` | video hardware and GPU access. Relevant for hardware acceleration |
| `storage` | storage devices like USB drives and external disks |
| `optical` | optical drives (CD/DVD/Blu-ray) |
| `network` | network configuration tools |
| `power` | power management — suspend, hibernate, battery control. Needed by `tlp` and similar tools |

#### User password loop

```bash
while true; do
    set +e
    passwd "$FINAL_USER"
    ret=$?
    set -e
    ...
done
```

Identical pattern to the root password loop, but `passwd "$FINAL_USER"` sets the password for the newly created user rather than root. The loop retries on mismatch.

---

### 6. Sudoers

```bash
printf '%%wheel ALL=(ALL:ALL) ALL\n' | EDITOR='tee' visudo -f /etc/sudoers.d/10_wheel >/dev/null
```

The most non-obvious line in the script. It writes a sudo rule for the wheel group without directly editing any file. Breaking it into parts:

#### The content being written

`%%wheel ALL=(ALL:ALL) ALL` — in `printf`, the `%` character is a format specifier and must be escaped as `%%` to produce a literal `%`. So `%%wheel` prints `%wheel`. The full sudoers rule means:

- `%wheel` — applies to the wheel **group** (the `%` prefix means group; no prefix means user)
- `ALL=` — on all hosts
- `(ALL:ALL)` — can run commands as any user and any group
- `ALL` — can run any command

Together: any member of the `wheel` group can run any command as any user with `sudo`.

#### Why `visudo` instead of writing directly

`visudo` is the safe editor for sudoers files. Before saving, it parses the syntax and refuses to write if there's an error. A broken `/etc/sudoers` can lock you out of `sudo` entirely — the only recovery is booting a live USB. By going through `visudo`, the syntax is always validated before it's committed.

#### `EDITOR='tee'` trick

`visudo` opens the file in whatever `$EDITOR` is set to, expecting a human to type in an interactive editor. By overriding `EDITOR` to `tee` — which reads from stdin and writes to a file — the `printf` output piped into the command becomes the file's content. `visudo` sees its "editor" complete successfully and then validates and saves the result. It's a standard trick for non-interactively writing validated sudoers content.

- `>/dev/null` — `tee` always copies its input to both the file and stdout. Redirecting stdout to `/dev/null` prevents the rule from being printed to the terminal.

#### `/etc/sudoers.d/10_wheel` instead of `/etc/sudoers`

`/etc/sudoers.d/` is a drop-in directory for supplementary rules. The main `/etc/sudoers` file contains `@includedir /etc/sudoers.d` which automatically includes all files from that directory. Writing here instead of editing `/etc/sudoers` directly:

- Leaves the main file untouched (safer).
- Makes the rule easy to remove later (just delete the file).
- The `10_` prefix controls load order — files in `sudoers.d` are processed alphabetically.

---

## `templates/arch_iso/post_chroot/004_mkinitcpio_config.sh`

This script configures and regenerates the **initramfs** — the temporary filesystem the bootloader loads into RAM before the real root can be mounted. It's one of the most technically important scripts in the post-chroot phase. Get it wrong and the system won't boot.

---

### What mkinitcpio and the initramfs actually are

Before the kernel can mount your BTRFS root partition, it needs certain drivers and tools available in RAM. The **initramfs** (initial RAM filesystem) is a small, compressed archive that the bootloader loads alongside the kernel. It gets extracted into a temporary root filesystem in RAM, the kernel runs through it to prepare the real storage, then hands off to your actual system.

The boot sequence looks like this:

```
Firmware (UEFI)
  → Bootloader (systemd-boot)
    → Kernel + initramfs loaded into RAM
      → Kernel mounts initramfs as temporary /
        → Hooks run in sequence (load modules, set keyboard, find disk, mount BTRFS)
          → Real root mounted at /new_root
            → systemd takes over
              → initramfs discarded
```

`mkinitcpio` is the Arch Linux tool that builds this archive. `/etc/mkinitcpio.conf` is its configuration file — it controls exactly what goes inside.

---

### Config File Check

```bash
readonly CONF="/etc/mkinitcpio.conf"

if [[ ! -f "$CONF" ]]; then
    log_error "${CONF} not found."
    exit 1
fi
```

- `readonly CONF` — stores the path as a constant. Used in two places (the check and the `sed` command), so defining it once avoids repetition and makes it easy to change if needed.
- `[[ ! -f "$CONF" ]]` — `-f` tests that the path exists and is a regular file. The `!` inverts it: true if the file does **not** exist. If `pacstrap` ran correctly, this file will always be present — but the guard catches the case where it wasn't or something went wrong.
- `exit 1` — hard exit. Without the config file there is nothing to configure, so there's no point continuing.

---

### The `sed` Command

```bash
sed -i \
    -e 's/^MODULES=.*/MODULES=(btrfs)/' \
    -e 's|^BINARIES=.*|BINARIES=(/usr/bin/btrfs)|' \
    -e 's/^HOOKS=.*/HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)/' \
    "$CONF"
```

A single `sed` invocation that rewrites three lines in the config file in one pass.

- `-i` — in-place: modifies the file directly rather than printing to stdout.
- `\` at the end of each line — shell line continuation. The backslash tells bash the command continues on the next line. Purely cosmetic — makes the three expressions readable instead of one very long line.
- Multiple `-e` flags — each `-e` adds one expression. All expressions are applied to every line in the same pass through the file.
- `^MODULES=.*` — the `^` anchors the match to the **start of the line**, ensuring it only matches the actual `MODULES=` assignment and not any comment or other line that happens to contain those characters. `.*` matches everything after the `=` — the entire current value, whatever it is — and the whole line is replaced.
- `s|...|...|` on the BINARIES line — uses `|` as the sed delimiter instead of `/`. The replacement contains `/usr/bin/btrfs`, which includes forward slashes. Using `|` as the delimiter means the slashes don't need escaping. Any single character can be the sed delimiter — `/` is just the convention.

---

### `MODULES=(btrfs)`

```
MODULES=(btrfs)
```

The `MODULES` array lists kernel modules to be forcibly included in the initramfs and loaded during the boot process.

By default, the `autodetect` hook (explained below) scans the *currently running system* to figure out which modules are needed, then prunes the initramfs to include only those. The problem: we're building the initramfs inside a chroot on the live ISO. `autodetect` is scanning the ISO's hardware configuration, not necessarily the target machine's. It may not detect BTRFS as needed.

Adding `btrfs` to `MODULES` ensures it is **always** included regardless of what autodetect thinks. Without the BTRFS kernel module in the initramfs, the kernel cannot mount the root filesystem, and the system halts with a kernel panic.

---

### `BINARIES=(/usr/bin/btrfs)`

```
BINARIES=(/usr/bin/btrfs)
```

The `BINARIES` array lists executables to embed into the initramfs. When `mkinitcpio` processes this, it also automatically includes any shared libraries the binary depends on — so the executable is fully functional inside the initramfs environment.

Including `/usr/bin/btrfs` (the userspace BTRFS management tool) means:
- `btrfs` commands are available in the early boot environment for diagnostics or recovery without needing the full system.
- `btrfs check` can be run if the filesystem needs inspection before mounting.

---

### `HOOKS=(...)` — The Boot Pipeline

The hooks array is the most important part. Each hook is a script or module that runs in sequence during the initramfs phase, building up the environment step by step until the real root is ready to mount. The order matters — hooks depend on earlier hooks having completed.

```
HOOKS=(systemd autodetect microcode modconf kms keyboard sd-vconsole block filesystems)
```

For context, the default Arch hooks look like:
```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)
```

This script switches from the traditional `base`/`udev` approach to a **systemd-based initramfs**. Here's every hook and what it does:

#### `systemd`
Replaces both `base` and `udev` from the default set. Instead of a minimal busybox environment, this sets up a full **systemd** instance inside the initramfs. This is the modern approach — it integrates seamlessly with the main system, supports `sd-*` prefixed hooks, and enables better hardware detection. Once you use `systemd` here, you must use `sd-*` variants of any hooks that have them (which is why `keymap` becomes `sd-vconsole`).

#### `autodetect`
Scans the currently running system to determine which hardware modules are actually needed and prunes everything else from the initramfs. This is what keeps the initramfs small and fast to load. **Must appear early in the list** — hooks that run before `autodetect` include everything; hooks after it are filtered. This is why `MODULES=(btrfs)` in the config overrides autodetect — explicit module entries are not pruned.

#### `microcode`
Embeds the CPU microcode update files inside the initramfs and applies them at the very beginning of the boot process — earlier than any other hardware initialisation. This is **early microcode loading**, which is more effective than late loading (which happens after the kernel is fully running). The `intel-ucode` and `amd-ucode` packages installed in `007_pacstrap.sh` are what this hook reads.

#### `modconf`
Reads `/etc/modprobe.d/` configuration files and includes them in the initramfs. These files contain options for kernel modules — for example, disabling a specific feature of a driver, or setting a module parameter. Without this hook, custom module options would be ignored during the initramfs phase.

#### `kms`
**Kernel Mode Setting.** Includes GPU/DRM drivers in the initramfs so that display initialisation happens as early as possible. This is what enables the Plymouth boot splash (from `110_plymouth.sh` in the setup phase) to appear cleanly during boot without a jarring flash between text mode and graphics mode.

#### `keyboard`
Includes USB HID keyboard drivers in the initramfs. Without this, the keyboard is non-functional during the initramfs phase — meaning you couldn't type a LUKS passphrase, interact with recovery prompts, or do anything interactive during early boot.

#### `sd-vconsole`
The systemd-initramfs equivalent of the `keymap` + `consolefont` hooks from the default set. Reads `/etc/vconsole.conf` — the file created by `006_console_fix.sh` — and applies the keyboard layout (`KEYMAP=us`) inside the initramfs environment.

#### `block`
Includes block device drivers: SATA, NVMe, USB mass storage, and similar. These are the drivers that let the kernel see your storage devices at all. Without this hook, the kernel has no way to discover or communicate with the disk the root partition lives on.

#### `filesystems`
Includes filesystem drivers for every filesystem listed in `/etc/fstab`. On this system, that means BTRFS. This hook is what ultimately allows `mount` to understand and open the BTRFS root partition. It's the final step before the real system can be handed control.

**What's absent vs the default:**
- `fsck` — deliberately omitted. The boot parameters added in `007_systemd_boot.sh` include `fsck.mode=skip`, so filesystem checking is disabled at boot. BTRFS also has its own consistency mechanisms that don't rely on traditional fsck.

---

### Regenerating the Initramfs

```bash
mkinitcpio -P
```

Rebuilds the initramfs using the configuration just written.

- `-P` — process all **presets**. Presets are defined in `/etc/mkinitcpio.d/`. The default `linux` preset generates two images:
  - `initramfs-linux.img` — the normal image, filtered by `autodetect`.
  - `initramfs-linux-fallback.img` — a bloated but comprehensive fallback that includes everything regardless of autodetect. Used for recovery when the normal image fails to boot.

After this command, both files are written to `/boot/` and the bootloader entry configured in `007_systemd_boot.sh` will load them correctly.

**Note on the header comment:** The script's top comment says `Does NOT generate initramfs (that happens after packages are installed)` — this was accurate in an earlier version where `mkinitcpio -P` was a separate step after package installation. The current template combines both steps, so the comment is now outdated. The regeneration happens here.

---

## `templates/arch_iso/post_chroot/005_package_installer.sh`

This script installs the full software stack — everything that makes the system usable rather than just bootable. It groups packages by category and uses a **batch-first, individual-fallback** strategy: try to install an entire group at once for speed, and only fall back to one-by-one installation if the batch fails.

---

### Package Groups

Thirteen arrays, each covering a logical category. Each is a plain bash array of package names, defined at the top so they're easy to edit in one place.

#### `pkgs_graphics`
```bash
mesa vulkan-intel sof-firmware linux-firmware
```
- `mesa` — the open-source OpenGL and Vulkan implementation for Intel and AMD GPUs. Required for any graphical output; without it, the GPU is essentially unusable for rendering.
- `vulkan-intel` — Intel-specific Vulkan driver. Needed for Vulkan-based applications and games on Intel integrated graphics.
- `sof-firmware` — Sound Open Firmware. Required for Intel audio chipsets, particularly on modern laptops where the audio DSP needs firmware blobs to function. Without it, no sound.
- `linux-firmware` — already installed in `pacstrap`, included here to ensure the latest version is present.

#### `pkgs_hyprland`
```bash
hyprland uwsm xorg-xwayland xdg-desktop-portal-hyprland
xdg-desktop-portal-gtk polkit hyprpolkitagent
```
- `hyprland` — the Wayland compositor itself. The graphical environment.
- `uwsm` — Universal Wayland Session Manager. Launches and manages Hyprland as a proper systemd-integrated desktop session rather than just a raw compositor process. Enables proper session tracking, environment variable propagation, and systemd unit management for the desktop.
- `xorg-xwayland` — a compatibility layer that allows X11 (legacy) applications to run on Wayland. Not all apps have native Wayland support yet; XWayland bridges that gap transparently.
- `xdg-desktop-portal-hyprland` — portals are D-Bus interfaces that sandboxed or Flatpak applications use to request system capabilities (screen capture, file picker, camera). This is the Hyprland-specific implementation.
- `xdg-desktop-portal-gtk` — provides GTK-themed file chooser dialogs via the portal interface. Needed alongside the Hyprland portal for complete portal coverage.
- `polkit` — the privilege escalation framework for desktop sessions. Like sudo but for GUI applications — when an app needs elevated permissions, polkit handles the authentication.
- `hyprpolkitagent` — the Hyprland-specific polkit authentication agent. This is the popup dialog that appears asking for your password when polkit needs to authenticate a GUI app.

#### `pkgs_appearance`
```bash
qt5-wayland qt6-wayland gtk3 gtk4 nwg-look qt5ct qt6ct
matugen ttf-font-awesome ttf-jetbrains-mono-nerd noto-fonts-emoji
```
- `qt5-wayland`, `qt6-wayland` — platform plugins that allow Qt 5 and Qt 6 applications to run natively on Wayland instead of through XWayland.
- `gtk3`, `gtk4` — the GTK widget toolkits. Required at runtime for any GTK-based application.
- `nwg-look` — a GTK theme and icon configuration tool designed for Wayland environments (replacing `lxappearance` which requires X11).
- `qt5ct`, `qt6ct` — Qt 5 and Qt 6 configuration tools. Let you set theme, font, and icon settings for Qt applications without a full KDE/Plasma install.
- `matugen` — generates Material Design 3 colour schemes from a wallpaper image and applies them to config files. The theming engine for this setup.
- `ttf-font-awesome` — an icon font whose glyphs are used extensively in `waybar` and other tools for icons in text contexts.
- `ttf-jetbrains-mono-nerd` — JetBrains Mono with Nerd Font icon patches. The primary terminal and editor font.
- `noto-fonts-emoji` — Google Noto emoji font. Required for emoji characters to render as actual emoji rather than missing-glyph squares.

#### `pkgs_desktop`
```bash
waybar swww hyprlock hypridle hyprsunset hyprpicker
swaync swayosd rofi brightnessctl
```
- `waybar` — the status bar. Displays workspaces, clock, system stats, tray icons, etc.
- `swww` — wallpaper daemon for Wayland. Sets and transitions between wallpapers with animation support.
- `hyprlock` — screen locker built for Hyprland. Triggered by `hypridle` or manually.
- `hypridle` — idle daemon. Watches for user inactivity and triggers actions like dimming the screen or locking (`hyprlock`) after configurable timeouts.
- `hyprsunset` — blue light filter, similar to redshift or Night Light. Shifts the display colour temperature warmer at night to reduce eye strain.
- `hyprpicker` — a colour picker that works on Wayland, for picking hex/RGB values from anywhere on screen.
- `swaync` — Sway Notification Center. Manages desktop notifications and provides a notification panel.
- `swayosd` — on-screen display for volume and brightness changes. The small popup that appears when you press volume keys.
- `rofi` — application launcher and general-purpose fuzzy menu. Used for launching apps, power menu, wallpaper selection, etc.
- `brightnessctl` — controls screen and keyboard backlight brightness from the command line.

#### `pkgs_audio`
```bash
pipewire wireplumber pipewire-pulse playerctl
bluez bluez-utils blueman pavucontrol
```
- `pipewire` — the modern audio and video server, replacing both PulseAudio and JACK. Handles routing of all audio streams.
- `wireplumber` — the session manager for PipeWire. Manages device routing, policy, and connection logic between audio clients and devices.
- `pipewire-pulse` — a PulseAudio compatibility layer. Implements the PulseAudio API on top of PipeWire so applications that only know PulseAudio work without modification.
- `playerctl` — controls media players that implement the MPRIS D-Bus interface. Lets keybindings trigger play/pause/next on Spotify, mpv, browsers, etc.
- `bluez` — the Linux Bluetooth protocol stack.
- `bluez-utils` — command-line Bluetooth tools, including `bluetoothctl` for scripting and manual pairing.
- `blueman` — a GTK-based Bluetooth manager GUI with a system tray icon.
- `pavucontrol` — PulseAudio Volume Control GUI. Works with PipeWire via `pipewire-pulse` for graphical per-application volume control.

#### `pkgs_filesystem`
```bash
btrfs-progs compsize zram-generator udisks2 dosfstools
ntfs-3g gvfs unzip zip thunar
```
- `btrfs-progs` — already installed; gets updated to the latest version here.
- `compsize` — calculates the true on-disk size of BTRFS files accounting for compression. Without it, `du` reports uncompressed sizes and you can't see how much space compression is actually saving.
- `zram-generator` — a systemd-based tool that creates and configures ZRAM devices. This is what `009_zram_config.sh` sets up — it writes the config, and `zram-generator` reads it at boot.
- `udisks2` — a D-Bus service for disk management. Lets file managers and desktop environments auto-mount USB drives and manage storage without needing root.
- `dosfstools` — FAT/FAT32 tools. Already discussed in `007_pacstrap.sh`.
- `ntfs-3g` — NTFS filesystem driver with read/write support. Required for accessing Windows drives or NTFS-formatted external drives.
- `gvfs` — GNOME Virtual File System. Provides backends for accessing remote filesystems (SMB, SFTP), the trash, MTP devices (phones), and more.
- `unzip`, `zip` — standard archive tools for ZIP files.
- `thunar` — a lightweight, fast GTK file manager from the Xfce project.

#### `pkgs_network`
```bash
networkmanager iwd openssh firewalld reflector
firefox curl wget
```
- `networkmanager` — already installed in `pacstrap`.
- `iwd` — Intel Wireless Daemon. A modern, faster WiFi backend. When paired with NetworkManager (via `iwd` as the backend), it handles WPA3, faster roaming, and lower memory usage than the older `wpa_supplicant`.
- `openssh` — SSH client and server. `ssh` for connecting out, `sshd` for accepting connections in.
- `firewalld` — a dynamic firewall management daemon with D-Bus interface. Manages `nftables`/`iptables` rules with zone-based policy.
- `reflector` — mirror list updater. Installed in the ISO phase too, but included here so the live system can refresh mirrors after reboot.
- `firefox` — web browser.
- `curl`, `wget` — HTTP download tools; `curl` is more versatile, `wget` is simpler for recursive downloads.

#### `pkgs_terminal`
```bash
kitty zsh zsh-syntax-highlighting starship fastfetch
bat eza fd yazi fzf ripgrep gum
```
- `kitty` — GPU-accelerated terminal emulator with Wayland native support, extensive configuration, and image display protocol support (used by `yazi`).
- `zsh` — already installed in `003_post_chroot.sh`.
- `zsh-syntax-highlighting` — colours commands in the prompt as you type: valid commands in green, invalid in red. Makes typos immediately visible.
- `starship` — a cross-shell prompt that shows Git status, language versions, exit codes, and more. Configured in `starship.toml`.
- `fastfetch` — displays system information (OS, kernel, CPU, RAM, etc.) quickly on terminal open. Replaces the slower `neofetch`.
- `bat` — a `cat` replacement with syntax highlighting, line numbers, and Git diff integration.
- `eza` — an `ls` replacement with colour coding, icons, tree view, and Git status display.
- `fd` — a `find` replacement. Faster, respects `.gitignore`, and has a simpler syntax.
- `yazi` — terminal-based file manager with image preview (via Kitty's image protocol), archive browsing, and plugin support.
- `fzf` — a general-purpose fuzzy finder. Piped into other commands to add interactive selection to anything.
- `ripgrep` — a `grep` replacement. Faster than grep, respects `.gitignore` by default, and has better regex support.
- `gum` — a library of fancy terminal UI components (input prompts, spinners, choose menus, confirmations) used in shell scripts to make them interactive and polished.

#### `pkgs_dev`
```bash
neovim git git-delta jq bc shellcheck
```
- `neovim`, `git` — already installed.
- `git-delta` — a syntax-highlighting pager for `git diff`, `git show`, and `git log -p`. Replaces the default diff output with side-by-side, colour-coded diffs.
- `jq` — a command-line JSON processor. Parse, filter, and transform JSON from shell scripts or the terminal.
- `bc` — a command-line arbitrary-precision calculator. Used in shell scripts for arithmetic that bash's integer-only `$(( ))` can't handle.
- `shellcheck` — a static analysis tool for shell scripts. Catches common bugs, quoting issues, and style problems in bash/sh scripts.

#### `pkgs_multimedia`
```bash
ffmpeg mpv swappy imagemagick obs-studio
grim slurp wl-clipboard cliphist
```
- `ffmpeg` — a comprehensive audio/video conversion and processing tool. Used directly and as a backend by many other applications.
- `mpv` — a minimalist, scriptable media player. Supports almost every format via ffmpeg.
- `swappy` — a screenshot annotation tool. Opens a screenshot for drawing, text, and shape annotations before saving.
- `imagemagick` — a command-line image manipulation suite. Convert, resize, crop, compose images from scripts.
- `obs-studio` — screen recording and live streaming software.
- `grim` — a Wayland screenshot tool. Captures the entire screen or a specific output.
- `slurp` — a Wayland region selector. Used in combination with `grim` to let you draw a selection rectangle before capturing.
- `wl-clipboard` — provides `wl-copy` and `wl-paste` for Wayland clipboard access from the terminal and scripts.
- `cliphist` — a clipboard history manager for Wayland. Stores clipboard entries and integrates with `rofi` for selection.

#### `pkgs_sysadmin`
```bash
btop htop sysstat logrotate tlp thermald
powertop gnome-keyring
```
- `btop` — a full-featured, visually polished resource monitor showing CPU, memory, disk I/O, and network in real time.
- `htop` — a classic interactive process viewer. More widely available and scriptable than `btop`.
- `sysstat` — a suite of system performance tools: `iostat` (disk I/O stats), `sar` (system activity reporter), `mpstat` (CPU stats per core).
- `logrotate` — rotates, compresses, and deletes log files on a schedule. Prevents `/var/log` from filling the disk over time.
- `tlp` — a laptop power management tool. Automatically adjusts CPU governor, disk spindown, USB power, and more based on whether you're on AC or battery.
- `thermald` — Intel thermal daemon. Monitors CPU temperature and coordinates with the kernel to prevent thermal throttling in a more controlled way than the default.
- `powertop` — an Intel tool that analyses power consumption by process and suggests tunables. Useful for diagnosing battery drain.
- `gnome-keyring` — a keyring daemon that securely stores passwords, keys, and certificates. Integrates with PAM for automatic unlock on login.

#### `pkgs_gnome`
```bash
loupe gnome-text-editor gnome-calculator
```
A small set of GNOME apps that are well-designed and work cleanly on Hyprland:
- `loupe` — GNOME's image viewer. Minimal, fast, with gesture support.
- `gnome-text-editor` — a simple, modern text editor for quick edits without opening a full code editor.
- `gnome-calculator` — the standard GNOME calculator.

#### `pkgs_productivity`
```bash
obsidian zathura zathura-pdf-mupdf cava
```
- `obsidian` — a markdown-based note-taking and knowledge management app with a local vault.
- `zathura` — a minimal, keyboard-driven document viewer.
- `zathura-pdf-mupdf` — the PDF rendering backend for `zathura` using the MuPDF library. Required alongside `zathura` to actually open PDF files.
- `cava` — Console-based Audio Visualizer. A terminal audio spectrum analyser, often used as a visual element on the desktop.

---

### `install_group` Function

```bash
install_group() {
    local group_name="$1"
    shift
    local pkgs=("$@")

    [[ ${#pkgs[@]} -eq 0 ]] && return
    ...
}
```

The engine that handles installation for every group. Key mechanics:

#### `shift` and array capture

```bash
local group_name="$1"
shift
local pkgs=("$@")
```

- `local group_name="$1"` — captures the first argument (the group name like `"Graphics"`).
- `shift` — removes `$1` from the positional parameters, shifting everything left. After this, `$1` is what was `$2`, `$@` contains everything that was `$2` onwards — the package list.
- `local pkgs=("$@")` — captures all remaining arguments into a local array. The parentheses are critical: `local pkgs="$@"` would create a plain string; `local pkgs=("$@")` creates an array where each argument becomes a separate element.

#### Empty group guard

```bash
[[ ${#pkgs[@]} -eq 0 ]] && return
```

`${#pkgs[@]}` is the count of elements in the array. If `install_group` is called with no package names (only a group name), this exits early rather than calling `pacman` with an empty argument list, which would produce an error.

#### Batch install attempt

```bash
if pacman -S --needed --noconfirm "${pkgs[@]}"; then
    log_ok "${group_name}: all packages installed."
    return 0
fi
```

Tries to install the entire group in a single `pacman` call. This is fast — one transaction, one dependency resolution pass, one download queue. If it succeeds, the function returns immediately.

The problem with batch mode: `pacman` fails the entire transaction if any single package causes an error (renamed package, temporary network issue, dependency conflict). One bad package name fails everything.

#### Fallback: individual install

```bash
log_warn "Batch failed for ${group_name}. Falling back to individual install..."
rm -f /var/lib/pacman/db.lck

local fail_count=0
for pkg in "${pkgs[@]}"; do
    if pacman -S --needed --noconfirm "$pkg" &>/dev/null; then
        printf "  ${GREEN}[+]${RESET} %s\n" "$pkg"
    else
        printf "  ${RED}[X]${RESET} %s\n" "$pkg"
        ((fail_count++))
    fi
done
```

When batch fails, installs each package individually. This isolates failures — a single unavailable package doesn't prevent the rest from installing.

- `rm -f /var/lib/pacman/db.lck` — `/var/lib/pacman/db.lck` is pacman's lock file, created when pacman starts and removed when it exits cleanly. A failed batch install may leave this file behind, causing the next `pacman` call to refuse to run ("only one pacman may be running"). Removing it before the fallback loop ensures each individual install can proceed.
- `&>/dev/null` on the individual installs — suppresses all output. Instead of scrolling walls of pacman text for each package, the function prints clean `[+]` or `[X]` lines.
- `((fail_count++))` — counts failures across the group. Reported in the summary but doesn't stop the loop — remaining packages still get attempted.

---

### `main`

```bash
main() {
    rm -f /var/lib/pacman/db.lck
    pacman -Syy --noconfirm || log_warn "Repository sync failed."

    install_group "Graphics"      "${pkgs_graphics[@]}"
    install_group "Hyprland"      "${pkgs_hyprland[@]}"
    ...
}
```

#### Initial lock clear and sync

```bash
rm -f /var/lib/pacman/db.lck
pacman -Syy --noconfirm || log_warn "Repository sync failed."
```

- Clears any stale lock before starting.
- `pacman -Syy` — force-refreshes all package databases before installing anything. `-yy` (double) forces re-download even if pacman thinks databases are current. This ensures the package list is up to date and avoids installing outdated versions.
- `|| log_warn` — if the sync fails (e.g. no network), a warning is printed but the script continues. Packages already cached may still install; the user is informed rather than left wondering why it stopped.

#### The 13 `install_group` calls

Each call passes the group name as the first argument, then expands the corresponding array as individual arguments:

```bash
install_group "Graphics" "${pkgs_graphics[@]}"
```

`"${pkgs_graphics[@]}"` expands each array element as a separate quoted argument. Inside `install_group`, these become `$2`, `$3`, etc. — then `shift` removes `$1`, leaving them all in `$@` for the array capture.

---

## `templates/arch_iso/post_chroot/007_systemd_boot.sh`

This script installs and configures `systemd-boot` — the UEFI bootloader. It's the bridge between the firmware and the Linux kernel: when you power on the machine, the firmware hands control to systemd-boot, which reads its configuration and loads the kernel. Get this wrong and nothing boots.

---

### What systemd-boot is

systemd-boot (formerly called gummiboot) is a minimal UEFI boot manager. Unlike GRUB, which is a complex bootloader that can handle BIOS and UEFI, many filesystems, chained bootloaders, and more, systemd-boot deliberately does very little:

- **UEFI only** — it relies entirely on the firmware's EFI support.
- **Reads simple text files** — boot entries are plain `.conf` files on the ESP.
- **Paths relative to the ESP** — all kernel and initramfs paths are relative to the ESP root, so systemd-boot never needs to understand BTRFS or any other filesystem.
- **Faster than GRUB** — typically 1–2 seconds faster to hand off to the kernel.

The files it manages live entirely on the ESP (`/boot`):
```
/boot/
├── EFI/
│   └── systemd/
│       └── systemd-bootx64.efi   ← the bootloader binary itself
├── loader/
│   ├── loader.conf               ← global settings
│   └── entries/
│       └── arch.conf             ← the Arch Linux boot entry
├── vmlinuz-linux                 ← kernel image (placed by pacman)
├── intel-ucode.img               ← microcode (placed by pacman)
└── initramfs-linux.img           ← initramfs (built by mkinitcpio)
```

---

### Preflight Checks

#### UEFI detection

```bash
if [[ ! -d /sys/firmware/efi/efivars ]]; then
    log_warn "No UEFI detected. Skipping systemd-boot (use GRUB for BIOS)."
    exit 0
fi
```

Same check as in the pre-chroot scripts. The important difference here is **`exit 0`**, not `exit 1`. On a BIOS machine, skipping systemd-boot is the *correct* behaviour — `008_grub.sh` handles BIOS systems. `exit 0` tells the orchestrator this script completed successfully, so it marks it done and moves on rather than triggering a failure prompt.

#### ESP mount check

```bash
if ! mountpoint -q /boot; then
    log_error "/boot is not mounted. Mount your ESP first."
    exit 1
fi
```

The ESP must be mounted at `/boot` for `bootctl` to write files there. This is a hard `exit 1` — unlike the UEFI check, there's no graceful alternative. If `/boot` isn't mounted, the install has no target.

---

### Installing systemd-boot

#### `efibootmgr`

```bash
pacman -S --needed --noconfirm efibootmgr >/dev/null
```

`efibootmgr` is a tool that reads and writes UEFI NVRAM — the small amount of non-volatile memory in the firmware that stores which EFI binaries to boot and in what order. `bootctl install` uses it internally to register systemd-boot's EFI binary as a boot option in the firmware. Without `efibootmgr`, systemd-boot could be copied to the ESP but the firmware wouldn't know to launch it.

#### `bootctl install` with idempotency

```bash
if ! bootctl install --esp-path=/boot 2>/dev/null; then
    if ! bootctl is-installed --esp-path=/boot 2>/dev/null; then
        log_error "bootctl install failed."
        exit 1
    fi
fi
```

`bootctl install` copies the systemd-boot EFI binary to the ESP and registers it in UEFI NVRAM. The nested `if` structure handles re-runs gracefully:

- If `install` succeeds → done, continue.
- If `install` fails → check `bootctl is-installed`. If systemd-boot is already present (e.g. the script is being re-run), treat it as success and continue.
- If both fail → genuine error, hard exit.

`2>/dev/null` on both calls suppresses `bootctl`'s own error output — the script controls messaging through `log_error` instead.

---

### Loader Configuration

```bash
cat > /boot/loader/loader.conf <<EOF
default  arch.conf
timeout  1
console-mode max
editor   no
EOF
```

`/boot/loader/loader.conf` is the global configuration file for systemd-boot. A heredoc (`<<EOF ... EOF`) writes the entire block in one operation.

- `default arch.conf` — which entry to boot automatically. `arch.conf` refers to the file `/boot/loader/entries/arch.conf` that this script creates. The `.conf` extension is optional in newer versions but explicit is clearer.
- `timeout 1` — seconds to display the boot menu before auto-booting the default. `1` is fast enough to feel instant but still gives you one second to press a key and choose a different entry. `0` would skip the menu completely and always boot the default.
- `console-mode max` — the text resolution of the boot menu itself. `max` uses the highest resolution the firmware supports, giving sharp text on HiDPI displays. Alternatives: `auto` (firmware pick), `keep` (whatever the firmware already set), or a specific mode number.
- `editor no` — **disables the kernel command line editor** in the boot menu. Without this, anyone with physical access to the machine can press `e` at the boot menu and modify the kernel parameters before booting — for example, adding `init=/bin/bash` to drop straight into a root shell, completely bypassing login and disk encryption. This is a basic hardening setting that costs nothing.

---

### Detecting the Root PARTUUID

#### Finding the source device

```bash
ROOT_DEV_RAW=$(findmnt -n -o SOURCE /)
ROOT_DEV="${ROOT_DEV_RAW%[*}"
```

`findmnt` queries the kernel's mount table for information about a mount point.

- `-n` — no header row, just the data.
- `-o SOURCE` — output only the source column (the device that's mounted).
- `/` — the mount point to query.

On a BTRFS subvolume system, the output is not a clean device path. It looks like:
```
/dev/nvme0n1p2[/@]
```
The `[/@]` part is the subvolume path appended in brackets. The kernel reports it this way to show that it's the `@` subvolume of the device, not the raw partition.

- `${ROOT_DEV_RAW%[*}` — bash **suffix stripping**. The `%` means "strip the shortest match of the pattern from the end of the string". The pattern is `[*`: a literal `[` followed by any characters. So `[/@]` is stripped, leaving just `/dev/nvme0n1p2`. The result is always a clean block device path.

#### Block device validation

```bash
if [[ ! -b "$ROOT_DEV" ]]; then
    log_error "Device '${ROOT_DEV}' is not a valid block device."
    exit 1
fi
```

After stripping the subvolume notation, verifies the result is an actual block device with `-b`. If the stripping produced something unexpected, this catches it before `blkid` runs on a garbage path.

#### Reading the PARTUUID

```bash
set +e
ROOT_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_DEV")
set -e

if [[ -z "${ROOT_PARTUUID:-}" ]]; then
    log_error "Could not determine PARTUUID for ${ROOT_DEV}."
    exit 1
fi
```

`blkid` reads partition metadata from the device.

- `-s PARTUUID` — show only the `PARTUUID` attribute, filtering out everything else (`UUID`, `TYPE`, `LABEL`, etc.).
- `-o value` — output only the value, not the `PARTUUID=` key. Result is just the UUID string, e.g. `4a3b2c1d-0000-0000-0000-abcdef012345`.
- `set +e` / `set -e` — `blkid` can exit non-zero if the attribute doesn't exist or on a read error. Without temporarily disabling `set -e`, a missing PARTUUID would abort the whole script before the check below can produce a useful error message.

**PARTUUID vs UUID — why PARTUUID here:**
- **UUID** is a property of the *filesystem*, created by `mkfs` when the partition is formatted.
- **PARTUUID** is a property of the *GPT partition entry*, created when the partition was written in `cfdisk`.
- The bootloader needs to identify the root partition at a point when the kernel hasn't mounted any filesystems yet — it uses PARTUUID because the GPT table is readable before the filesystem is opened.

`${ROOT_PARTUUID:-}` — the `:-` substitution provides an empty string if the variable is unset, protecting against `set -u` crashing on an unset variable when `blkid` returned nothing.

---

### Detecting Microcode

```bash
UCODE_LINE=""
if [[ -f /boot/intel-ucode.img ]]; then
    UCODE_LINE="initrd  /intel-ucode.img"
    log_info "Intel microcode detected."
elif [[ -f /boot/amd-ucode.img ]]; then
    UCODE_LINE="initrd  /amd-ucode.img"
    log_info "AMD microcode detected."
fi
```

Checks whether a microcode image was actually placed in `/boot` by `pacstrap` (from `intel-ucode` or `amd-ucode`). Rather than hard-coding a specific CPU vendor, it detects by file existence. If neither image is present (VM, unknown hardware), `UCODE_LINE` stays as an empty string and no microcode line will appear in the boot entry.

The value stored is a complete `initrd` line, ready to drop directly into the boot entry file — no formatting needed at the point of use.

---

### Writing the Boot Entry

```bash
{
    printf "title   Arch Linux\n"
    printf "linux   /vmlinuz-linux\n"
    [[ -n "$UCODE_LINE" ]] && printf "%s\n" "$UCODE_LINE"
    printf "initrd  /initramfs-linux.img\n"
    printf "options root=PARTUUID=%s rw rootfstype=btrfs rootflags=subvol=@ loglevel=3 zswap.enabled=0\n" "$ROOT_PARTUUID"
} > /boot/loader/entries/arch.conf
```

#### `{ ... } > file` command group

The `{ }` braces form a **command group** — all the commands inside run in the current shell (not a subshell), with their collective stdout redirected to `arch.conf`. This is the clean way to write a file with mixed static and conditional content: everything inside contributes to the output, the conditional `&&` line is included or skipped naturally, and there's only one `>` redirection at the end.

#### Boot entry fields

- `title Arch Linux` — the name displayed in the boot menu.
- `linux /vmlinuz-linux` — path to the kernel image. All paths in a boot entry are **relative to the ESP root** (`/boot/`). systemd-boot only reads from the ESP filesystem (FAT32) and never touches BTRFS, which is why this works even before any Linux filesystem drivers are loaded.
- `initrd /intel-ucode.img` (conditional) — the microcode update image. systemd-boot supports multiple `initrd` lines and loads them all into RAM in order. The kernel processes them sequentially: the microcode image is handled first, patching the CPU before the initramfs environment starts. This is **early microcode loading** — more effective than late loading because the CPU is fixed before any significant code runs.
- `initrd /initramfs-linux.img` — the main initramfs built by `mkinitcpio`. Extracted into RAM as a temporary root filesystem to run the hooks that mount the real BTRFS partition.

#### Kernel options line

```
options root=PARTUUID=<uuid> rw rootfstype=btrfs rootflags=subvol=@ loglevel=3 zswap.enabled=0
```

These are the **kernel command line parameters** — arguments passed directly to the Linux kernel at boot:

- `root=PARTUUID=<uuid>` — identifies the root partition by its PARTUUID. The kernel uses this to know which block device to mount as `/`. Using PARTUUID here (rather than `/dev/nvme0n1p2`) means the boot entry stays correct even if drive enumeration order changes.
- `rw` — mount the root filesystem read-write from the start. The alternative `ro` mounts it read-only initially (sometimes used with fsck), but since we're skipping fsck (`fsck.mode=skip` is implied by the hook removal from mkinitcpio), `rw` is correct.
- `rootfstype=btrfs` — explicitly tells the kernel which filesystem driver to use for the root device. Without this, the kernel probes the device to detect the filesystem type, which takes extra time and could theoretically fail.
- `rootflags=subvol=@` — passes mount flags to the root filesystem. `subvol=@` tells the BTRFS driver to mount the `@` subvolume as root, not the top-level BTRFS namespace. Without this, BTRFS would mount its top-level and `@` would appear as a subdirectory — the system wouldn't boot correctly.
- `loglevel=3` — controls kernel message verbosity. Level 3 means only `err` (errors) and above (`crit`, `alert`, `emerg`) are printed to the console. The default is `7` (everything including debug). Level 3 gives a clean boot screen — no scrolling walls of hardware detection text — while still showing anything genuinely wrong.
- `zswap.enabled=0` — disables **zswap**, the kernel's built-in compressed swap cache. zswap intercepts swap writes, compresses them, and stores them in RAM before they hit actual swap storage. The problem: since we're configuring ZRAM in `009_zram_config.sh` (which is already compressed swap in RAM), zswap would add a redundant second layer of compression on top, wasting CPU and memory. Disabling it ensures ZRAM operates cleanly without interference.

---

### Auto-update Service

```bash
systemctl enable systemd-boot-update.service 2>/dev/null || true
```

Enables a systemd service that automatically copies the latest systemd-boot EFI binary to the ESP whenever the `systemd` package is upgraded. Without this, a `pacman -Syu` that updates systemd updates the binary at `/usr/lib/systemd/boot/efi/systemd-bootx64.efi` but leaves the older copy on the ESP untouched — the firmware keeps booting the old version until someone manually runs `bootctl update`.

- `2>/dev/null` — suppresses output if the service isn't found.
- `|| true` — prevents `set -e` from aborting if the service doesn't exist on older systemd versions. Silently skips.

---

## `templates/arch_iso/post_chroot/008_grub.sh`

This script is the **BIOS fallback bootloader**. It only runs if `007_systemd_boot.sh` did not install systemd-boot — making it self-aware. On UEFI systems it exits immediately and cleanly; on BIOS systems it installs GRUB.

---

### Detecting systemd-boot (Two Checks)

```bash
if [[ -f /boot/loader/loader.conf ]]; then
    log_ok "systemd-boot already configured. Skipping GRUB."
    exit 0
fi

if command -v bootctl &>/dev/null && bootctl is-installed &>/dev/null; then
    log_ok "systemd-boot detected. Skipping GRUB."
    exit 0
fi
```

Two independent checks, both exiting with `0` — skipping is not an error.

- **First check** — `[[ -f /boot/loader/loader.conf ]]`: the fastest possible test. If the loader config file exists, systemd-boot was installed by the previous script. No subprocess, no tool needed.
- **Second check** — a more thorough confirmation for edge cases where the file might be missing but systemd-boot is still registered in UEFI NVRAM. `command -v bootctl` confirms the tool is available, then `bootctl is-installed` queries both the ESP and NVRAM. The `&&` short-circuits — if `bootctl` isn't found, the second command never runs.

Both checks use `exit 0` because on a UEFI system, this script is supposed to do nothing. The orchestrator sees a clean exit and marks it complete.

---

### Installing GRUB

```bash
pacman -S --needed --noconfirm grub
```

Installs the GRUB package, which provides `grub-install` and `grub-mkconfig`.

---

### Detecting the Target Disk

```bash
ROOT_DEV=$(findmnt / -o SOURCE -n)
```

Same concept as `007_systemd_boot.sh` — finds which block device is mounted at `/`. Note the argument order here differs slightly from `007` (`findmnt / -o SOURCE -n` vs `findmnt -n -o SOURCE /`) — both are valid, the mount point can go anywhere in the argument list.

GRUB on BIOS installs to the **disk's MBR**, not the partition. So the partition path needs to be stripped back to the parent disk:

```bash
if [[ "$ROOT_DEV" =~ nvme|mmcblk ]]; then
    TARGET_DISK="${ROOT_DEV%p*}"
else
    TARGET_DISK="${ROOT_DEV%%[0-9]*}"
fi
```

Two different stripping patterns because two different naming conventions exist:

- **NVMe and eMMC** drives (`nvme0n1p2`, `mmcblk0p2`) — the partition is indicated by a `p` followed by a number. `${ROOT_DEV%p*}` strips the shortest match of `p` followed by anything from the end: `nvme0n1p2` → `nvme0n1`.
- **SATA/SCSI** drives (`sda2`, `sdb3`) — the partition is just a trailing digit with no separator. `${ROOT_DEV%%[0-9]*}` strips the **longest** match of any digits followed by anything from the end. `%%` (double percent) is greedy — it strips as much as possible. `sda2` → `sda`.

The `%%` vs `%` distinction matters here: `%` would strip the shortest match and `sda12` might become `sda1` instead of `sda`. `%%` ensures all trailing digits are removed.

---

### `grub-install`

```bash
grub-install --target=i386-pc "$TARGET_DISK"
```

Writes the GRUB bootloader to the disk.

- `--target=i386-pc` — specifies BIOS/MBR mode. Despite the name (`i386`), this works on any 64-bit x86 machine in BIOS mode — it's a historical naming convention from GRUB's architecture. GRUB writes a small stage 1 loader to the MBR (the first 512 bytes of the disk) and its larger stage 2 core image either to the 1MB gap between MBR and the first partition (MBR-partitioned disks) or to the dedicated BIOS Boot partition (GPT-partitioned disks, created in `003_partitioning.sh`).
- `"$TARGET_DISK"` — the parent disk (`/dev/sda`, `/dev/nvme0n1`), not a partition. GRUB writes to the disk's boot sector, not a partition.

---

### `grub-mkconfig`

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

Generates GRUB's configuration file. Unlike systemd-boot which uses hand-authored entry files, GRUB uses a generated config produced by this tool.

- `grub-mkconfig` scans for installed kernels in `/boot`, detects other operating systems, reads `/etc/default/grub` for settings, and writes a complete `grub.cfg`.
- `-o /boot/grub/grub.cfg` — output path. Without this, it prints to stdout.

---

## `templates/arch_iso/post_chroot/009_zram_config.sh`

This script configures **ZRAM** — compressed swap in RAM. Instead of writing overflow memory pages to a slow disk, the kernel writes them to a compressed block device that lives entirely in RAM. The result is swap that's orders of magnitude faster than SSD swap, at the cost of some CPU time for compression and decompression.

---

### What ZRAM is

When the kernel decides a memory page hasn't been used recently enough to keep in RAM, it normally writes it to a swap partition or file on disk. With ZRAM, the kernel instead writes it to a virtual block device (`/dev/zram0`) that compresses the data using zstd and stores it in a reserved portion of RAM. The tradeoffs:

- **Pro:** Vastly faster than any disk — even NVMe. Reading a compressed page from RAM takes microseconds; reading from SSD takes milliseconds.
- **Pro:** Compression means you get more effective swap capacity than the RAM reserved. 2GB of ZRAM can hold 4–6GB of compressible data.
- **Con:** CPU overhead for every swap-in/swap-out — mitigated by zstd being fast.
- **Con:** Still uses RAM. On a 4GB system, 4GB of ZRAM means the kernel can technically address 4GB × compression_ratio of memory, but the physical RAM is still 4GB.

The `zram-generator` package (installed in `005_package_installer.sh`) reads this configuration file and creates and configures the ZRAM device automatically at boot via systemd.

---

### Constants

```bash
readonly THRESHOLD_KB=8388608  # 8 GiB in KiB
readonly CONFIG="/etc/systemd/zram-generator.conf"
```

- `8388608` = 8 × 1024 × 1024 = 8 GiB expressed in kibibytes (the unit `/proc/meminfo` uses). Using a `readonly` constant makes the intent clear and prevents accidental modification.
- `/etc/systemd/zram-generator.conf` — the path `zram-generator` reads. It lives under `/etc/systemd/` because `zram-generator` is a systemd component.

---

### Reading System Memory — Pure Bash

```bash
get_total_ram_kb() {
    local key val unit
    while read -r key val unit; do
        if [[ "$key" == "MemTotal:" ]]; then
            echo "$val"
            return 0
        fi
    done < /proc/meminfo
    return 1
}
```

Reads the total RAM from the kernel's `/proc/meminfo` file using only bash built-ins — no `grep`, no `awk`, no subprocesses.

- `while read -r key val unit` — reads one line at a time from `/proc/meminfo`. Each line has the format `MemTotal:       16384000 kB`. The three variables capture the field name, the value, and the unit.
- `< /proc/meminfo` — the input redirection feeds the entire file into the `while` loop. This is more efficient than piping through `cat` because it avoids a subprocess.
- `[[ "$key" == "MemTotal:" ]]` — matches the specific line. The `:` is part of the key name as it appears in the file.
- `echo "$val"` + `return 0` — outputs just the numeric value (in kB) and exits successfully. The `return 1` at the bottom handles the case where `MemTotal:` wasn't found.

**Why pure bash?** No external tools needed, which matters in minimal or early boot environments. It's also faster — no process fork for grep/awk.

The function is called with error handling:

```bash
total_mem_kb=$(get_total_ram_kb) || { log_error "Cannot read /proc/meminfo"; exit 1; }
total_mem_gb=$(( total_mem_kb / 1024 / 1024 ))
```

- `|| { ...; }` — command group runs only if the function returns non-zero (couldn't find `MemTotal:`). Hard exit since sizing without knowing RAM is impossible.
- `$(( total_mem_kb / 1024 / 1024 ))` — integer arithmetic. kB → MB → GB, using two integer divisions. The result is approximate (rounds down) which is fine for display and comparison purposes.

---

### Sizing Logic

```bash
if (( total_mem_kb > THRESHOLD_KB )); then
    zram_size="ram - 2000"
else
    zram_size="ram"
fi
```

- **More than 8GB RAM:** `zram_size="ram - 2000"` — `zram-generator`'s own expression syntax where `ram` is a variable meaning total physical RAM in MiB. This creates a ZRAM device that is `(total_RAM_in_MiB - 2000) MiB`. On a 16GB system: ~14GB of ZRAM. The 2000MB is kept as uncompressed RAM headroom so the system doesn't end up compressing everything.
- **8GB or less:** `zram_size="ram"` — use the full RAM amount for ZRAM. Low-memory systems benefit more from maximum swap capacity.

These strings are passed verbatim into the config file — `zram-generator` evaluates the expression `ram - 2000` itself at boot time using the actual runtime RAM value.

---

### Writing the Configuration

```bash
cat > "$CONFIG" <<EOF
[zram0]
zram-size = ${zram_size}
compression-algorithm = zstd
EOF
```

A heredoc writing to the config file. The format is systemd's standard `.conf` syntax:

- `[zram0]` — the section header. `zram0` is the name of the device that will be created (`/dev/zram0`). Additional sections (`[zram1]`, etc.) would create additional ZRAM devices.
- `zram-size = ${zram_size}` — the size expression evaluated by `zram-generator` at boot. `${zram_size}` expands to either `ram - 2000` or `ram`.
- `compression-algorithm = zstd` — uses zstd for compression. Fast, excellent ratio, and already in use for BTRFS compression — consistent choice throughout the system.

#### Verifying the write

```bash
if [[ -s "$CONFIG" ]]; then
    log_ok "ZRAM configuration written."
else
    log_error "Failed to write ${CONFIG}."
    exit 1
fi
```

`-s` tests that the file exists **and** has a size greater than zero. This is stricter than `-f` (which only checks existence). It guards against a silent failure where the file was created but nothing was written — an empty config would produce no ZRAM at boot with no error message.

---

## `templates/arch_iso/post_chroot/010_services.sh`

The final post-chroot script. It enables the systemd services that need to be running from the first boot. All the packages for these services were installed in `005_package_installer.sh`; this script activates them.

---

### Shell Options — The Missing `-e`

```bash
set -uo pipefail
```

Notice what's absent compared to every other script: **`-e` is not set**. This is intentional and important.

With `set -e`, any command that exits non-zero immediately aborts the entire script. For a service-enabling loop, that would mean one missing or failed service stops all the rest from being enabled. The goal here is to attempt every service and report what failed — not to abort on the first problem. Removing `-e` lets the loop run to completion regardless of individual failures, while `set -u` and `pipefail` still protect against unset variables and broken pipes.

---

### Services List

```bash
readonly SERVICES=(
    "NetworkManager.service"
    "tlp.service"
    "udisks2.service"
    "thermald.service"
    "bluetooth.service"
    "firewalld.service"
    "fstrim.timer"
    "systemd-timesyncd.service"
    "systemd-resolved.service"
)
```

Each service justified:

| Service | Role |
|---|---|
| `NetworkManager.service` | Network management — WiFi, ethernet, VPN. Without this, the system has no internet after reboot. |
| `tlp.service` | Laptop power management. Automatically adjusts CPU governor, disk spindown, and USB power based on AC vs battery. |
| `udisks2.service` | The D-Bus disk management daemon. Allows desktop environments and file managers to auto-mount USB drives and manage removable storage without root. |
| `thermald.service` | Intel thermal management daemon. Coordinates with the kernel to prevent thermal runaway on Intel CPUs, more gracefully than the kernel's own throttling. |
| `bluetooth.service` | The Bluetooth stack daemon. Required for any Bluetooth device to function. |
| `firewalld.service` | Dynamic firewall management. Manages nftables rules with a zone-based policy model, providing a basic network barrier from first boot. |
| `fstrim.timer` | A systemd timer that runs `fstrim` once a week across all mounted filesystems. Sends TRIM commands to SSDs periodically, complementing the continuous `discard=async` mount option. |
| `systemd-timesyncd.service` | NTP time synchronisation. Keeps the system clock accurate. Lightweight alternative to a full NTP daemon — the same sync enabled manually in `002_environment_prep.sh`. |
| `systemd-resolved.service` | The systemd DNS resolver. Provides local DNS caching, DNSSEC validation, and DNS-over-TLS. NetworkManager integrates with it automatically. |

Note that `fstrim.timer` is a **timer unit** (`.timer`), not a service. `systemctl enable` handles both the same way — it creates a symlink in the appropriate wants directory.

---

### Enable Loop

```bash
failed=()

for service in "${SERVICES[@]}"; do
    if ! systemctl cat "$service" &>/dev/null; then
        log_warn "Skipping ${service}: unit not found."
        failed+=("${service} (missing)")
        continue
    fi

    if systemctl enable "$service" --force 2>/dev/null; then
        log_ok "Enabled: ${service}"
    else
        log_error "Failed: ${service}"
        failed+=("${service} (error)")
    fi
done
```

#### Existence check before enabling

```bash
if ! systemctl cat "$service" &>/dev/null; then
```

`systemctl cat` prints the content of a unit file. Its real value here is its exit code — `0` if the unit exists anywhere systemd can find it, non-zero if it doesn't. This is more reliable than checking file paths directly because systemd resolves units from multiple locations (`/usr/lib/systemd/system/`, `/etc/systemd/system/`, etc.).

The check runs first because attempting to `systemctl enable` a non-existent unit produces an error. By pre-checking, the script can distinguish between "unit not found" and "unit found but failed to enable" — two different problems requiring different responses.

#### Two failure modes

```bash
failed+=("${service} (missing)")   # unit not found
failed+=("${service} (error)")     # unit found but enable failed
```

The `failed` array tracks both types separately so the summary is informative. A missing service likely means the package wasn't installed; a failed enable means the unit exists but something is wrong with it.

#### `--force` on enable

`systemctl enable --force` creates the symlinks that mark a service to start at boot, even if those symlinks already exist (it overwrites them). Without `--force`, re-running the script on an already-enabled service is fine, but if a symlink pointed somewhere unexpected, the enable would fail. `--force` makes the operation idempotent.

---

### Summary

```bash
if [[ ${#failed[@]} -eq 0 ]]; then
    log_ok "All services enabled successfully."
else
    log_warn "Completed with ${#failed[@]} issue(s):"
    for f in "${failed[@]}"; do
        printf "  - %s\n" "$f"
    done
    exit 1
fi
```

- `${#failed[@]} -eq 0` — checks whether the failed array is empty (zero elements).
- If failures exist, prints each one by name with its failure type, then exits with code `1`. This signals to the orchestrator that the script failed, triggering the retry/skip/abort prompt. The detailed list tells the user exactly which services need attention before they decide whether to retry.

---

---

## POST-CHROOT NOTES

Your assessment is **broadly correct**. The majority of the post-chroot scripts replicate what `archinstall` handles for you automatically:

| Script | What it does | `archinstall` covers it? |
|---|---|---|
| `003_post_chroot.sh` | Timezone, locale, hostname, user, sudo | ✓ fully |
| `004_mkinitcpio_config.sh` | Custom initramfs hooks | Partially — different hook set |
| `005_package_installer.sh` | Install packages | ✓ has a package selection step |
| `007_systemd_boot.sh` | systemd-boot install + boot entry | ✓ on UEFI |
| `008_grub.sh` | GRUB for BIOS | ✓ on BIOS |
| `009_zram_config.sh` | ZRAM compressed swap | ✗ not configured by archinstall |
| `010_services.sh` | Enable services | Partial — not all services guaranteed |

The genuine post-chroot gaps left by `archinstall` that are worth doing manually after rebooting:
- `009_zram_config.sh` — ZRAM is not set up by archinstall at all
- `010_services.sh` — specifically `fstrim.timer` and `paccache.timer`; archinstall enables the obvious ones (NetworkManager, etc.) but not the maintenance timers
- `004_mkinitcpio_config.sh` — archinstall generates a working initramfs but with the older busybox-based hooks (`udev`, `keyboard`, `keymap`) rather than the systemd-based set (`systemd`, `sd-vconsole`). The systemd hook set boots faster and integrates better with the rest of the system. This is optional but worth knowing.

---

#### Response

##### 1. `systemctl enable systemd-boot-update.service` — Can It Be Done After Login?

**Yes, entirely.** This is a service enablement on an already-installed system — there is nothing chroot-specific about it. You can run it at any point after first boot:

```bash
systemctl enable systemd-boot-update.service 2>/dev/null || true
```

The service watches for updates to the `systemd` package and keeps the EFI binary on the ESP in sync. Without it:

1. `pacman -Syu` updates `/usr/lib/systemd/boot/efi/systemd-bootx64.efi` (the source binary).
2. The older copy at `/boot/EFI/systemd/systemd-bootx64.efi` (on the ESP) stays untouched.
3. Firmware boots the old binary indefinitely until someone runs `bootctl update` manually.

With the service enabled, pacman triggers `bootctl update` automatically via a pacman hook whenever systemd is upgraded. You never have to think about it again.

Since archinstall installs systemd-boot on UEFI systems, this service is relevant to you. Enable it on first login after the `archinstall` setup is done.

---

##### 2. Boot Options Explained: `root=PARTUUID=... rw rootfstype=btrfs rootflags=subvol=@ loglevel=3 zswap.enabled=0`

These are kernel parameters — passed from the bootloader to the kernel at boot time, controlling how the kernel mounts the root filesystem and configures itself.

**Are they archinstall's defaults?** Mostly yes, with two exceptions: `loglevel=3` and `zswap.enabled=0` are not set by archinstall.

---

###### `root=PARTUUID=<uuid>`

**What it does:** Tells the kernel which partition contains the root filesystem. PARTUUID is the UUID assigned to the partition slot in the GPT partition table — distinct from the filesystem UUID (which is what `UUID=` refers to).

**Why PARTUUID over other options:**

| Identifier | Example | Stable across? |
|---|---|---|
| Device path | `root=/dev/sda2` | ✗ changes if you add a drive |
| Filesystem UUID | `root=UUID=...` | ✓ stable unless you reformat |
| PARTUUID | `root=PARTUUID=...` | ✓ stable, set when partition was created |

PARTUUID is preferred because it's assigned at partition creation and doesn't change even if you reformat the filesystem inside that partition. Both archinstall and this script use PARTUUID.

**Alternatives:** None better for a standard setup. Keep PARTUUID.

---

###### `rw`

**What it does:** Mounts the root filesystem read-write at boot. The alternative is `ro`, which mounts read-only initially and relies on a later systemd unit to remount it read-write.

**Is this archinstall's default?** Yes.

**The `ro` alternative:** Some distributions (Ubuntu, Fedora) prefer starting with `ro` for cleaner fsck integration — if the filesystem needs checking, it can be done before the RW mount. On Arch with a properly functioning fstab, `rw` is standard and fine. Switching to `ro` on a working system provides minimal benefit.

**Recommendation:** Keep `rw`.

---

###### `rootfstype=btrfs`

**What it does:** Explicitly tells the kernel the root filesystem type. Without it, the kernel probes available filesystem drivers in sequence until one succeeds.

**Is this archinstall's default?** Yes for BTRFS installs.

**Pros:** Slightly faster mount (skips probing), makes the boot entry self-documenting.

**Cons:** None — BTRFS support is always compiled into the Arch kernel, so there's no risk of it not being found.

**Recommendation:** Keep it.

---

###### `rootflags=subvol=@`

**What it does:** Tells BTRFS which subvolume to mount as `/`. Without this flag, BTRFS mounts the top-level subvolume (ID 5) — the container that holds all your named subvolumes (`@`, `@home`, etc.) — not `@` itself. The system wouldn't boot correctly without it.

**Is this archinstall's default?** Yes — archinstall uses `@` as the root subvolume name by convention. If you chose BTRFS in archinstall, your boot entry already has `rootflags=subvol=@`.

**Alternatives:** None. This must match whatever name you gave the root subvolume during partitioning.

---

###### `loglevel=3`

**What it does:** Sets the kernel's console log verbosity. The scale is 0–7:

| Level | Name | Shows |
|---|---|---|
| 0 | Emergency | System is unusable |
| 1 | Alert | Action must be taken |
| 2 | Critical | Critical conditions |
| 3 | Error | Error conditions only |
| 4 | Warning | Warning conditions (kernel default) |
| 5 | Notice | Normal but significant |
| 6 | Info | Informational |
| 7 | Debug | Everything |

Level 3 means only actual errors are printed to the console at boot. Warnings, informational messages, and normal hardware detection text are suppressed from the screen — but still written to the kernel ring buffer, so `journalctl -k` still shows everything.

**Is this archinstall's default?** No. archinstall typically uses `loglevel=5` or leaves the kernel default of 4. Level 3 is a deliberate aesthetic preference — a much quieter boot.

**Pros of loglevel=3:** Clean boot screen. No scrolling wall of hardware detection text.

**Cons:** You might miss a non-fatal warning that indicates something worth investigating. It's still in journalctl — just not on screen.

**Alternatives:**

| Value | Best for |
|---|---|
| `loglevel=3` | Clean desktop, quiet boot |
| `loglevel=4` | Default — balanced visibility |
| `loglevel=5` | Seeing normal operation messages |
| `loglevel=7` | Debugging boot problems |
| `quiet` | Fully silent boot (pair with loglevel=3) |

**Recommendation:** `loglevel=3` is a good choice for a working desktop. If you're troubleshooting, press `e` in the systemd-boot menu at boot to temporarily edit the entry and bump it up.

---

###### `zswap.enabled=0`

**What it does:** Disables zswap — the kernel's built-in compressed swap cache. Zswap intercepts swap writes and compresses them in RAM before sending to the actual swap device, transparently decompressing on reads.

**Is this archinstall's default?** No. archinstall doesn't set it — zswap is enabled by default in the Arch kernel.

**Why it's set here:** This script pairs with `009_zram_config.sh`, which sets up ZRAM. Both zswap and ZRAM compress data in RAM, but at different layers:

- **zswap** intercepts swap writes at the kernel memory management layer before they reach any swap device
- **ZRAM** is a block device — it acts like a swap partition, stored in compressed RAM

If both are active simultaneously: a page being swapped out hits zswap first (compressed in RAM), then zswap may later write it to the ZRAM device (compressed again). Double compression, wasted CPU, more complex memory management path — all for no benefit.

**With ZRAM: disable zswap. Without ZRAM: leave zswap enabled — it's useful on its own.**

**Recommendation:** Keep `zswap.enabled=0` if you're using ZRAM. If you decide not to use ZRAM at all (valid with 32GB RAM), remove this parameter.

---

##### 3. ZRAM Configuration for 32GB RAM

**What the script sets for you:**

The script reads `/proc/meminfo`, sees 32GB, and since that's above the 8GB threshold:

```bash
zram-size = ram - 2000   # ≈ 30GB uncompressed capacity
```

This gives you a ZRAM device that can hold up to ~30GB of **uncompressed** data. The critical thing to understand is that this is a **ceiling**, not a reservation. ZRAM only consumes actual RAM for data that has actually been swapped into it — and that data is compressed (typically 2:1 to 4:1 ratio for general workloads). An empty 30GB ZRAM device costs essentially nothing.

**So is 30GB too much?**

Not harmful, but more capacity than you'll ever need with 32GB of RAM. For ZRAM to hold 30GB of compressed data, the kernel would need to have swapped out ~30GB of pages — meaning your system would need to have exhausted all 32GB of physical RAM and then some. On a desktop with 32GB, this is an extremely unlikely scenario.

**What the Arch wiki recommends for 32GB:**

The general guidance is ~50% of RAM for systems with more than 16GB — around **16GB** for your setup. This gives a more than adequate safety net.

**Realistic scenarios on 32GB:**

| Usage | Physical RAM used | ZRAM likely used |
|---|---|---|
| Normal desktop (browser, editor, terminal) | 6–12GB | ~0 |
| Heavy usage (VMs, many tabs, dev tools) | 18–24GB | A few GB at most |
| Extreme (ML training, many containers) | 28–32GB | Possibly 4–8GB |

Even in the extreme case, 8GB of ZRAM is plenty. At a 3:1 compression ratio, 8GB of ZRAM can store ~24GB worth of pages.

**Recommendation for 32GB:**

Change `zram-size` to something more proportionate. Either a formula that caps out:

```ini
[zram0]
zram-size = min(ram / 2, 8192)
```

Or simply a fixed value:

```ini
[zram0]
zram-size = 8192
```

8GB of ZRAM (consuming ~2–4GB of actual RAM under compression) is a solid safety net for a 32GB system. The script's `ram - 2000` formula is reasonable for unknown hardware in general, but overcorrects at the high end.

**What archinstall does:** Nothing — archinstall does not configure ZRAM. This is one of the few genuinely useful additions from the post-chroot scripts regardless of whether you used archinstall.

---

##### 4. zswap vs ZRAM — Which Is Better, and Can You Switch After Login?

**The short answer: ZRAM is the better choice for a modern desktop.**

Both solve the same problem — reducing or eliminating disk I/O for swap by keeping compressed data in RAM — but they operate differently and can't coexist usefully.

---

###### How They Differ

**zswap** is a kernel-level write-back cache that sits *in front of* an existing swap device. When the kernel wants to swap out a page, zswap intercepts it, compresses it in RAM, and stores it in a pool. Only when the zswap pool is full does it evict compressed pages to the actual swap device (disk). Reads that hit the zswap pool return data directly from RAM without touching the disk.

Key constraint: **zswap requires a backing swap device** — a swap partition or swap file on disk. It can't operate standalone.

**ZRAM** is a block device driver that creates a virtual block device backed entirely by compressed RAM. You configure it as a swap device the normal way (`swapon`), and the kernel doesn't know or care that it's backed by RAM rather than disk — it just swaps pages there. No disk is involved at all unless ZRAM itself fills up, at which point the kernel starts returning OOM errors (unless you also have a disk swap as a secondary fallback).

---

###### Side-by-side Comparison

| | zswap | ZRAM |
|---|---|---|
| Requires a disk swap device | ✓ yes | ✗ no |
| Eliminates disk I/O for swap | Partially (reduces it) | ✓ fully (for pages in ZRAM) |
| Configurable size | Indirect (% of RAM, default 20%) | ✓ direct |
| Works standalone | ✗ needs disk swap | ✓ yes |
| Kernel overhead | Low (cache layer) | Low (block device) |
| Default on Arch kernel | ✓ enabled | ✗ not configured |
| Used by Android / ChromeOS | ✗ | ✓ |
| Used by modern Fedora / Ubuntu | ✗ | ✓ (default since ~2022) |

**Winner for a desktop:** ZRAM. It eliminates disk swap entirely, is fully configurable, and has become the community default for a reason. zswap's main advantage — reducing writes to a slow spinning disk — is less relevant on a machine where the only drive is a fast SSD and you have plenty of RAM to begin with.

---

###### Can You Switch After Login?

**Yes — both can be changed at runtime, and made permanent without reinstalling.**

**Disabling zswap at runtime** (takes effect immediately, no reboot needed):
```bash
echo 0 | sudo tee /sys/module/zswap/parameters/enabled
```
To make it permanent: add `zswap.enabled=0` to your kernel parameters in the boot entry (or in `/etc/kernel/cmdline` if you use a UKI).

**Enabling ZRAM** (after installing `zram-generator`):
```bash
sudo pacman -S zram-generator
sudo nvim /etc/systemd/zram-generator.conf
# Add:
# [zram0]
# zram-size = 8192
# compression-algorithm = zstd

sudo systemctl daemon-reload
sudo systemctl start /dev/zram0
```
Verify it's active:
```bash
zramctl          # shows ZRAM devices and compression stats
swapon --show    # confirms it's registered as swap
```

**Going the other way — disabling ZRAM and re-enabling zswap:**
```bash
sudo swapoff /dev/zram0
sudo systemctl stop /dev/zram0
# Remove or empty /etc/systemd/zram-generator.conf
echo 1 | sudo tee /sys/module/zswap/parameters/enabled
# Also ensure a disk swap device exists for zswap to back onto
```

Both switches are fully reversible and non-destructive. You're just changing which layer handles swap pressure — the kernel adapts immediately.

**One thing you can't do: run both productively.** If zswap is enabled and ZRAM is your swap device, pages get compressed by zswap in RAM, then zswap writes them to ZRAM, which compresses them again. Double compression pass, double CPU overhead, no benefit. This is exactly why `009_zram_config.sh` pairs with the `zswap.enabled=0` kernel parameter.

---

##### 5. Services for a Desktop — tlp, firewalld, and ufw

Your instinct on both is correct.

---

###### `tlp.service` — Skip It on a Desktop

TLP is a **laptop power management tool**. It automatically adjusts CPU governor, Wi-Fi power saving, disk spindown, USB autosuspend, and PCI power management based on whether the machine is on AC or battery. On a laptop this is genuinely useful — it extends battery life without you having to think about it.

On a desktop there is no battery, no AC/battery transition logic to manage, and TLP has nothing meaningful to do. Enabling it on a desktop is harmless but pointless — it will apply some power management rules that either have no effect or could marginally reduce performance for no gain.

**Verdict: do not enable `tlp.service` on a desktop.** If you ever switch to a laptop, add it then.

The only desktop-relevant power tool in a similar category is `auto-cpufreq`, which adjusts CPU frequency scaling based on load. But even that's optional — most desktop users are fine leaving the CPU governor at `schedutil` (the default on modern kernels).

---

###### `thermald.service` — Context-Dependent

`thermald` is Intel's thermal management daemon. It monitors CPU temperature sensors and proactively throttles CPU activity before the hardware emergency throttle kicks in — aiming for quieter, more consistent thermal behavior.

On a **laptop**: genuinely useful, especially on thin chassis where thermal headroom is tight.
On a **desktop with adequate cooling**: less necessary. The hardware's own thermal throttle (and a decent cooler) typically handles it fine without software intervention.
On an **AMD CPU**: `thermald` is Intel-specific. It either does nothing on AMD or isn't available.

**Verdict:** Optional on a desktop. Include it if you have an Intel CPU and want proactive thermal management. Skip it on AMD.

---

###### `firewalld.service` vs `ufw.service` — Pick One, Not Both

Both firewalld and ufw are **frontends for the same kernel netfilter subsystem**. Under the hood they both write rules to nftables (or iptables on older kernels). If you enable both, they'll fight over the same ruleset and produce unpredictable results. You pick one.

**What firewalld does:**
- Zone-based model: each network interface is assigned to a zone (e.g. `home`, `public`, `trusted`), and each zone has its own ruleset
- Dynamic: rules can be changed without a full restart
- NetworkManager integration: automatically reassigns zones when you switch networks (e.g. wired → Wi-Fi → VPN)
- More complex, more powerful — designed for systems that move between networks or need per-interface policies

**What ufw does:**
- Simpler, more direct syntax: `ufw allow ssh`, `ufw deny 3306/tcp`, `ufw allow from 192.168.1.0/24`
- No zone concept — one flat ruleset applied to all interfaces
- Optional GUI: `gufw` for a graphical interface
- Less configuration needed for standard desktop use

**For your use case (desktop, straightforward firewall needs):**

ufw is the better fit. The zone system of firewalld is designed for machines that roam between networks — on a desktop plugged into one network it adds complexity without benefit.

To replace `firewalld.service` with ufw:

```bash
# Install
sudo pacman -S ufw

# Set default policy: block all incoming, allow all outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow whatever you actually need (examples)
sudo ufw allow ssh          # if you run sshd
sudo ufw allow 80/tcp       # HTTP
sudo ufw allow 443/tcp      # HTTPS

# Enable and start
sudo ufw enable
sudo systemctl enable ufw
```

Verify status:
```bash
sudo ufw status verbose
```

**One thing to know about `systemd-resolved` and ufw:** If you enable `systemd-resolved` (which routes DNS queries through a local stub resolver at `127.0.0.53`), make sure your ufw rules don't accidentally block outbound DNS (port 53 UDP/TCP). The default `allow outgoing` policy handles this automatically.

**Also worth knowing:** On a home desktop behind a NAT router, you're already protected from unsolicited inbound connections by the router itself — it drops packets that don't correspond to outbound connections you initiated. A local firewall on the desktop is a second layer of defense, most useful for:
- Blocking specific outbound connections from applications you don't trust
- Restricting which local services are reachable from your LAN
- Preparation for when you move the machine somewhere with less network control

Running ufw with the default deny-incoming policy is a sensible baseline regardless.

---

###### Revised Service List for Your Desktop

| Service | Keep? | Notes |
|---|---|---|
| `NetworkManager.service` | ✓ | Essential |
| `tlp.service` | ✗ | Laptop only — skip |
| `udisks2.service` | ✓ | Needed for file manager automounting |
| `thermald.service` | ✓/? | Keep if Intel CPU, skip if AMD |
| `bluetooth.service` | ✓/? | Only if you have Bluetooth hardware |
| `firewalld.service` | ✗ | Replace with ufw |
| `ufw.service` | ✓ | Your firewall of choice |
| `fstrim.timer` | ✓ | Weekly TRIM — essential for SSD health |
| `systemd-timesyncd.service` | ✓ | NTP — keep |
| `systemd-resolved.service` | ✓ | DNS resolver — keep |

---

---

## `templates/arch_setup/ORCHESTRA.sh`

This is the **entry point for the third and final installation phase** — the post-reboot setup that runs as a normal logged-in user on the new system. Unlike the ISO orchestrators (which ran from a live environment as root and tracked state only in memory), this orchestrator is designed for a real session: it persists progress to a file so it can resume after interruptions, keeps sudo credentials refreshed automatically, supports per-script sudo/user execution modes, and writes a timestamped log file for every run.

---

### Configuration

```bash
SCRIPT_SEARCH_DIRS=(
    "$(dirname "$(readlink -f "$0")")"
)

STATE_FILE="/tmp/orchestra_state"
LOG_FILE="/tmp/orchestra_$(date +%Y%m%d_%H%M%S).log"
SUDO_REFRESH_INTERVAL=60
```

**`SCRIPT_SEARCH_DIRS`** is an array of directories to search when resolving a script name to a full path. The first entry uses the same `dirname "$(readlink -f "$0")"` pattern from the ISO orchestrator — it resolves to the directory containing ORCHESTRA.sh itself, regardless of symlinks or from where it's called. The commented-out second entry shows how you'd add other search paths (e.g. a system-wide location), making the setup extensible without changing how scripts are invoked.

**`STATE_FILE="/tmp/orchestra_state"`** — a simple text file where each completed script entry is recorded as a line. This is what enables resume: if the orchestrator is interrupted (crash, reboot, manual kill), re-running it reads this file and skips everything already listed. The ISO orchestrators used in-memory arrays (`EXECUTED`, `FAILED`, `SKIPPED`) that were lost on exit; this file survives across runs.

**`LOG_FILE`** — every `log()` call writes to both the terminal and this file simultaneously. The filename embeds a timestamp (`date +%Y%m%d_%H%M%S`) so each run produces its own log rather than overwriting the previous one. Useful for diagnosing what happened in a failed run after the fact.

**`SUDO_REFRESH_INTERVAL=60`** — controls how often the background sudo keepalive fires. See the sudo section below.

---

### Install Sequence Format

```bash
INSTALL_SEQUENCE=(
    # "U | 005_example_user_script.sh"
    # "S | 010_example_sudo_script.sh --auto"
)
```

Each entry is a string in the format `"MODE | scriptname.sh [args...]"`:

- **`S`** — run this script with `sudo bash`. Use for anything that needs root: installing packages, writing system config, enabling services.
- **`U`** — run as the current user. Use for user-level config: dotfiles, user services, AUR helpers.
- Arguments after the script name are passed through (e.g. `--auto` to make a subscript non-interactive).

The sequence is intentionally empty in this template — you populate it with your own scripts. Numbering by tens (`005`, `010`, `020`) is a convention that leaves room to insert scripts between existing ones without renumbering.

---

### Globals

```bash
AUTO_MODE=false
SUDO_REFRESH_PID=""
```

`AUTO_MODE=false` — uses the bare word `false`, not a string `"0"` or `"false"`. In bash, `false` is an actual built-in command that always exits non-zero. This means `if $AUTO_MODE` literally runs the `false` command and checks its exit code — so the if-branch is never entered. When set to `true` (another built-in that always exits zero), `if $AUTO_MODE` always enters the branch. This is a cleaner boolean pattern than comparing strings.

`SUDO_REFRESH_PID=""` — initialized empty; will hold the PID of the background sudo refresh process so it can be killed on exit.

---

### Helpers

```bash
log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

die() {
    log "FATAL: $*"
    exit 1
}
```

**`log()`** — prefixes every message with the current time (`HH:MM:SS`) and uses `tee -a` to append to the log file while also printing to stdout. `$*` expands all arguments as a single string (appropriate here since log messages are just text).

**`die()`** — a convenience wrapper that logs a fatal message then exits with code `1`. Used anywhere a condition is unrecoverable (missing script, bad argument, sudo failure).

```bash
resolve_script() {
    local name="$1"
    for dir in "${SCRIPT_SEARCH_DIRS[@]}"; do
        if [[ -f "$dir/$name" ]]; then
            echo "$dir/$name"
            return 0
        fi
    done
    return 1
}
```

Loops through `SCRIPT_SEARCH_DIRS` and returns the full path of the first matching file. Returning `1` on no match lets the caller detect failure: `script_path="$(resolve_script "$script_name")" || die "..."`. The separation of "find the script" from "run the script" makes the search logic easy to extend — add more directories to `SCRIPT_SEARCH_DIRS` and `resolve_script` handles them automatically.

---

### State Tracking

```bash
is_completed() {
    local entry="$1"
    [[ -f "$STATE_FILE" ]] && grep -qFx "$entry" "$STATE_FILE"
}

mark_completed() {
    local entry="$1"
    echo "$entry" >> "$STATE_FILE"
}

reset_state() {
    if [[ -f "$STATE_FILE" ]]; then
        rm -f "$STATE_FILE"
        log "State file cleared. Will start from the beginning."
    else
        log "No state file found. Nothing to reset."
    fi
}
```

The state file is a plain-text list: one completed entry per line. The entry is the full original string from `INSTALL_SEQUENCE` (e.g. `"S | 010_install_packages.sh --auto"`), not just the script name — so the same script with different arguments would be tracked as a different entry.

**`is_completed()`** — `grep -qFx` breaks down as:
- `-q` — quiet, produce no output, just return an exit code
- `-F` — treat the pattern as a fixed string (no regex), so `|` and `.` in the entry don't have special meaning
- `-x` — match the entire line exactly (not a substring match)

The `[[ -f "$STATE_FILE" ]]` check short-circuits if the file doesn't exist yet — without it, `grep` would print an error on the first run.

**`mark_completed()`** — appends the entry to the state file with `>>`. Appending rather than overwriting means the file grows one line per completed script, and the order reflects the actual execution sequence.

**`reset_state()`** — exposes `--reset` as a first-class operation. Useful when you want to re-run the entire sequence from scratch (e.g. after a major config change) without having to manually delete `/tmp/orchestra_state`.

---

### Sudo Credential Refresh

```bash
start_sudo_refresh() {
    sudo -v || die "Cannot obtain sudo credentials."

    (
        while true; do
            sudo -n true 2>/dev/null
            sleep "$SUDO_REFRESH_INTERVAL"
        done
    ) &
    SUDO_REFRESH_PID=$!
}

stop_sudo_refresh() {
    if [[ -n "$SUDO_REFRESH_PID" ]]; then
        kill "$SUDO_REFRESH_PID" 2>/dev/null || true
        wait "$SUDO_REFRESH_PID" 2>/dev/null || true
        SUDO_REFRESH_PID=""
    fi
}

cleanup() {
    stop_sudo_refresh
    log "Orchestrator finished. Log saved to $LOG_FILE"
}
trap cleanup EXIT
```

`sudo -v` ("validate") prompts for a password if needed and refreshes the sudo timestamp. If sudo isn't available or the password is wrong, `die` aborts immediately — there's no point running a setup sequence if sudo won't work.

The background subshell `( while true; do sudo -n true; sleep 60; done ) &` is a keepalive loop. `sudo -n` ("non-interactive") refreshes the timestamp without prompting — if the timestamp has expired, it simply fails silently (`2>/dev/null`). The effect is that as long as this loop is running, sudo stays active indefinitely. Without this, a subscript that takes several minutes could hit the sudo timeout mid-run and stall waiting for a password.

`$!` captures the PID of the last backgrounded process (the subshell). This is stored so it can be killed later.

**`stop_sudo_refresh()`** — kills the background loop and waits for it to actually exit (`wait`). The `|| true` on both `kill` and `wait` prevents errors if the process already exited on its own. Resetting `SUDO_REFRESH_PID=""` makes the function idempotent (safe to call multiple times).

**`trap cleanup EXIT`** — registers the `cleanup` function to run whenever the script exits, for any reason: normal completion, `die`, a signal, or `set -e` catching a failure. This guarantees the background process is always cleaned up.

---

### Script Execution

```bash
run_script() {
    local mode="$1"
    local cmd="$2"

    local script_name script_args
    script_name="$(echo "$cmd" | awk '{print $1}')"
    script_args="$(echo "$cmd" | cut -s -d' ' -f2-)"

    local script_path
    script_path="$(resolve_script "$script_name")" \
        || die "Script not found: $script_name (searched: ${SCRIPT_SEARCH_DIRS[*]})"

    local exec_cmd
    if [[ "$mode" == "S" ]]; then
        exec_cmd="sudo bash \"$script_path\" $script_args"
    else
        exec_cmd="bash \"$script_path\" $script_args"
    fi

    log "Running [$mode]: $script_name $script_args"
    eval "$exec_cmd" 2>&1 | tee -a "$LOG_FILE"
    return "${PIPESTATUS[0]}"
}
```

**Splitting `cmd` into name and args:**
- `awk '{print $1}'` extracts the first whitespace-delimited field — the script name.
- `cut -s -d' ' -f2-` extracts everything from field 2 onward — the args. The `-s` flag suppresses output entirely if there's no delimiter at all (i.e. a script with no args), returning an empty string rather than the whole input.

**`eval "$exec_cmd"`** — `eval` re-parses and executes the constructed string as a shell command. This is necessary because `exec_cmd` contains quoted paths and variable arguments that need shell word-splitting to work correctly. It's a pragmatic choice — the inputs here are internal (not user-controlled), so the injection risk is low.

**`2>&1 | tee -a "$LOG_FILE"`** — merges stderr into stdout and sends both to the terminal and the log file simultaneously. Every line the subscript prints is captured.

**`return "${PIPESTATUS[0]}"`** — `PIPESTATUS` is a bash array holding the exit codes of each command in the last pipeline. `[0]` is the exit code of `eval "$exec_cmd"` — the actual script. Without this, `return` would use the exit code of `tee`, which always succeeds even if the script failed. This is a critical correctness fix for pipelines where you care about the left-hand side's result.

---

### Failure Handling & Pre-run Prompt

```bash
handle_failure() {
    local entry="$1"

    if $AUTO_MODE; then
        log "Script failed in auto mode. Aborting."
        exit 1
    fi

    while true; do
        echo ""
        log "FAILED: $entry"
        echo "  [r] Retry"
        echo "  [s] Skip and continue"
        echo "  [a] Abort"
        read -rp "Choice: " choice
        case "$choice" in
            r|R) return 0 ;;
            s|S) return 1 ;;
            a|A) return 2 ;;
            *)   echo "Invalid choice." ;;
        esac
    done
}
```

In auto mode, any failure is fatal — there's no one to ask. In interactive mode, an infinite `while true` loop keeps prompting until a valid choice is made. The return values (0/1/2) are a numeric protocol between `handle_failure` and the calling retry loop — they mean retry/skip/abort respectively. The caller checks `$?` after the call to decide what to do next.

```bash
prompt_before_run() {
    local entry="$1"

    if $AUTO_MODE; then
        return 0
    fi

    echo ""
    read -rp "Run: $entry ? [Y/n/q] " answer
    case "$answer" in
        n|N) return 1 ;;
        q|Q) log "User chose to quit."; exit 0 ;;
        *)   return 0 ;;
    esac
}
```

The default case (`*`) handles both an explicit `y`/`Y` and an empty Enter press — any input that isn't `n` or `q` proceeds. `q` calls `exit 0` directly (clean exit), not `return` — this terminates the orchestrator immediately rather than returning to the loop.

---

### Main Loop (`run_sequence`)

```bash
run_sequence() {
    local total=${#INSTALL_SEQUENCE[@]}

    if [[ "$total" -eq 0 ]]; then
        log "INSTALL_SEQUENCE is empty. Add scripts to get started."
        exit 0
    fi

    log "Starting orchestrator ($total scripts in sequence)"
    [[ -f "$STATE_FILE" ]] && log "Resuming from state file: $STATE_FILE"

    start_sudo_refresh

    local index=0
    for entry in "${INSTALL_SEQUENCE[@]}"; do
        index=$((index + 1))

        local mode cmd
        mode="$(echo "$entry" | cut -d'|' -f1 | tr -d ' ')"
        cmd="$(echo "$entry" | cut -d'|' -f2- | sed 's/^ *//')"

        if [[ "$mode" != "S" && "$mode" != "U" ]]; then
            die "Invalid mode '$mode' in entry: $entry (expected S or U)"
        fi

        if is_completed "$entry"; then
            log "[$index/$total] SKIP (already done): $cmd"
            continue
        fi

        log "[$index/$total] Next: [$mode] $cmd"

        if ! prompt_before_run "$entry"; then
            log "Skipped by user: $cmd"
            continue
        fi

        while true; do
            if run_script "$mode" "$cmd"; then
                mark_completed "$entry"
                log "[$index/$total] DONE: $cmd"
                break
            else
                handle_failure "$entry"
                local result=$?
                if [[ $result -eq 0 ]]; then
                    log "Retrying: $cmd"
                    continue
                elif [[ $result -eq 1 ]]; then
                    log "Skipped after failure: $cmd"
                    break
                else
                    log "Aborted by user."
                    exit 1
                fi
            fi
        done
    done

    log "All scripts processed."
}
```

**Parsing the entry:** Each `INSTALL_SEQUENCE` entry is `"S | 010_install.sh --auto"`. The mode and command are split on `|`:
- `cut -d'|' -f1 | tr -d ' '` — takes everything before `|` and strips spaces, giving `S` or `U`.
- `cut -d'|' -f2- | sed 's/^ *//'` — takes everything from the second field onward and strips leading spaces, giving `010_install.sh --auto`.

**`is_completed "$entry"`** — the full original entry string is used as the key, not just the script name. This means `"S | 010_install.sh"` and `"S | 010_install.sh --auto"` are tracked as separate completions. If you change the args for a script between runs, the old completion won't match and it will re-run.

**Resume detection:** The `[[ -f "$STATE_FILE" ]]` check before the loop logs a notice if a state file already exists, confirming to the user that they're resuming a previous run rather than starting fresh.

**Retry loop:** On success, `mark_completed` persists the entry to the state file before continuing. On failure, `handle_failure` returns 0/1/2. The `local result=$?` captures this immediately — without that capture, subsequent commands could overwrite `$?` before the `if` checks it.

---

### Entry Point (`main`)

```bash
main() {
    for arg in "$@"; do
        case "$arg" in
            --reset)
                reset_state
                exit 0
                ;;
            --auto)
                AUTO_MODE=true
                ;;
            --help|-h)
                echo "Usage: $0 [--auto] [--reset] [--help]"
                exit 0
                ;;
            *)
                die "Unknown argument: $arg (try --help)"
                ;;
        esac
    done

    log "Orchestra started (auto=$AUTO_MODE)"
    run_sequence
}

main "$@"
```

A `for` loop over `"$@"` handles all arguments — this pattern works well when multiple flags can be combined (`--auto --reset` is fine). Each argument is matched and acted on independently. Unknown arguments call `die` immediately rather than silently ignoring them, which prevents subtle bugs from typos like `--Auto` or `---auto`.

`--reset` exits after clearing state rather than proceeding into `run_sequence`. This makes it a safe "start over" command you can run before a second attempt.

`main "$@"` at the bottom is the conventional Bash entry point pattern: define everything as functions, then call `main` with all original arguments at the end. This ensures all functions are defined before any code runs.

---

---

## `templates/arch_setup/000_TEMPLATE.sh`

This is not a script that does anything on its own — it's a **blank template** for arch_setup subscripts. You copy it, rename it with a numeric prefix, and fill in the `main()` function. Its value is in demonstrating all the conventions that ORCHESTRA.sh expects from its subscripts: the `--auto` flag protocol, the idempotency check pattern, the marker file approach, and the numbering scheme.

---

### Configuration

```bash
SCRIPT_DESC="Template script - replace with your description"
MARKER_FILE="/tmp/.dusky_000_template_done"

AUTO_MODE=false
for arg in "$@"; do
    [[ "$arg" == "--auto" ]] && AUTO_MODE=true
done
```

**`SCRIPT_DESC`** — a human-readable name used only in `log()` output. Replace with something like `"Install AUR helper (yay)"`. It has no functional effect but makes logs readable.

**`MARKER_FILE`** — a path to a file that, when it exists, signals this script has already completed successfully. The convention uses `/tmp/.dusky_` as a prefix and the script's own number as a suffix (`000_template_done`). Each script gets a unique marker so they don't interfere with each other. The `.` prefix makes it a hidden file (though that's just style in `/tmp`).

**`AUTO_MODE` parsing** — a simple `for` loop over `"$@"`, checking each argument against `--auto`. This is the interface contract between ORCHESTRA.sh and its subscripts: ORCHESTRA passes `--auto` when running in autonomous mode, and each subscript is responsible for honoring it. The same `for` loop pattern can be extended to handle other flags (e.g. `--dry-run`) as needed.

---

### Helpers

```bash
log() {
    echo "[$(basename "$0")] $*"
}

confirm() {
    local prompt="${1:-Continue?}"
    if $AUTO_MODE; then
        return 0
    fi
    read -rp "$prompt [Y/n] " answer
    [[ -z "$answer" || "$answer" =~ ^[Yy] ]]
}
```

**`log()`** — uses `basename "$0"` as the prefix, which extracts just the script filename (e.g. `015_install_packages.sh`) from its full path. This makes log output self-identifying — when multiple scripts are running in sequence and all their output is interleaved in the orchestrator's log file, you can tell at a glance which script produced each line.

**`confirm()`** — the interactive prompt helper. `${1:-Continue?}` uses the first argument as the prompt, defaulting to `"Continue?"` if none is given. In auto mode it immediately returns `0` (yes), letting the script proceed non-interactively. In interactive mode, it reads input and evaluates it: `[[ -z "$answer" || "$answer" =~ ^[Yy] ]]` — an empty Enter press (`-z`) or any answer starting with `Y`/`y` (the regex `^[Yy]`) returns success. Anything else returns failure. The result of this test expression is the return value of the function.

---

### Idempotency Check

```bash
if [[ -f "$MARKER_FILE" ]]; then
    log "Already completed. Skipping. (Remove $MARKER_FILE to re-run)"
    exit 0
fi
```

This runs before `main()` — it's a script-level guard that makes each subscript independently idempotent. The comment documents all four idempotency check patterns you might use instead of the marker file:

```bash
# Marker file:  [[ -f "$MARKER_FILE" ]]
# Package:      pacman -Qi some-package &>/dev/null
# Service:      systemctl is-enabled some-service &>/dev/null
# File exists:  [[ -f /etc/some/config ]]
```

- **Marker file** — universal fallback. Works for any operation. The downside: it's stored in `/tmp` and won't survive a reboot, so the check only helps if you're re-running in the same session.
- **`pacman -Qi`** — checks if a package is installed. `-Q` queries the local package database, `-i` requests info. More reliable than a marker file because it reflects actual system state: the check still works after a reboot.
- **`systemctl is-enabled`** — checks if a service is enabled at boot. Similar benefit: reflects real state.
- **`[[ -f /etc/some/config ]]`** — checks for a specific file that the script would create. Best when the script's output is a specific known file.

ORCHESTRA.sh has its own state file that also tracks completion, but that's at the orchestrator level — it records which script ran, not whether what the script did is actually in place. The per-script idempotency check is a second, independent layer of protection that handles cases like: running a subscript manually outside the orchestrator, or the orchestrator's state file being deleted.

---

### `main()`

```bash
main() {
    log "Starting: $SCRIPT_DESC"

    # --- Step 1: Example package installation ---
    # log "Installing packages..."
    # pacman -S --needed --noconfirm package1 package2

    # --- Step 2: Example configuration ---
    # log "Writing config..."
    # cat > /etc/some/config <<'CONF'
    # key = value
    # CONF

    # --- Step 3: Example service enable ---
    # log "Enabling service..."
    # systemctl enable --now some-service

    # --- Step 4: Example interactive step ---
    # if confirm "Do you want to configure X manually?"; then
    #     :
    # fi

    touch "$MARKER_FILE"
    log "Done: $SCRIPT_DESC"
}

main
```

The commented-out steps show the four most common operations in a setup script:

1. **Package installation** — `--needed` skips already-installed packages (idempotency), `--noconfirm` prevents interactive prompts.
2. **Config file writing** — `cat > /path <<'CONF'` heredoc with a quoted delimiter (`'CONF'` instead of `CONF`) prevents variable expansion inside the heredoc, so `$HOME` and similar variables are written literally rather than expanded.
3. **Service enable** — `--now` both enables at boot and starts immediately in one command.
4. **Interactive step** — wraps any user-facing prompt in `confirm`, so it's automatically bypassed in `--auto` mode.

The `touch "$MARKER_FILE"` at the end is the final act of the script. It only runs if `main()` completed without error (since `set -e` is active) — so the marker file is a reliable indicator that everything succeeded.

`main` (called without `"$@"`) at the bottom — unlike ORCHESTRA.sh, the subscripts don't need to forward arguments to `main` since `AUTO_MODE` is already parsed at the top-level scope before `main` is called.

