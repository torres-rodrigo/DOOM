#!/bin/bash
set -euo pipefail

echo "Creating directories..."

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# XDG base + local bin
mkdir -p \
    "$XDG_CONFIG_HOME" \
    "$XDG_CACHE_HOME" \
    "$XDG_DATA_HOME" \
    "$XDG_STATE_HOME" \
    "$HOME/.local/bin"

# Config directories
mkdir -p \
    "$XDG_CONFIG_HOME/cliphist" \
    "$XDG_CONFIG_HOME/dotnet" \
    "$XDG_CONFIG_HOME/fastfetch" \
    "$XDG_CONFIG_HOME/ghostty" \
    "$XDG_CONFIG_HOME/git" \
    "$XDG_CONFIG_HOME/hypr" \
    "$XDG_CONFIG_HOME/nvim/lua/config" \
    "$XDG_CONFIG_HOME/starship" \
    "$XDG_CONFIG_HOME/systemd/user" \
    "$XDG_CONFIG_HOME/uwsm" \
    "$XDG_CONFIG_HOME/wezterm" \
    "$XDG_CONFIG_HOME/zsh"

# State directories
mkdir -p \
    "$XDG_STATE_HOME/doom-install" \
    "$XDG_STATE_HOME/zsh"

# Data directories
mkdir -p \
    "$XDG_DATA_HOME/cargo" \
    "$XDG_DATA_HOME/fonts" \
    "$XDG_DATA_HOME/go" \
    "$XDG_DATA_HOME/rustup" \
    "$XDG_DATA_HOME/zig"

# Cache directories
mkdir -p \
    "$XDG_CACHE_HOME/dotnet" \
    "$XDG_CACHE_HOME/go/mod" \
    "$XDG_CACHE_HOME/nuget" \
    "$XDG_CACHE_HOME/zig"

# Media directories
mkdir -p "$HOME/Pictures/Screenshots"

echo "Directories created"
