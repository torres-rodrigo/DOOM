# Auto login with encription
┌──────────────────┬────────────────┬────────────────┬──────────────────────────────────────┐
│ Display Manager  │      Size      │      Type      │               Best For               │
├──────────────────┼────────────────┼────────────────┼──────────────────────────────────────┤
│ SDDM             │ ~60MB          │ Graphical (Qt) │ Multi-user, themes, graphical login  │
├──────────────────┼────────────────┼────────────────┼──────────────────────────────────────┤
│ greetd           │ ~3MB           │ Minimal daemon │ Single user, auto-login, flexibility │
├──────────────────┼────────────────┼────────────────┼──────────────────────────────────────┤
│ ly               │ ~2MB           │ TUI            │ Minimalist TUI login screen          │
├──────────────────┼────────────────┼────────────────┼──────────────────────────────────────┤
│ getty auto-login │ 0MB (built-in) │ No DM          │ Your use case!                       │
└──────────────────┴────────────────┴────────────────┴──────────────────────────────────────┘
Option 1
```
✅ RECOMMENDED: Option 1 - getty Auto-Login (Most Minimal)
  This is the lightest possible solution - no display manager at all!
  How It Works:
  Boot → LUKS Password (Plymouth) → Auto-login to TTY → Hyprland Starts
  You only type your LUKS password once, then everything auto-starts.
  Complete Setup Guide:
  Step 1: Create Auto-Start Script
  Create cDOOM/login/getty-autologin.sh:
  #!/bin/bash
  echo "Configuring getty auto-login..."
  # Create systemd override directory for getty@tty1
  sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
  # Create auto-login override
  cat <<EOF | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf
  [Service]
  ExecStart=
  ExecStart=-/sbin/agetty -o '-p -f -- \\u' --noclear --autologin $USER %I \$TERM
  EOF
  # Enable the service
  sudo systemctl enable getty@tty1.service
  echo "Getty auto-login configured for user: $USER"
  Step 2: Auto-Start Hyprland on Login
  Add to your shell profile to auto-start Hyprland when logging into TTY1.
  For ZSH (create cDOOM/config/zsh/.zprofile):
  # Auto-start Hyprland on TTY1
  if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec uwsm start hyprland
  fi
  For Bash (create cDOOM/config/bash/.bash_profile):
  # Auto-start Hyprland on TTY1
  if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec uwsm start hyprland
  fi
  Step 3: Update Installation Script
  Add to cDOOM/doom_install.sh:
  #CONFIG SETUP
  cp -r config/* ~/.config/
  # Copy shell profile for auto-start
  if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
      cp "$DOOM_DIR/config/zsh/.zprofile" "$ZDOTDIR/.zprofile"
  else
      cp "$DOOM_DIR/config/bash/.bash_profile" "$HOME/.bash_profile"
  fi
  #END CONFIG SETUP

  #AUTO-LOGIN SETUP
  echo "4. AUTO-LOGIN SETUP"
  run_script "$DOOM_DIR/login/getty-autologin.sh"
  echo "$SPACER"
  echo
  #END AUTO-LOGIN SETUP
```

Option 2
```
If you want slightly more flexibility (easier to disable auto-login later), use greetd.

  How It Works:

  Boot → LUKS Password (Plymouth) → greetd auto-login → Hyprland Starts

  Complete Setup Guide:

  Step 1: Add Packages

  Add to cDOOM/packages/packages.sh:

  PACKAGES=(
      #System
      "base-devel"
      "gnome-keyring"
      "greetd"          # ← ADD THIS (minimal display manager)
      # ... rest of packages

  Step 2: Create greetd Configuration

  Create cDOOM/login/greetd.sh:

  #!/bin/bash

  echo "Configuring greetd with auto-login..."

  # Create greetd config directory if needed
  sudo mkdir -p /etc/greetd

  # Create auto-login configuration
  cat <<EOF | sudo tee /etc/greetd/config.toml
  [terminal]
  vt = 1

  [default_session]
  # Auto-login directly to Hyprland
  command = "uwsm start hyprland"
  user = "$USER"
  EOF

  # Enable greetd service
  sudo systemctl enable greetd.service

  echo "greetd configured for auto-login as: $USER"

  Step 3: Update Installation Script

  Add to cDOOM/doom_install.sh:

  #AUTO-LOGIN SETUP
  echo "4. AUTO-LOGIN SETUP"
  run_script "$DOOM_DIR/login/greetd.sh"
  echo "$SPACER"
  echo
  #END AUTO-LOGIN SETUP

  ---
```

# Git multi user per dir
gitconfig
```
[includeIf "gitdir/i:C:/Users/rodrigo.torrescosta/Documents/LOCAL_DOCS/my_projects/"]
	path = C:/Users/rodrigo.torrescosta/.gitconfig-personal
```

