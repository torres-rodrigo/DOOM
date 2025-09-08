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

# PRE-FlIGHT CHECKUP
echo "0. PRE-FLIGHT CHECKUP"
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run with root privileges Ex: 'sudo ./doom_install.sh'"
   exit 1
fi
echo
# END PRE-FlIGHT CHECKUP

# ENVIORMENT SET-UP
echo "1. ENVIORMENT SET-UP"
DOOM_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
DOOM_PATH="$HOME/.local/share/doom"
DOOM_INSTALL="$DOOM_PATH/install"
export PATH="$DOOM_PATH/bin:$PATH"
echo
# END ENVIORMENT SET-UP

# SYSTEM UPDATE
echo "2. SYSTEM UPDATE"
echo "Updating system ..."
sudo pacman -Syu --noconfirm
echo
# END SYSTEM UPDATE

# PACKAGES
echo "3. PACKAGES"
chmod +x "$DOOM_DIR/packages/core-packages.sh"
"$DOOM_DIR/packages/core-packages.sh"
echo
# END PACKAGES
