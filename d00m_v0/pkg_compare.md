# Package Comparison: DOOM · d00m_v0 · Omarchy · Dusky

**Legend**
| Symbol | Meaning |
|--------|---------|
| `✓` | Installed from official Arch repos |
| `A` | Installed from AUR |
| `✗` | Not installed |
| `~` | Present but commented out (disabled/optional) |

Sources:
- **DOOM** — `packages/packages.sh` + `packages/aur.sh` + `packages/fonts.sh`
- **d00m_v0** — `install/packaging/packages.list` + `install/packaging/aur.sh`
- **Omarchy** — `install/omarchy-base.packages` + `install/omarchy-other.packages`
- **Dusky** — all package scripts across `user_scripts/`

---

## Window Manager / Compositor

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `hyprland` | ✓ | ✓ | ✓ | ✓ | Dynamic tiling Wayland compositor |
| `hyprland-guiutils` | ✓ | ✗ | ✓ | ✗ | GUI helper apps for Hyprland |
| `mango` WM | ✗ | PLANNED | ✗ | ✗ | **d00m_v0 target compositor — replacing Hyprland** |
| `hyprland-protocols` | ✗ | ✓ | ✗ | ✗ | Hyprland-specific Wayland protocols; remove when switching |
| `hyprsunset` | ✗ | ✓ | ✓ | ✓ | Hyprland blue-light / night mode filter |
| `hyprpaper` | ✗ | ✓ | ✗ | ✗ | Hyprland-native wallpaper setter; remove when switching |
| `hyprlock` | ✗ | ✓ | ✓ | ✓ | Hyprland screen locker |
| `hypridle` | ✗ | ✓ | ✓ | ✓ | Idle detection daemon (triggers lock/suspend) |
| `hyprpicker` | ✗ | ✓ | ✓ | ✓ | Wayland color picker / eyedropper |

---

## Mango WM Dependencies (d00m_v0 planned additions)

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `wayland` | ✗ | PLANNED | ✗ | ✗ | Core Wayland client library |
| `wayland-protocols` | ✗ | PLANNED | ✗ | ✗ | Standardized Wayland protocol extensions |
| `libdrm` | ✗ | PLANNED | ✗ | ✗ | Linux Direct Rendering Manager userspace lib |
| `libxkbcommon` | ✗ | PLANNED | ✗ | ✗ | Keyboard keymap handling (XKB) |
| `pixman` | ✗ | PLANNED | ✗ | ✗ | Low-level pixel manipulation library |
| `libdisplay-info` | ✗ | PLANNED | ✗ | ✗ | EDID and DisplayID parsing |
| `libliftoff` | ✗ | PLANNED | ✗ | ✗ | KMS/DRM hardware plane offloading |
| `hwdata` | ✗ | PLANNED | ✗ | ✗ | PCI/USB hardware ID databases |
| `seatd` | ✗ | PLANNED | ✗ | ✗ | Minimal seat management daemon |
| `pcre2` | ✗ | PLANNED | ✗ | ✗ | Perl-Compatible Regular Expressions v2 |
| `xorg-xwayland` | ✗ | PLANNED | ✗ | ✓ | X11 compat layer (d00m_v0 has `xwayland`) |
| `libxcb` | ✗ | PLANNED | ✗ | ✗ | XCB library for X11 compatibility |

---

## Session Management / XDG Portals

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `uwsm` | ✓ | ✓ | ✓ | ✓ | Universal Wayland Session Manager — proper session lifecycle |
| `xdg-desktop-portal` | ✓ | ✗ | ✗ | ✗ | Base portal interface for sandboxed apps |
| `xdg-desktop-portal-gtk` | ✓ | ✓ | ✓ | ✓ | GTK portal backend (file chooser, etc.) |
| `xdg-desktop-portal-hyprland` | ✓ | ✓ | ✓ | ✓ | Hyprland portal backend; swap when changing WM |
| `xwayland` | ✗ | ✓ | ✗ | ✓ | X11 compatibility layer for Wayland |
| `qt5-wayland` | ✓ | ✓ | ✓ | ✓ | Qt5 Wayland platform backend |
| `qt6-wayland` | ✓ | ✓ | ✗ | ✓ | Qt6 Wayland platform backend |
| `xdg-utils` | ✗ | ✓ | ✗ | ✓ | XDG command-line tools (xdg-open, etc.) |

