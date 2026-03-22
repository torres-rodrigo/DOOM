#!/usr/bin/env bash
# install/config/cursor.sh — Install DoomCursor theme and apply it as the default.

set -euo pipefail

ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
CURSOR_NAME="DoomCursor"
CURSOR_SRC="$DOOM_PATH/assets/DoomCursor"

mkdir -p "$ICONS_DIR"

if [[ ! -d "$CURSOR_SRC/cursors" ]]; then
    echo "cursor: assets/DoomCursor not found — skipping"
    exit 0
fi

cp -r "$CURSOR_SRC" "$ICONS_DIR/$CURSOR_NAME"
echo "cursor: installed $CURSOR_NAME → $ICONS_DIR/$CURSOR_NAME"

# XCursor default fallback — many Wayland clients look here to resolve "default" cursor
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" <<EOF
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=$CURSOR_NAME
EOF
echo "cursor: ~/.icons/default/index.theme → Inherits=$CURSOR_NAME"

MANGO_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/mango/config.conf"
if [[ -f "$MANGO_CONF" ]]; then
    grep -q '^cursor_theme=' "$MANGO_CONF" \
        || printf '\ncursor_theme=%s\n' "$CURSOR_NAME" >> "$MANGO_CONF"
    grep -q '^cursor_size=' "$MANGO_CONF" \
        || printf 'cursor_size=32\n' >> "$MANGO_CONF"
    echo "cursor: patched $MANGO_CONF with cursor_theme + cursor_size"
else
    echo "cursor: ~/.config/mango/config.conf not found — add manually:"
    echo "  cursor_theme=$CURSOR_NAME"
    echo "  cursor_size=32"
fi

echo "cursor: done"
