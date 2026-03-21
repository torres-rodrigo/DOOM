# Deploy dotfiles from the repo's config/ directory to ~/.config/.

echo "Deploying dotfiles..."

if [[ ! -d "$DOOM_PATH/config" ]]; then
  echo "ERROR: $DOOM_PATH/config not found — cannot deploy dotfiles."
  return 1 2>/dev/null || exit 1
fi

cp -rf "$DOOM_PATH/config/"* "$XDG_CONFIG_HOME/"

echo "Dotfiles: OK"
