# Optional packages — prompted interactively.
# Users choose what they want; nothing is forced on them.

ask_install() {
  local pkg="$1"
  local description="$2"

  if command -v gum &>/dev/null; then
    gum confirm "Install $pkg? ($description)" && return 0 || return 1
  else
    read -rp "Install $pkg? ($description) [y/N] " ans
    [[ "${ans,,}" == "y" ]]
  fi
}

echo "Optional packages (choose what you want):"
echo

# Development environments

if ask_install "go" "Go programming language"; then
  sudo pacman -S --needed --noconfirm go
fi

if ask_install "dotnet-runtime" ".NET Runtime for C# apps"; then
  sudo pacman -S --needed --noconfirm dotnet-runtime
fi

# Media production
if ask_install "obs-studio" "Screen recording + streaming"; then
  sudo pacman -S --needed --noconfirm obs-studio
fi

# Gaming
if ask_install "steam" "Steam gaming platform + performance tooling"; then
  # Multilib is required for Steam's 32-bit dependencies
  sudo sed -i '/^#\[multilib\]/,/^#Include/{s/^#//}' /etc/pacman.conf
  sudo pacman -Syu

  # Detect GPU and install the matching Vulkan driver + lib32 variant
  gpu=$(lspci | grep -Ei "VGA|3D controller|Display controller" | tr '[:upper:]' '[:lower:]')
  if echo "$gpu" | grep -q "nvidia"; then
    sudo pacman -S --needed --noconfirm nvidia-utils lib32-nvidia-utils
  elif echo "$gpu" | grep -q "amd\|ati"; then
    sudo pacman -S --needed --noconfirm vulkan-radeon lib32-vulkan-radeon
  elif echo "$gpu" | grep -q "intel"; then
    sudo pacman -S --needed --noconfirm vulkan-intel lib32-vulkan-intel
  else
    echo "WARNING: GPU vendor not recognised — install Vulkan driver manually."
  fi

  sudo pacman -S --needed --noconfirm \
    steam \
    gamemode \
    lib32-gamemode \
    vulkan-tools
fi

if ask_install "lutris wine" "Lutris + Wine for Windows games"; then
  sudo pacman -S --needed --noconfirm lutris wine wine-mono
fi

if ask_install "xpadneo" "Xbox controller support"; then
  paru -S --needed --noconfirm xpadneo-dkms
  # Blacklist the broken in-kernel xpad driver
  echo "blacklist xpad" | sudo tee /etc/modprobe.d/blacklist-xpad.conf
  sudo modprobe xpadneo
  sudo usermod -aG input "$USER"
fi

echo "Optional packages: OK"