---

## Display Manager / Greeter / Boot

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `greetd` | ✓ | ✗ | ✗ | ✗ | Minimal display manager daemon |
| `greetd-tuigreet` | ✓ | ✗ | ✗ | ✗ | TUI greeter frontend for greetd |
| `sddm` | ✗ | ✓ | ✓ | ✗ | Qt-based display manager; **user wants to remove** |
| `sddm-theme-astronaut` | ✗ | A | ✗ | ✗ | SDDM login theme; remove along with sddm |
| `plymouth` | ✓ | ✓ | ✓ | ✗ | Boot splash screen animation |

> **Goal for d00m_v0:** No greeter. Auto-login after disk encryption passphrase, identical to Omarchy's flow.

---

## Status Bar

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `waybar` | ✗ | ✓ | ✓ | ✓ | Highly configurable Wayland status bar |

---

## Notifications

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `mako` | ✓ | ✓ | ✓ | ✗ | Lightweight Wayland notification daemon |
| `swaynotificationcenter` (`swaync`) | ✗ | A | ✗ | ✓ | Notification sidebar with Do Not Disturb |

---

## App Launchers / System Menus

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `rofi-wayland` | ✗ | ✓ | ✗ | ✓ | App launcher and system menus |
| `omarchy-walker` | ✗ | ✗ | ✓ | ✗ | Omarchy-specific custom launcher |
| `wlogout` | ✗ | A | ✗ | A | Wayland logout / session menu screen |

---

## Clipboard

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `cliphist` | ✓ | ✓ | ✗ | ✓ | Clipboard history manager |
| `wl-clipboard` | ✓ | ✓ | ✓ | ✓ | Wayland clipboard CLI (wl-copy / wl-paste) |
| `wl-clip-persist` | ✓ | ✗ | ✗ | ✓ | Keeps clipboard content alive after app closes |
| `wtype` | ✗ | A | ✗ | ✗ | Type text into Wayland windows programmatically |

---

## Terminals

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `ghostty` | ✓ | ✗ | ✗ | ✗ | Fast, feature-rich terminal by Mitchell Hashimoto |
| `kitty` | ✓ | ✓ | ✗ | ✓ | GPU-accelerated terminal emulator |
| `wezterm` | ✓ | ✗ | ✗ | ✗ | Lua-configured GPU-accelerated terminal |
| `alacritty` | ✗ | ✓ | ✓ | ✗ | Minimal GPU-accelerated terminal |

---

## Shell

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `zsh` | ✓ | ✓ | ✗ | ✓ | Primary interactive shell |
| `zsh-completions` | ✗ | ✓ | ✗ | ✗ | Extended Zsh completion definitions |
| `zsh-autosuggestions` | ✗ | ✓ | ✗ | ✓ | Fish-like command suggestions for Zsh |
| `zsh-syntax-highlighting` | ✗ | ✓ | ✗ | ✓ | Syntax coloring for Zsh command line |
| `starship` | ✓ | ✓ | ✓ | ✓ | Fast cross-shell prompt |
| `zoxide` | ✗ | ✓ | ✓ | ✗ | Smart `cd` with frecency ranking |
| `fzf` | ✓ | ✓ | ✓ | ✓ | Fuzzy finder for files, history, anything |
| `zsh-theme-powerlevel10k` | ✗ | A | ✗ | ✗ | Feature-rich Zsh prompt theme |

---

## Editors

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `neovim` | ✓ | ✓ | ✓ | ✓ | Lua-extensible modal text editor |
| `vi` | ✗ | ✓ | ✗ | ✗ | Minimal vi editor |
| `nano` | ✗ | ✓ | ✗ | ✓ | Simple terminal text editor (fallback) |

