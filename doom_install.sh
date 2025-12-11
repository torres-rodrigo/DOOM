#!/bin/bash

# Exit if a command exits with a non-zero status
set -eEo pipefail

# Error catching
catch_errors() {
    echo -e "\n\e[31mDOOM installation failed!\e[0m"
    echo
    echo
    if [[ -n "$CURRENT_SCRIPT" ]]; then
        echo "Failed in: $CURRENT_SCRIPT"
    fi
    echo
    echo "The following command finished with exit code $?"
    echo "$BASH_COMMAND"
    echo
}

# Set the trap
trap catch_errors ERR INT TERM

# Track script being run
CURRENT_SCRIPT=""

run_script() {
    CURRENT_SCRIPT="$1"
    source "$1"
    CURRENT_SCRIPT=""
}

export DOOM_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export ZIG_GLOBAL_CACHE_DIR="$XDG_CACHE_HOME/zig"
export ZIG_GLOBAL_PACKAGE_DIR="$XDG_DATA_HOME/zig"
export NUGET_PACKAGES="$XDG_CACHE_HOME/nuget"
export DOTNET_CLI_HOME="$XDG_CONFIG_HOME/dotnet"
export DOTNET_CLI_CACHE_HOME="$XDG_CACHE_HOME/dotnet"

export ZDOTDIR="$HOME/.config/zsh"

SPACER="============================================="

#PREFLIGHT CHECKUP
echo "0. PREFLIGHT CHECKUPS"
run_script "$DOOM_DIR/preflight/preflight.sh"
echo "$SPACER"
echo 
#END PREFLIGHT CHECKUP

#SYSTEM UPDATE
echo "1. SYSTEM UPDATE"
sudo pacman -Syu --noconfirm
echo "$SPACER"
echo 
#END SYSTEM UPDATE

#PACKAGES
echo "2. PACKAGES"
run_script "$DOOM_DIR/packages/packages.sh"
run_script "$DOOM_DIR/packages/fonts.sh"
run_script "$DOOM_DIR/packages/aur.sh"
echo "$SPACER"
echo 
#END PACKAGES
