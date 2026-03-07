PACKAGES=(
    #System
    "base-devel"
    "gnome-keyring"
    "polkit-gnome"
    # "power-profiler-daemon"
    "qt5-wayland"
    "qt6-wayland"
    "xdg-desktop-portal"
    "xdg-desktop-portal-gtk"
    "xdg-desktop-portal-hyprland"
    "zsh"

    #Desktop Enviorment
    "brightnessctl" # Backlight brightness control
    "greetd" # Minimal display manager
    "greetd-tuigreet" # TUI greeter for greetd
    "hypridle" # Idle management daemon
    "hyprland" # Dynamic tiling Wayland compositor
    "hyprland-guiutils" # GUI utilities for Hyprland
    "hyprlock" # Screen locker
    "hyprpicker" # Color picker
    "mako" # Notification daemon
    "plymouth" # Boot splash screen
    "swaybg" # Wallpaper setter
    "swayosd" # On-screen display (volume/brightness)
    "uwsm" # Universal Wayland Session Manager
    "wl-clipboard" # Clipboard manager for Wayland

    #System - Hardware Detection & Management
    "pciutils" # PCI device detection (lspci)
    "upower" # Battery/power monitoring
    "usbutils" # USB device detection (lsusb)

    #System - Bluetooth
    "bluez" # Bluetooth protocol stack
    "bluez-utils" # Bluetooth utilities
    "bluetui" # Minimal TUI Bluetooth manager (Rust)

    #Security
    "fprintd" # Fingerprint authentication daemon
    "libfido2" # FIDO2 library
    "pam-u2f" # FIDO2/Yubikey PAM module
    "ufw" # Uncomplicated Firewall

    #UX - Clipboard
    "cliphist" # Clipboard history manager (Go)
    "wl-clip-persist" # Persist clipboard after app closes

    #UX - Screenshots
    "grim" # Screenshot utility for Wayland
    "satty" # Screenshot annotation tool (Rust)
    "slurp" # Region selector for Wayland

    #UX - Screen Recording
    "gpu-screen-recorder" # Hardware-accelerated screen recorder
    "v4l-utils" # Webcam utilities

    #Terminal
    "bat" # Improved cat
    "btop" # TUI resource monitor
    "caligula" # dd TUI
    "curl" # Command-line tool for transferring data with URLs
    "dust" # Disk usage analyzer
    "eza" # Modern replacement for ls
    "fastfetch" # Fast system information tool
    "fd" # Improved find
    "ffmpeg" # Powerful multimedia framework for audio and video processing
    "ffmpegthumbnailer" # Utility to create video thumbnails using FFmpeg
    "fzf" # Command-line fuzzy finder
    "ghostty" # Terminal emulator
    "git-delta" # Diff tool
    "github-cli" # Github cli
    "gopass" # Password manager CLI
    "gum" # Tool to build rich shell scripts with styled text and prompts
    "hledger" # Plain text accounting tool
    "jq" # JSON parser and processor
    "jujutsu" # Version control system
    "kitty" # Terminal emulator
    "lazygit" # Git TUI
    "less" # File pager for viewing text files and command output
    "luarocks" # Package manager for Lua modules
    "man" # Manual pages
    "mise" # Polygot package manager
    "ncdu" # Disk usage visualizer
    "neovim" # Vim-based text editor
    "pacman-contrib" # Pacman scripts and tools
    "ripgrep" # Fast text searching tool (like grep, but better)
    "skim" # Fuzzy finder written in Rust
    "starship" # Minimal, fast, and customizable shell prompt
    "tealdeer" # Fast tldr client for simplified command help pages
    "tree-sitter-cli" # CLI for building syntax parsers using Tree-sitter
    "unzip" # Utility for extracting files from .zip archives
    "wezterm" # Terminal emilator
    "wget" # Command-line downloader for HTTP, HTTPS, and FTP

    #Progrmas
    # "gimp" # Image editor
    # "inkscape" # Vector graphics editor
    # "libreoffice-fresh" # Office suite
    # "localsend" # Cross-platform local file sharing
    # "mpv" # Media player
    # "obsidian" # Kknowledge management and note-taking app
    # "thunar" # File manager
)

sudo pacman -S --noconfirm --needed "${PACKAGES[@]}"

echo "Packages installed"
echo