---

## File Managers

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `yazi` | ✗ | ✓ | ✗ | ✓ | Async TUI file manager |
| `thunar` | ~ | ✓ | ✗ | ✓ | Xfce GUI file manager |
| `gvfs` | ✗ | ✓ | ✗ | ✓ | Virtual filesystem (trash, MTP, network) |
| `gvfs-mtp` | ✓ | ✓ | ✓ | ✓ | MTP device support (Android phones) |
| `gvfs-smb` | ✓ | ✓ | ✓ | ✓ | Samba/network share support |
| `gvfs-nfs` | ✗ | ✗ | ✓ | ✓ | NFS network share support |

---

## System Monitoring

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `btop` | ✓ | ✓ | ✓ | ✓ | Interactive TUI resource monitor |
| `fastfetch` | ✓ | ✓ | ✓ | ✓ | Fast system info display (runs at shell start) |
| `inxi` | ✗ | ✓ | ✓ | ✓ | Detailed system info for debugging |
| `htop` | ✗ | ✗ | ✓ | ✓ | Classic interactive process viewer |

---

## Audio

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `pipewire` | ✗ | ✓ | ✓ | ✓ | Modern audio/video server |
| `pipewire-alsa` | ✗ | ✓ | ✓ | ✗ | ALSA compatibility via PipeWire |
| `pipewire-jack` | ✗ | ✓ | ✓ | ✗ | JACK compatibility via PipeWire |
| `pipewire-pulse` | ✗ | ✓ | ✓ | ✓ | PulseAudio compatibility via PipeWire |
| `wireplumber` | ✗ | ✓ | ✓ | ✓ | PipeWire session/policy manager |
| `pavucontrol` | ✗ | ✓ | ✗ | ✓ | PulseAudio-compatible volume control GUI |
| `alsa-utils` | ✗ | ✓ | ✓ | ✗ | ALSA command-line tools (amixer, etc.) |
| `playerctl` | ✗ | ✓ | ✓ | ✓ | Media player control via MPRIS |

---

## Theming / Appearance

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `matugen` | ✗ | ✓ | ✗ | ✓ | Generates color schemes from wallpaper |
| `python-pywal` | ✗ | ✓ | ✗ | ✗ | Alternate wallpaper-based color scheme tool |
| `papirus-icon-theme` | ✗ | ✓ | ✗ | A | Flat icon theme |
| `papirus-folders` | ✗ | A | ✗ | A | Colored folder variants for Papirus |
| `kvantum` | ✗ | ✓ | ✓ | ✓ | Qt theme engine with SVG themes |
| `gtk-engine-murrine` | ✗ | ✓ | ✗ | ✗ | GTK2 rendering engine |
| `gnome-themes-extra` | ✗ | ✓ | ✓ | ✗ | Additional GTK themes (includes Adwaita dark) |
| `nwg-look` | ✗ | ✓ | ✗ | ✓ | GTK settings GUI for Wayland |
| `cava` | ✗ | A | ✗ | ✓ | Terminal audio spectrum visualizer |

---

## Wallpaper

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `swaybg` | ✓ | ✗ | ✓ | ✗ | Simple static wallpaper setter for Wayland |
| `waypaper` | ✗ | ✓ | ✗ | A | GUI wallpaper browser/selector |
| `swww` | ✗ | ✓ | ✗ | ✓ | Animated wallpaper transitions for Wayland |
| `hyprpaper` | ✗ | ✓ | ✗ | ✗ | Hyprland-native wallpaper setter; remove with Hyprland |

---

## Screenshots & Screen Recording

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `grim` | ✓ | ✓ | ✓ | ✓ | Screenshot utility for Wayland |
| `slurp` | ✓ | ✓ | ✓ | ✓ | Interactive region selector for Wayland |
| `satty` | ✓ | ✓ | ✓ | ✓ | Screenshot annotation editor (Rust) |
| `gpu-screen-recorder` | ✓ | ✓ | ✓ | A | Hardware-accelerated screen recorder |
| `wf-recorder` | ✗ | ✓ | ✗ | ✗ | Alternative CLI screen recorder (wlroots) |
| `v4l-utils` | ✓ | ✗ | ✗ | ✗ | Webcam/video4linux utilities |

