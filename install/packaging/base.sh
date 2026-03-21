# Install base system packages from the packages.list file.
# Idempotent: already-installed packages are gracefully skipped by pacman.

PACKAGES_LIST="$DOOM_INSTALL/packaging/packages.list"

# Filter out comments and blank lines, then install
packages=()
while IFS= read -r line; do
  line="${line%%#*}"    # Strip inline comments
  line="${line// /}"   # Strip spaces
  [[ -n "$line" ]] && packages+=("$line")
done < "$PACKAGES_LIST"

echo "Installing ${#packages[@]} base packages..."
sudo pacman -S --needed --noconfirm "${packages[@]}"

# Set up Rust stable toolchain via rustup.
# rustup itself is installed by pacman above, but it ships with no toolchain —
# this call downloads and sets the stable compiler as the default.
sudo pacman -S needed --noconfirm rustup
if command -v rustup &>/dev/null; then
  echo "Setting up Rust stable toolchain..."
  rustup default stable
fi

# Apply makepkg optimizations before paru compiles.
# mold is now installed (from packages.list above), so all flags are active:
# -march=native, mold linker, RUSTFLAGS, MAKEFLAGS, NINJAFLAGS.
mkdir -p "$XDG_CONFIG_HOME/pacman"
cp "$DOOM_PATH/config/pacman/makepkg.conf" "$XDG_CONFIG_HOME/pacman/makepkg.conf"
echo "makepkg: optimized config applied"

# Install paru (AUR helper) if not already present
if ! command -v paru &>/dev/null; then
  echo "Installing paru AUR helper..."
  tmpdir=$(mktemp -d)
  git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmpdir/paru"
  cd "$tmpdir/paru"
  makepkg -si --noconfirm
  cd -
  rm -rf "$tmpdir"
fi

echo "Base packages: OK"
