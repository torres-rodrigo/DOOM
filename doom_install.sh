#!/bin/bash

# Exit if a command exits witha a non-zero status
set -eE

# Error catching
catch_errors() {
    echo -e "\n\e[31mDOOM installation failed!\e[0m"
    echo
    echo "The following command finished with exit code $?:"
    echo "$BASH_COMMAND"
    echo
}

# Set the trap
trap catch_errors ERR

#PRE-FlIGHT CHECKUP
echo "0. PRE-FLIGHT CHECKUP"
if [[ $EUID -eq 0 ]]; then
  echo "Error: This script must not be run with root privileges. Ex: './doom_install.sh'"
  exit 1
fi
echo
#END PRE-FlIGHT CHECKUP

# ENVIORMENT SET-UP
echo "1. ENVIORMENT SET-UP"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
DOOM_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOOM_PATH="$HOME/.local/share/doom"
DOOM_INSTALL="$DOOM_PATH/install"
export PATH="$DOOM_PATH/bin:$PATH"
mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_CACHE_HOME"
mkdir -p "$XDG_DATA_HOME"
#mkdir -p "$DOOM_PATH"
#mkdir -p "$DOOM_INSTALL"
echo
echo "=================================================="
echo
# END ENVIORMENT SET-UP

# SYSTEM UPDATE
echo "2. SYSTEM UPDATE"
echo "Updating system ..."
sudo pacman -Syu --noconfirm
echo
echo "=================================================="
echo
# END SYSTEM UPDATE

# PACKAGES
echo "3. PACKAGES"
chmod +x "$DOOM_DIR/packages/base_packages.sh"
"$DOOM_DIR/packages/base_packages.sh"
chmod +x "$DOOM_DIR/packages/aur_setup.sh"
"$DOOM_DIR/packages/aur_setup.sh"
chmod +x "$DOOM_DIR/packages/core_packages.sh"
"$DOOM_DIR/packages/core_packages.sh"
echo
echo "=================================================="
echo
# END PACKAGES

# CONFIGS
echo "4. CONFIGS"
echo "Copying configs to ~/.config"
cp -R "$DOOM_DIR/config/." "~/.config"
systemctl --user enable hyprland.service
echo
echo "=================================================="
echo
# ENDCONFIGS