---

## OSD (On-Screen Display)

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `swayosd` | ✓ | ✓ | ✓ | ✓ | Volume and brightness OSD overlay |

---

## Fonts

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `noto-fonts` | ✓ | ✓ | ✓ | ✗ | Unicode coverage — no missing glyphs |
| `noto-fonts-cjk` | ✗ | ✗ | ✓ | ✗ | Chinese, Japanese, Korean glyphs |
| `noto-fonts-emoji` | ✓ | ✓ | ✓ | ✓ | Emoji support |
| `ttf-cascadia-code-nerd` | ✓ | ✗ | ✗ | ✗ | DOOM primary coding font |
| `ttf-jetbrains-mono-nerd` | ✗ | ✓ | ✓ | ✓ | Primary coding font for d00m_v0 + Omarchy |
| `ttf-font-awesome` | ✗ | ✓ | ✗ | ✓ | Icon font for waybar |
| `woff2-font-awesome` | ✗ | ✗ | ✓ | ✗ | Font Awesome in WOFF2 format (Omarchy) |
| `fontconfig` | ✗ | ✓ | ✓ | ✗ | Font rendering configuration |
| `ttf-material-design-icons-webfont` | ✗ | A | ✗ | ✗ | Material Design icons for waybar modules |
| `ttf-ia-writer` | ✗ | ✗ | ✓ | ✗ | iA Writer font (Omarchy) |

---

## Input

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `libinput` | ✗ | ✓ | ✗ | ✗ | Pointer, touchpad, and keyboard input |
| `fcitx5` | ✓ | ✓ | ✓ | ✗ | Input method framework (CJK, special chars) |
| `fcitx5-gtk` | ✓ | ✓ | ✓ | ✗ | GTK integration for fcitx5 |
| `fcitx5-qt` | ✓ | ✓ | ✓ | ✗ | Qt integration for fcitx5 |

---

