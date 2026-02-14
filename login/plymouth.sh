#!/bin/bash

echo "Configuring Plymouth boot splash..."

# Check if Plymouth theme is already set to DOOM
if [ "$(plymouth-set-default-theme)" != "doom" ]; then
  # Copy DOOM Plymouth theme to system directory
  sudo cp -r "$DOOM_DIR/default/plymouth" /usr/share/plymouth/themes/doom/

  # Set DOOM as the default Plymouth theme
  sudo plymouth-set-default-theme doom

  echo "Plymouth theme set to DOOM"
else
  echo "Plymouth theme already set to DOOM"
fi

echo "Plymouth boot splash configured"
