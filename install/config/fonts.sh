#!/usr/bin/env bash
# install/config/fonts.sh — Install custom fonts from assets/ to the system font directory.

set -euo pipefail

FONT_DIR="/usr/share/fonts/doom"
FONT_SRC="$DOOM_PATH/assets"

found=0
for f in "$FONT_SRC"/*.ttf "$FONT_SRC"/*.otf; do
    [[ -f "$f" ]] && { found=1; break; }
done

if (( found == 0 )); then
    echo "fonts: no font files found in assets/ — skipping"
    exit 0
fi

sudo mkdir -p "$FONT_DIR"

for f in "$FONT_SRC"/*.ttf "$FONT_SRC"/*.otf; do
    [[ -f "$f" ]] || continue
    sudo cp -f "$f" "$FONT_DIR/"
    echo "fonts: installed $(basename "$f") → $FONT_DIR/"
done

sudo fc-cache -fv
echo "fonts: font cache updated"
echo "fonts: done"