gitconfig-personal
```
[user]
	name = 
	email = 
```

# Claude recomendations
```
1. Display Manager & Auto-Login

  Current: Nothing - boots to TTY
  Add:
  - Getty auto-login (minimal) OR greetd/SDDM
  - Auto-start Hyprland configuration
  - Session management integration

  Why: Without this, Hyprland doesn't start automatically after boot.

  2. Plymouth Boot Splash Configuration

  Current: Package installed but not configured
  Add:
  - Custom cDOOM Plymouth theme (logo, progress bar, password entry)
  - Plymouth script with animations
  - Integration with LUKS password entry

  Why: Currently just shows text during boot. Plymouth makes it polished and branded.

  3. Waybar Status Bar

  Current: Missing entirely
  Add:
  - /config/waybar/config.jsonc - Status bar configuration
  - /config/waybar/style.css - Custom styling
  - System indicators (battery, network, audio, workspaces, clock)

  Why: No system information visible without it (time, battery, network status, etc.)

  4. Notification System

  Current: Mako installed but not configured
  Add:
  - /config/mako/config - Notification daemon styling
  - /config/swayosd/config.toml - On-screen display for volume/brightness

  Why: No visual feedback for notifications, volume changes, brightness adjustments.

  ---
  💎 IMPORTANT USER EXPERIENCE FEATURES

  5. Application Launcher

  Current: Nothing
  Add:
  - Walker app launcher configuration (/config/walker/config.toml)
  - Rofi/fuzzel as alternative
  - Keybinding: SUPER + SPACE to launch apps

  Why: Currently no way to launch applications without terminal.

  6. System Utility Scripts

  Current: 9 basic scripts (TUI/webapp installers)
  Add Core Scripts:
  bin/doom-menu                  # Main system menu
  bin/doom-theme-*               # Theme management (set, list, current)
  bin/doom-pkg-*                 # Package management (install, remove, list)
  bin/doom-cmd-screenshot        # Screenshot tool
  bin/doom-cmd-screenrecord      # Screen recording
  bin/doom-launch-*              # Smart app launchers
  bin/doom-restart-*             # Service restart utilities
  bin/doom-update                # System update script

  Why: Makes system management accessible without remembering commands.

  7. Keybinding Documentation System

  Current: Bindings exist but not discoverable
  Add:
  - bin/doom-list-keybindings - Interactive keybinding viewer
  - SUPER + K - Show all shortcuts
  - Searchable with fuzzy finder

  Why: Users need to know what keybindings exist.

  8. Theme System

  Current: No theming
  Add:
  themes/
  ├── tokyo-night/           # Default theme
  ├── gruvbox/
  ├── catppuccin/
  └── nord/

  Each theme includes:
  ├── colors.toml            # Color definitions
  ├── hyprland.conf          # Compositor colors
  ├── waybar.css             # Status bar
  ├── alacritty.toml         # Terminal
  ├── btop.theme             # System monitor
  ├── backgrounds/           # Wallpapers
  └── preview.png

  Why: Users want visual customization without manually editing configs.

  ---
  🛠️ QUALITY OF LIFE IMPROVEMENTS

  9. Desktop Application Entries

  Current: None
  Add:
  applications/
  ├── hidden/                # Hide system clutter apps
  │   ├── btop.desktop
  │   ├── cups.desktop
  │   └── [30+ system apps]
  └── icons/                 # Custom app icons

  Why: Launcher shows too many internal/system apps by default.

  10. First-Run Experience

  Current: Nothing
  Add:
  install/first-run/
  ├── welcome.sh             # Welcome screen on first boot
  ├── theme-selector.sh      # Choose initial theme
  ├── wifi-setup.sh          # Network configuration
  └── battery-monitor.sh     # Laptop power management

  Why: Guides new users through initial setup.

  11. Common Terminal Utilities

  Current: Good coverage, missing some
  Add:
  - lazygit config (/config/lazygit/config.yml)
  - btop config (/config/btop/btop.conf)
  - imv image viewer config
  - mpv media player config

  Why: Pre-configured tools work better out of the box.

  12. Font Management

  Current: Basic font installation
  Add:
  - /config/fontconfig/fonts.conf - Font rendering config
  - Font utility scripts (doom-font-list, doom-font-set)
  - Nerd Fonts (all variants)

  Why: Better font rendering and user customization.

  ---
  🔧 ADVANCED FEATURES

  13. Hardware-Specific Configurations

  Current: None
  Add:
  install/config/hardware/
  ├── laptop-detect.sh       # Auto-detect laptop vs desktop
  ├── nvidia-setup.sh        # Enhanced NVIDIA config
  ├── bluetooth-setup.sh     # Bluetooth configuration
  └── power-management.sh    # TLP/power-profiles-daemon

  Why: Different hardware needs different configs.

  14. Browser Integration

  Current: None
  Add:
  - Chromium/Firefox flags configuration
  - Browser-based web app support
  - Password manager integration (1Password/Bitwarden)

  Why: Modern workflows rely heavily on browsers.

  15. Development Environment Setup

  Current: Mise/gopass documentation only
  Add:
  bin/doom-install-dev-env   # Install language runtimes
  Languages: Ruby, Python, Node.js, Go, Rust, Java, .NET

  Why: Developers need quick environment setup.

  16. Migration System

  Current: None
  Add:
  migrations/
  ├── [timestamp]_feature_name.sh
  └── migration-runner.sh

  Why: Allows safe updates without breaking user configs.

  ---
  📋 RECOMMENDED PRIORITY IMPLEMENTATION ORDER

  Phase 1: Functional Basics (Make it work)

  1. ✅ Display manager + auto-login (getty/greetd)
  2. ✅ Waybar status bar
  3. ✅ Application launcher (Walker/Rofi)
  4. ✅ Notification system (Mako + SwayOSD)
  5. ✅ Plymouth boot splash theme

  Phase 2: Essential UX (Make it usable)

  6. ✅ System utility scripts (20-30 core scripts)
  7. ✅ Theme system (3-5 themes)
  8. ✅ Keybinding viewer
  9. ✅ Screenshot/screenrecord tools
  10. ✅ Desktop application cleanup

  Phase 3: Polish (Make it great)

  11. ✅ First-run experience
  12. ✅ Font management
  13. ✅ Hardware detection
  14. ✅ Browser integration
  15. ✅ Development environment setup

  Phase 4: Long-term (Make it maintainable)

  16. ✅ Migration system
  17. ✅ Update channels (stable/edge)
  18. ✅ Backup/restore utilities
  19. ✅ Debug/diagnostic tools

  ---
  🎨 My Recommended Minimal Complete Setup

  If I were to make cDOOM production-ready with minimum additions, here's what I'd prioritize:

  Critical (Week 1)

  1. Getty auto-login           # So Hyprland starts
  2. Waybar                     # Status bar
  3. Walker/Rofi                # App launcher
  4. doom-menu script           # System control
  5. Plymouth theme             # Boot splash

  Important (Week 2)

  6. Basic theme system         # 2-3 themes
  7. Screenshot/record tools    # Media capture
  8. Mako notifications         # Visual feedback
  9. Package management scripts # doom-pkg-install, etc.
  10. Keybinding viewer         # SUPER+K

  Nice-to-Have (Week 3+)

  11. First-run wizard
  12. Multiple themes (10+)
  13. Hardware detection
  14. Migration system

  ---
  📊 File Count Comparison
  ┌──────────────────────┬───────────┬────────────────────────┬────────────────────┐
  │      Component       │ cDOOM Now │ With Minimal Additions │ Full omarchy-level │
  ├──────────────────────┼───────────┼────────────────────────┼────────────────────┤
  │ Config files         │ 37        │ ~80                    │ 775+               │
  ├──────────────────────┼───────────┼────────────────────────┼────────────────────┤
  │ Utility scripts      │ 9         │ ~40                    │ 161                │
  ├──────────────────────┼───────────┼────────────────────────┼────────────────────┤
  │ Themes               │ 0         │ 3-5                    │ 14                 │
  ├──────────────────────┼───────────┼────────────────────────┼────────────────────┤
  │ Installation scripts │ 3         │ ~15                    │ 50+                │
  ├──────────────────────┼───────────┼────────────────────────┼────────────────────┤
  │ Total effort         │ Baseline  │ 2-3 weeks              │ 2-3 months         │
  └──────────────────────┴───────────┴────────────────────────┴────────────────────┘
  ---
  🎯 Bottom Line

  To make cDOOM a complete system like omarchy, you need:

  Minimum viable (weekend project):

  - Display manager auto-login
  - Waybar status bar
  - Application launcher
  - 5-10 utility scripts

  Production ready (2-3 weeks):

  - Above + theme system
  - Plymouth boot splash
  - Screenshot/media tools
  - 30-40 utility scripts
  - First-run experience

  omarchy-level polish (2-3 months):

  - Everything above +
  - 14+ themes
  - 161 utility scripts
  - Migration system
  - Hardware detection
  - Full documentation
```
# zen setup
download zen tar.xz
tar -xvf zen.linux-x86_64.tar.xz
chmod +x zen/.zen
sudo mv zen /opt/
sudo v /usr/share/applications/zen.desktop
```
[Desktop Entry]
Name=Zen
Exec=/opt/zen/zen
Icon=/opt/zen/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;

```


# New subject