## Network

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `networkmanager` | ✗ | ✓ | ✗ | ✓ | Network connection management daemon |
| `iwd` | ✗ | ✓ | ✓ | ✓ | Intel Wireless Daemon (fast WPA backend) |
| `tailscale` | ✗ | ✓ | ✗ | ✗ | WireGuard-based VPN mesh networking |
| `ufw` | ✓ | ✓ | ✓ | ✗ | Uncomplicated Firewall (iptables frontend) |
| `firewalld` | ✗ | ✗ | ✗ | ✓ | Dynamic firewall (Dusky's choice) |
| `avahi` | ✗ | ✓ | ✓ | ✗ | mDNS/DNS-SD for local network discovery |
| `impala` | ✗ | A | ✓ | ✗ | TUI WiFi manager (Rust) |

---

## Bluetooth

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `bluez` | ✓ | ✓ | ✗ | ✓ | Bluetooth protocol stack |
| `bluez-utils` | ✓ | ✓ | ✗ | ✓ | Bluetooth CLI tools (`bluetoothctl`) |
| `bluetui` | ✓ | A | ✓ | ✓ | Minimal TUI Bluetooth manager (Rust) |
| `blueman` | ✗ | ✓ | ✗ | ✓ | Bluetooth GUI manager |

---

## Security & Authentication

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `gnome-keyring` | ✓ | ✓ | ✓ | ✓ | Secure secret/credential storage |
| `libsecret` | ✗ | ✓ | ✓ | ✓ | Library for accessing GNOME Keyring |
| `polkit-gnome` | ✓ | ✓ | ✓ | ✗ | GUI authentication agent for privileged ops |
| `hyprpolkitagent` | ✗ | ✗ | ✗ | ✓ | Hyprland-specific polkit agent (Dusky) |
| `openssh` | ✗ | ✓ | ✗ | ✓ | SSH client and server |
| `gnupg` | ✗ | ✓ | ✗ | ✗ | GPG encryption and signing |
| `fprintd` | ✓ | ✗ | ✗ | ✗ | Fingerprint authentication daemon |
| `libfido2` | ✓ | ✗ | ✗ | ✗ | FIDO2/Yubikey hardware key library |
| `pam-u2f` | ✓ | ✗ | ✗ | ✗ | PAM module for FIDO2/Yubikey login |

---

## Development Tools

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `base-devel` | ✓ | ✓ | ✓ | ✓ | Build tools: gcc, make, binutils, etc. |
| `git` | ✗ | ✓ | ✓ | ✓ | Version control system |
| `github-cli` | ✓ | ✓ | ✓ | ✗ | GitHub CLI (`gh`) |
| `lazygit` | ✓ | ✓ | ✓ | ✗ | TUI Git client |
| `git-delta` | ✓ | ✗ | ✗ | ✓ | Enhanced diff viewer with syntax highlighting |
| `jujutsu` | ✓ | ✗ | ✗ | ✗ | Alternative VCS with first-class conflicts |
| `docker` | ✗ | ✓ | ✓ | ✗ | Container runtime |
| `docker-compose` | ✗ | ✓ | ✓ | ✗ | Multi-container Docker orchestration |
| `docker-buildx` | ✗ | ✓ | ✓ | ✗ | Extended Docker build (multi-arch, etc.) |
| `lazydocker` | ✗ | A | ✓ | A | TUI Docker client |
| `clang` | ✗ | ✓ | ✓ | ✓ | C/C++/Obj-C compiler (LLVM frontend) |
| `llvm` | ✗ | ✓ | ✓ | ✗ | LLVM compiler infrastructure |
| `jq` | ✓ | ✓ | ✓ | ✓ | JSON processor and pretty-printer |
| `python` | ✗ | ✓ | ✗ | ✗ | Python interpreter |
| `python-pip` | ✗ | ✓ | ✗ | ✗ | Python package installer |
| `rustup` | ✗ | ✓ | ✗ | ✗ | Rust toolchain manager (DOOM uses `rust` pkg) |
| `rust` | ✗ | ✗ | ✓ | ✗ | Rust compiler (Omarchy installs directly) |
| `luarocks` | ✓ | ✗ | ✓ | ✗ | Lua package manager |
| `tree-sitter-cli` | ✓ | ✗ | ✓ | ✓ | CLI for building Tree-sitter parsers |
| `mise` | ✓ | A | ✓ | ✗ | Polyglot dev tool version manager |

---

## CLI Utilities

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `bat` | ✓ | ✓ | ✓ | ✓ | `cat` with syntax highlighting and line numbers |
| `eza` | ✓ | ✓ | ✓ | ✓ | `ls` replacement with icons and git info |
| `fd` | ✓ | ✓ | ✓ | ✓ | `find` replacement — faster, simpler syntax |
| `ripgrep` | ✓ | ✓ | ✓ | ✓ | `grep` replacement (`rg`) — blazing fast |
| `dust` | ✓ | ✓ | ✓ | ✗ | `du` replacement — visual disk usage |
| `duf` | ✗ | ✓ | ✗ | ✗ | `df` replacement — visual filesystem info |
| `less` | ✓ | ✓ | ✓ | ✓ | Terminal file pager |
| `man-db` | ✓ | ✓ | ✓ | ✓ | Manual page viewer |
| `curl` | ✓ | ✓ | ✗ | ✓ | HTTP/HTTPS/FTP transfer tool |
| `wget` | ✓ | ✓ | ✓ | ✓ | File downloader |
| `unzip` | ✓ | ✓ | ✓ | ✓ | ZIP archive extraction |
| `zip` | ✗ | ✓ | ✗ | ✓ | ZIP archive creation |
| `p7zip` | ✗ | ✓ | ✗ | ✓ | 7-Zip support (p7zip / 7zip) |
| `rsync` | ✗ | ✓ | ✗ | ✓ | Efficient file sync and transfer |
| `inetutils` | ✓ | ✓ | ✓ | ✓ | Network tools: hostname, ftp, etc. |
| `tmux` | ✓ | ✓ | ✓ | ✗ | Terminal multiplexer |
| `zellij` | ✗ | ✗ | ✗ | ✓ | Modern terminal multiplexer (Rust) |
| `gum` | ✓ | ✓ | ✓ | ✓ | Shell script UI components |
| `skim` | ✓ | ✗ | ✗ | ✗ | Fuzzy finder written in Rust |
| `tealdeer` | ✓ | ✗ | ✓ | ✓ | Fast `tldr` client for command help |
| `ncdu` | ✓ | ✗ | ✗ | ✗ | Interactive disk usage navigator |
| `caligula` | ✓ | ✗ | ✗ | ✓ | TUI for `dd` / disk imaging |
| `hledger` | ✓ | ✗ | ✗ | ✗ | Plain-text double-entry accounting |
| `gopass` | ✓ | ✗ | ✗ | ✗ | CLI password manager (git-based) |
| `pacman-contrib` | ✓ | ✗ | ✗ | ✓ | Pacman helper scripts (paccache, etc.) |
| `expac` | ✗ | ✓ | ✓ | ✓ | Pacman data extraction utility |
| `wtype` | ✗ | A | ✗ | ✗ | Type text into Wayland windows |

---

## Media

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `ffmpeg` | ✓ | ✓ | ✗ | ✓ | Media processing Swiss Army knife |
| `ffmpegthumbnailer` | ✓ | ✓ | ✓ | ✓ | Video thumbnail generation for file managers |
| `imagemagick` | ✓ | ✓ | ✓ | ✓ | Image processing CLI |
| `imv` | ✓ | ✓ | ✓ | ✗ | Minimal image viewer for Wayland |
| `mpv` | ~ | ✓ | ✓ | ✓ | Feature-rich video player |

---

## Browsers

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `chromium` | ✗ | ✓ | ✓ | ✗ | Open-source Chromium browser |
| `firefox` | ✗ | ✓ | ✗ | ✓ | Mozilla Firefox browser |

---

## Productivity

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `obsidian` | ~ | ✓ | ✓ | ✓ | Markdown-based knowledge base and notes |
| `libreoffice-fresh` | ~ | ✓ | ✓ | A | Full office suite |
| `evince` | ✗ | ✓ | ✓ | ✗ | GNOME PDF/document viewer |
| `zathura` | ✗ | ✓ | ✗ | ✓ | Minimal keyboard-driven document viewer |
| `zathura-pdf-mupdf` | ✗ | ✓ | ✗ | ✓ | MuPDF backend for Zathura |
| `spotify` | ✗ | A | ✓ | ✗ | Spotify music client |
| `spicetify-cli` | ✗ | A | ✗ | ✗ | Spotify client theming tool |
| `claude-code` | ✗ | A | ✓ | ✗ | Claude AI coding CLI |

---

## System Tools

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `brightnessctl` | ✓ | ✓ | ✓ | ✓ | Display backlight brightness control |
| `acpi` | ✗ | ✓ | ✗ | ✗ | Battery and thermal info CLI |
| `upower` | ✓ | ✓ | ✗ | ✗ | Power management daemon |
| `power-profiles-daemon` | ✗ | ✗ | ✓ | ✗ | CPU power profile switching (Omarchy) |
| `bolt` | ✗ | ✓ | ✓ | ✗ | Thunderbolt device authorization manager |
| `tlp` | ✗ | ✓ | ✗ | ✓ | Laptop power management (battery longevity) |
| `tlp-rdw` | ✗ | ✓ | ✗ | ✓ | Radio device wizard for TLP |
| `cups` | ✗ | ✓ | ✓ | ✗ | Printing system daemon |
| `cups-pdf` | ✗ | ✓ | ✓ | ✗ | Print-to-PDF via CUPS |
| `pciutils` | ✓ | ✗ | ✗ | ✗ | PCI device info (`lspci`) |
| `usbutils` | ✓ | ✗ | ✗ | ✓ | USB device info (`lsusb`) |
| `fwupd` | ✗ | ✗ | ✗ | ✓ | Firmware update daemon |

---

## Filesystem

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `btrfs-progs` | ✗ | ✓ | ✓ | ✓ | Btrfs filesystem utilities |
| `snapper` | ✗ | ✓ | ✓ | ✗ | Btrfs/LVM snapshot management |
| `ntfs-3g` | ✗ | ✓ | ✗ | ✓ | Read/write NTFS filesystem support |
| `exfatprogs` | ✗ | ✓ | ✓ | ✗ | exFAT filesystem support |

---

## Performance

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `zram-generator` | ✗ | ✓ | ✓ | ✓ | Compressed swap in RAM (faster than disk swap) |
| `preload` | ✗ | ✓ | ✗ | ✗ | Adaptive readahead of frequently used binaries |

---

## Hardware / Peripheral (AUR)

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `makima-bin` | ✗ | A | ✓ | ✗ | Steam game controller input remapping |
| `asdcontrol` | ✓ | A | ✓ | ✗ | ASUS laptop keyboard backlight control |
| `asusctl` | ✗ | ✗ | ✓ | A | ASUS ROG/TUF power profiles and features |
| `hyprland-per-window-layout` | ✗ | A | ✗ | ✗ | Per-window keyboard layout; remove with Hyprland |

---

## Misc / XDG / Utilities

| Package | DOOM | d00m_v0 | Omarchy | Dusky | Description |
|---------|------|---------|---------|-------|-------------|
| `xdg-user-dirs` | ✗ | ✓ | ✗ | ✓ | Creates ~/Documents, ~/Pictures, etc. |
| `shared-mime-info` | ✗ | ✓ | ✗ | ✗ | MIME type database |
| `desktop-file-utils` | ✗ | ✓ | ✗ | ✗ | Desktop entry file utilities |
| `wlr-randr` | ✗ | ✓ | ✗ | ✗ | Display config CLI for wlroots compositors |
| `localsend` | ✗ | ✗ | ✓ | ✗ | Cross-platform local file sharing (AirDrop-like) |

---

## Summary Counts

| Source | Official | AUR | Total |
|--------|----------|-----|-------|
| **DOOM** | ~60 | 1 (conditional) | ~61 |
| **d00m_v0** | ~160 | 18 | ~178 |
| **Omarchy** | ~149 + 51 | — | ~200 |
| **Dusky** | ~193 + 47 | 17 core + 76 opt | ~333+ |

---

## Key Differences at a Glance

| Area | DOOM | d00m_v0 | Omarchy | Dusky |
|------|------|---------|---------|-------|
| Window manager | Hyprland | **→ mango WM** | Hyprland | Hyprland |
| Login / greeter | greetd + tuigreet | sddm **→ auto-login** | sddm | none listed |
| Primary terminal | Ghostty | Kitty | Alacritty | Kitty |
| Coding font | Cascadia Code Nerd | JetBrains Mono Nerd | JetBrains Mono Nerd | JetBrains Mono Nerd |
| Notification daemon | mako | mako | mako | swaync |
| Wallpaper tool | swaybg | swww + waypaper | swaybg | swww |
| Audio setup | Implicit | Full PipeWire stack | Full PipeWire stack | Full PipeWire stack |
| Containers | ✗ | Full Docker stack | Full Docker stack | ✗ |
| Filesystem tools | ✗ | btrfs-progs + snapper | btrfs-progs + snapper | btrfs-progs |
| Browsers | ✗ | chromium + firefox | chromium | firefox |
| Fingerprint/FIDO2 | ✓ | ✗ | ✗ | ✗ |
| Scope | Lean / curated | Comprehensive | Curated + opinionated | Maximal + modular |
