#!/bin/bash
# =============================================================================
# doom_v0 Install Script
# =============================================================================
# Run this after rebooting into the freshly installed Arch base system.
# The repo should already be at ~/d00m_v0 (copied by
# archinstall_manager.sh before reboot).
#
# Usage:
#   bash ~/d00m_v0/doom_install.sh
# =============================================================================

set -eEo pipefail

# ── Guard: must not run as root ───────────────────────────────────────────────
if [[ "$(id -u)" -eq 0 ]]; then
    echo "Error: do not run this script as root or with sudo." >&2
    exit 1
fi

# ── Correct HOME if the session set it incorrectly ────────────────────────────
# greetd auto-login can leave HOME pointing at /root when PAM does not fully
# initialise the user environment. Look up the true home from /etc/passwd.
_true_home="$(getent passwd "$(id -un)" | cut -d: -f6)"
if [[ "$HOME" != "$_true_home" ]]; then
    export HOME="$_true_home"
fi
unset _true_home

# ── Paths ─────────────────────────────────────────────────────────────────────
# Resolve DOOM_PATH from the script's own location so it works regardless
# of where the directory is placed or what it is named.
export DOOM_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOOM_INSTALL="$DOOM_PATH/install"

# ── XDG Base Directories ──────────────────────────────────────────────────────
# Use :- so a pre-existing value in the environment is respected.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Log file lives under XDG_STATE_HOME so no root access is needed.
export DOOM_INSTALL_LOG_FILE="$XDG_STATE_HOME/doom-install.log"

# ── Tool Directories (XDG-compliant) ─────────────────────────────────────────
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

# ── PATH ──────────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$CARGO_HOME/bin:$GOPATH/bin:$PATH"

# ── Ensure all directories exist ──────────────────────────────────────────────
mkdir -p \
  "$HOME/.local/bin" \
  "$XDG_CONFIG_HOME" \
  "$XDG_CACHE_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_STATE_HOME" \
  "$ZDOTDIR" \
  "$XDG_CACHE_HOME/zsh" \
  "$XDG_STATE_HOME/zsh" \
  "$CARGO_HOME" \
  "$RUSTUP_HOME" \
  "$GOPATH" \
  "$GOMODCACHE" \
  "$ZIG_GLOBAL_CACHE_DIR" \
  "$ZIG_GLOBAL_PACKAGE_DIR" \
  "$NUGET_PACKAGES" \
  "$DOTNET_CLI_HOME" \
  "$DOTNET_CLI_CACHE_HOME"

# ── Phase 1: Helpers (logging, error recovery, presentation) ──────────────────
source "$DOOM_INSTALL/helpers/000_doom.sh"

# Reset any leftover terminal state from a previous run (scroll regions, hidden cursor)
printf "\033[r"
show_cursor
clear

print_logo
start_install_log

# ── Phase 2: Preflight (guard checks, pacman init, markers) ───────────────────
source "$DOOM_INSTALL/preflight/001_doom.sh"

# ── Phase 3: Packaging (base packages + AUR) ──────────────────────────────────
source "$DOOM_INSTALL/packaging/002_doom.sh"

# ── Phase 4: Configuration (GPU, system tuning, config deployment) ────────────
source "$DOOM_INSTALL/config/003_doom.sh"

# ── Phase 5: Login / Boot (display manager, bootloader) ───────────────────────
source "$DOOM_INSTALL/login/004_doom.sh"

# ── Phase 6: Post-install (initramfs, cleanup, reboot) ────────────────────────
source "$DOOM_INSTALL/post-install/005_doom.sh"
