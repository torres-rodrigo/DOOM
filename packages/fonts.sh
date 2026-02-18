mkdir -p ~/.local/share/fonts
#cp $DOOM_DIR/doom_assets/doom_font.ttf ~/.local/share/fonts/
#excalidraw font

FONTS=(
    "noto-fonts"
    "noto-fonts-emoji"
    "ttf-cascadia-code-nerd" #Delete when i have my custom version of the font
)

sudo pacman -S --noconfirm --needed "${FONTS[@]}"

fc-cache

echo "Fonts installed"
echo
