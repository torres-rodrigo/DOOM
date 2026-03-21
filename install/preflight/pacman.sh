# Initialize pacman keyring and sync databases.
# Also configure pacman for parallel downloads and colored output.

print_step "Initializing pacman"

# Keyring setup
sudo pacman-key --init
sudo pacman-key --populate archlinux

# Enable parallel downloads + color in pacman.conf
sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

# Sync databases and upgrade all installed packages before adding new ones.
# Using -Syu (not -Sy alone) avoids partial upgrades: if -Sy syncs the DB
# to newer package versions and then later installs pull in those newer
# dependencies, any un-upgraded installed packages can break.
sudo pacman -Syu --noconfirm

# Install gum early (used by error recovery menus)
pacman -Qe gum &>/dev/null || sudo pacman -S --noconfirm gum

echo "Pacman: OK"
