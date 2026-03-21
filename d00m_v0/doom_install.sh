#!/bin/bash
# =============================================================================
# doom_v0 Install Script
# =============================================================================
# Run this after rebooting into the freshly installed Arch base system.
# The repo should already be at ~/doom_v0 (copied by
# archinstall_manager.sh before reboot).
#
# Usage:
#   bash ~/doom_v0/doom_install.sh
# =============================================================================

set -eEo pipefail

# ── Paths ─────────────────────────────────────────────────────────────────────
export DOOM_PATH="$HOME/doom_v0"
export DOOM_INSTALL="$DOOM_PATH/install"
export DOOM_INSTALL_LOG_FILE="/var/log/doom-install.log"

# ── XDG Base Directories ──────────────────────────────────────────────────────
# Use :- so a pre-existing value in the environment is respected.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

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
