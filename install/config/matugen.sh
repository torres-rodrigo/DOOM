#!/usr/bin/env bash
# install/config/matugen.sh — Set up matugen directories and apply the default theme.

set -euo pipefail

# ── Generated output dirs ─────────────────────────────────────────────────────
# matugen writes rendered templates here; apps read from these locations.
mkdir -p \
    "$HOME/.config/matugen/generated" \
    "$HOME/.config/gtk-3.0" \
    "$HOME/.config/gtk-4.0" \
    "$HOME/.config/mako" \
    "$HOME/.config/btop/themes" \
    "$HOME/.config/starship"

# ── Apply default preset ──────────────────────────────────────────────────────
# catppuccin is the out-of-the-box theme; user can change it later with doom-theme.
doom-theme catppuccin
