mkdir -p ~/.local/share/fonts
#cp $DOOM_DIR/doom_assets/doom_font.ttf ~/.local/share/fonts/

FONTS=(
    "noto-fonts"
    "noto-fonts-emoji"
)

sudo pacman -S --noconfirm --needed "${FONTS[@]}"

fc-cache

echo "Fonts installed"
echo