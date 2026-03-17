# Deploy utility scripts from scripts/ to ~/.local/bin.

echo "Installing scripts..."

if [[ ! -d "$DOOM_PATH/scripts" ]]; then
  echo "ERROR: $DOOM_PATH/scripts not found — cannot install scripts."
  return 1 2>/dev/null || exit 1
fi

mkdir -p "$HOME/.local/bin"
cp -f "$DOOM_PATH/scripts/"* "$HOME/.local/bin/"
chmod +x "$HOME/.local/bin/"doom-*

echo "Scripts: OK"
