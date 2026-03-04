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

# Git ammend to pushed commit/pr
git add <files>
git commit --amend --no-edit (-S) // For signed
git push --force-with-lease

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

remove stupid border about:config zen.theme.content-element-separation

youtube open videos on theater mode:
  document.cookie = "wide=1; domain=.youtube.com; path=/; expires=Fri, 31 Dec 9999 23:59:59 GMT";

# Stow
What is Stow?

  GNU Stow is a symlink manager - a program that creates symbolic links (symlinks) from one directory to another in an organized, manageable
  way. Think of it as an automated assistant that creates shortcuts for you, but in a very structured manner.

  It was originally designed to help manage software installations, but today it's most commonly used for managing dotfiles (configuration files
   like .bashrc, .zshrc, etc.).

  ---
  The Problem Stow Solves

  Without Stow:

  Imagine you have dotfiles scattered across your home directory:
  /home/user/
  ├── .bashrc
  ├── .vimrc
  ├── .config/
  │   ├── nvim/init.vim
  │   ├── alacritty/alacritty.yml
  │   └── git/config
  └── .zshrc

  Problems:
  1. Hard to version control - Files are scattered everywhere
  2. Hard to backup - You need to remember which files to backup
  3. Hard to sync - Moving to a new machine means finding all config files
  4. No organization - Everything mixed with other files in home directory

  With Stow:

  You organize everything in one place:
  ~/dotfiles/
  ├── zsh/
  │   └── .zshrc
  ├── vim/
  │   └── .vimrc
  ├── nvim/
  │   └── .config/
  │       └── nvim/
  │           └── init.vim
  └── git/
      └── .config/
          └── git/
              └── config

  Then Stow creates symlinks from these organized files to where they need to be in your home directory.

  ---
  How Stow Works: Core Concepts

  1. The Stow Directory (Source)

  This is where your actual files live. Usually ~/dotfiles/.

  2. The Target Directory (Destination)

  This is where symlinks will be created. Usually your home directory ~.

  3. Packages

  Each subdirectory inside the stow directory is a "package". For example:
  ~/dotfiles/
  ├── zsh/        ← Package 1
  ├── vim/        ← Package 2
  └── nvim/       ← Package 3

  4. The Magic: Directory Structure Mirroring

  Stow mirrors the directory structure inside each package to the target directory.

  Example:
  ~/dotfiles/zsh/
  └── .zshrc

  After running: stow zsh
  Result in home (~):
  └── .zshrc → ~/dotfiles/zsh/.zshrc (symlink)

  More complex example:
  ~/dotfiles/nvim/
  └── .config/
      └── nvim/
          └── init.vim

  After running: stow nvim
  Result in home (~):
  └── .config/
      └── nvim/
          └── init.vim → ~/dotfiles/nvim/.config/nvim/init.vim (symlink)

  The directory structure .config/nvim/ is preserved!

  ---
  Basic Usage

  1. Stow a Package (Create Symlinks)

  cd ~/dotfiles
  stow zsh
  This creates symlinks from ~/dotfiles/zsh/* to ~/*

  2. Unstow a Package (Remove Symlinks)

  cd ~/dotfiles
  stow -D zsh
  This removes the symlinks created by stow (but keeps the original files)

  3. Restow a Package (Remove and Re-create)

  cd ~/dotfiles
  stow -R zsh
  Useful after making changes to the package structure

  4. Stow Multiple Packages

  cd ~/dotfiles
  stow zsh vim nvim git

  5. Stow All Packages

  cd ~/dotfiles
  stow */

  6. Dry Run (See what would happen without doing it)

  cd ~/dotfiles
  stow -n zsh
  Shows what would be created/removed without actually doing it

  7. Verbose Mode (See what stow is doing)

  cd ~/dotfiles
  stow -v zsh
  
  8. By default, stow targets the parent directory. To target a different directory:

  cd ~/dotfiles
  stow -t /some/other/dir zsh 

  ---
  Practical Examples

  Example 1: Simple Dotfiles Setup

  Setup:
  mkdir ~/dotfiles
  cd ~/dotfiles

  ## Create zsh package
  mkdir -p zsh
  echo 'export EDITOR=nvim' > zsh/.zshrc

  ## Create vim package
  mkdir -p vim
  echo 'set number' > vim/.vimrc

  ## Stow them
  stow zsh vim

  Result:
  ~ (home directory)
  ├── .zshrc → ~/dotfiles/zsh/.zshrc
  └── .vimrc → ~/dotfiles/vim/.vimrc

  Example 2: Config Directory Structure

  Setup:
  cd ~/dotfiles

  ## Create git package with proper structure
  mkdir -p git/.config/git
  cat > git/.config/git/config <<EOF
  [user]
      name = Your Name
      email = you@example.com
  EOF

  ## Stow it
  stow git

  Result:
  ~/.config/git/config → ~/dotfiles/git/.config/git/config

  Example 3: Moving Existing Dotfiles to Stow

  Current state:
  ~ (home)
  └── .zshrc (actual file)

  Migration:
  ## 1. Create dotfiles directory and package
  mkdir -p ~/dotfiles/zsh

  ## 2. Move existing file into package
  mv ~/.zshrc ~/dotfiles/zsh/

  ## 3. Stow the package (creates symlink)
  cd ~/dotfiles
  stow zsh

  Final state:
  ~/dotfiles/zsh/
  └── .zshrc (actual file)

  ~ (home)
  └── .zshrc → ~/dotfiles/zsh/.zshrc (symlink)
  ---
  Common Use Cases

  Have different configs for work vs personal:
  ~/dotfiles/
  ├── zsh-work/
  │   └── .zshrc (work-specific)
  └── zsh-personal/
      └── .zshrc (personal-specific)

  Testing New Configurations

  ~/dotfiles/
  ├── nvim/          (stable config)
  └── nvim-experimental/  (testing new config)

  ## Try experimental:
  stow -D nvim
  stow nvim-experimental

  ## Revert:
  stow -D nvim-experimental
  stow nvim
  ---
  Pros and Cons

  Pros ✓

  1. Centralized Management
    - All dotfiles in one place
    - Easy to find and edit
  2. Version Control Friendly
    - Everything in one directory = easy to git commit
    - Track history of all config changes
  3. Easy Deployment
    - New machine: git clone dotfiles && cd dotfiles && stow */
    - That's it - all configs deployed
  4. Non-Destructive
    - Original files stay in dotfiles directory
    - Symlinks can be easily removed without losing data
  5. Selective Installation
    - Only stow what you need
    - stow nvim on servers, skip GUI configs
  6. Conflict Detection
    - Stow warns if target file already exists
    - Prevents accidental overwrites
  7. Platform-Specific Configs
    - Different packages for different machines
    - stow linux-desktop vs stow macos
  8. Easy Testing
    - Unstow old, stow new, test
    - Quick rollback with stow -R

  Cons ✗

  1. Learning Curve
    - Need to understand symlinks
    - Need to understand stow's directory mirroring
    - Initial setup can be confusing
  2. Symlink Awareness
    - Some programs don't follow symlinks well
    - Some programs recreate files instead of editing symlinks
    - Can break stow setup if not careful
  3. Directory Structure Requirements
    - Must mirror target structure in packages
    - Can be verbose: nvim/.config/nvim/init.vim
    - More directories to navigate
  4. Conflicts
    - If target file exists, stow refuses to proceed
    - Must manually resolve conflicts
    - Can be annoying during initial setup
  5. Not Great for Binary Files
    - Best for text configs
    - Binary files work but defeat the purpose (no easy diffing)
  6. Overhead for Simple Cases
    - If you only have 2-3 dotfiles, stow might be overkill
    - Direct symlinks might be simpler
  7. Deletion Confusion
    - Deleting a symlink doesn't delete the original
    - Can forget what's actually stowed vs manually created
  8. Platform Differences
    - Different stow versions behave slightly differently
    - GNU stow vs other implementations

  ---
  ## 3. **Use .stow-local-ignore**
  Ignore files you don't want stowed:
  bash
  ## ~/dotfiles/.stow-local-ignore
  README.md
  LICENSE
  .git
  .gitignore
  install.sh
  ---
  Common Gotchas

  1. Wrong Directory

  ## ❌ Wrong - running from home
  cd ~
  stow dotfiles/zsh  # ERROR

  ## ✓ Correct - running from stow directory
  cd ~/dotfiles
  stow zsh

  2. File Already Exists

  $ stow zsh
  ERROR: .zshrc already exists and is not a symlink

  ## Solution: Remove or backup first
  mv ~/.zshrc ~/.zshrc.old
  stow zsh

  3. Nested Packages

  ## ❌ Wrong structure
  dotfiles/
  └── configs/
      └── zsh/
          └── .zshrc

  ## ✓ Correct structure
  dotfiles/
  └── zsh/
      └── .zshrc

  4. Forgetting to Unstow

  ## Moving packages around? Unstow first!
  stow -D old-nvim
  stow new-nvim
  ---
  Summary

  Use Stow if:
  - You have many dotfiles to manage
  - You want version control
  - You sync configs across machines
  - You like organized directory structures

  Skip Stow if:
  - You only have 1-2 config files
  - You're happy with manual symlinks

# Secrets Management

# Devbox
A command-line tool that creates isolated, reproducible dev environments using Nix under the hood. Written in Go.

  How it works:
  - Uses Nix package manager without requiring you to learn Nix language
  - Creates a devbox.json defining your dependencies
  - Packages are stored in /nix/store/ with content-addressed hashing
  - Running devbox shell drops you into an isolated environment

  Architecture:
  project/
  ├── devbox.json          # Your dependencies
  ├── devbox.lock          # Locked versions
  └── .devbox/
      └── virtenv/         # Generated environment scripts

  /nix/store/
  ├── abc123-nodejs-18.17.0/
  ├── def456-python-3.11.4/
  └── ...                  # Content-addressed, immutable

  Key insight: Nix store is deduplicated. If two projects use Node 18.17.0, there's only one copy on disk.

# Direnv
What it is: Environment variable manager per directory. Written in Go.

  How it works:
  - Reads .envrc files when you cd into directories
  - Sets/unsets environment variables automatically
  - Often combined with Nix or mise

  Example .envrc:
  export DATABASE_URL=postgres://localhost/myapp
  use mise        # Integrates with mise
  # or
  use flake       # Integrates with Nix flakes

  Essential companion to mise/devbox/nix.

# New Subject
