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
  or
  use flake       # Integrates with Nix flakes

  Essential companion to mise/devbox/nix.

# Gopass and GPG
```
gpg --full-generate-key
```
Choose:
  ECC → ed25519 (signing)
  Add encryption subkey (cv25519)
  Set expiration (1–2 years)
  Strong passphrase (20+ characters)

Verify: `gpg --list-secret-keys --keyid-format LONG`

Export secret key: `gpg --export-secret-keys YOUR_KEY_ID > master.key`

Move master.key to:
Encrypted USB
Offline backup storage
NOT cloud storage

Then delete master key from daily system: `gpg --delete-secret-key YOUR_KEY_ID`

Re-import only subkeys:
```
gpg --import master.key
gpg --edit-key YOUR_KEY_ID
> key 1
> keytocard (optional if using hardware)
> save
```
Then remove master secret again, keeping subkeys.

Init gopass
`gopass init YOUR_KEY_ID`

This:
Creates .gopass-store
Encrypts everything using your GPG key
Prepares Git integration

Setup github
```
cd ~/.password-store
git init
git remote add origin git@github.com:USERNAME/repo.git
git push -u origin main
```
mportant:

✔ Only encrypted .gpg files are committed
✔ Never commit .gnupg directory
✔ Never commit private keys

Add .gitignore:
```
.gnupg/
*.key
```

Multi-Device Secure Workflow
Install:
gpg
gopass
git

Import Your Subkey (NOT master) from your secure backup:
`gpg --import subkey.key`
Verify
`gpg --list-secret-keys`

`git clone git@github.com:USERNAME/repo.git ~/.password-store`

`gopass init YOUR_KEY_ID`

Daily Usage Workflow
Add password
gopass insert accounts/github

Generate password
gopass generate accounts/email 32

Sync
git push


On another device:
git pull

Use a Hardware Token

Use:

YubiKey

Move encryption subkey to smartcard:

gpg --edit-key YOUR_KEY_ID
> key 1
> keytocard


Now private key cannot be extracted from device.


# Potential System organazation
Minimal, clean, organized
~/Downloads
~/Projects
~/Documents
~/Documents/vault
~/Pictures
~/Pictures/Screenshots
~/Videos
~/Videos/Screen-recordings

# Bank statement converter
Convert bank statements to a readable format for hledger, and other useful formats
Personal use first, expand for later

# wezterm multiplexing
How it works

  WezTerm has a built-in mux server (wezterm-mux-server) that runs as a headless daemon. The GUI is just a client that connects to it.
   When you close the GUI, the server keeps running in the background — when you reopen WezTerm, it reconnects and everything is as
  you left it.

  ---
  Session persistence (what you want)

  The minimal config to enable this is two lines:

  config.unix_domains = { { name = 'unix' } }
  config.default_gui_startup_args = { 'connect', 'unix' }

  unix_domains registers a local Unix socket domain. default_gui_startup_args tells WezTerm to auto-connect to it on every launch
  instead of starting fresh.

  What gets restored: all tabs, panes, split layouts, and working directories.

# wezterm layouts
The two startup events

┌─────────────┬─────────────────────────────────────────────────────────────┬──────────────────────────────────────────────┐
│    Event    │                        When it fires                        │                  Use it for                  │
├─────────────┼─────────────────────────────────────────────────────────────┼──────────────────────────────────────────────┤
│ gui-startup │ Every time the GUI launches                                 │ Creating your initial window/tab/pane layout │
├─────────────┼─────────────────────────────────────────────────────────────┼──────────────────────────────────────────────┤
│ mux-startup │ Once when the mux server starts (only if using unix domain) │ Server-level setup, background processes     │
└─────────────┴─────────────────────────────────────────────────────────────┴──────────────────────────────────────────────┘

For layouts you'll almost always use gui-startup. If you add the unix domain for session persistence, gui-startup still fires on
every GUI attach, while mux-startup fires only once at the start of the server — meaning your layout is built once and then
persists.

---
The core API

Everything flows from mux.spawn_window() → pane:split() → pane:send_text():

local wezterm = require 'wezterm'
local mux = wezterm.mux

wezterm.on('gui-startup', function()
    local tab, pane, window = mux.spawn_window({
        workspace = 'code',
        cwd = wezterm.home_dir .. '/projects/myapp',
    })

    -- Split right 30% — git status pane
    local git_pane = pane:split({
        direction = 'Right',
        size = 0.3,
        cwd = wezterm.home_dir .. '/projects/myapp',
    })
    git_pane:send_text('git status\n')

    -- Split bottom of the left pane 35% — run server
    local server_pane = pane:split({
        direction = 'Bottom',
        size = 0.35,
    })
    server_pane:send_text('npm run dev\n')

    pane:activate()  -- focus the main pane
end)

This gives you:
┌────────────────────┬──────────┐
│                    │          │
│   main pane        │  git     │
│   (nvim, editor)   │  status  │
│                    │          │
├────────────────────│          │
│   server / build   │          │
└────────────────────┴──────────┘

---
Workspaces

Workspaces are named groups of windows — think tmux sessions. You give them a name when you spawn a window, then switch between them
  with actions:

-- Switch to a named workspace (creates it if it doesn't exist)
act.SwitchToWorkspace { name = 'monitoring' }

-- Cycle through workspaces
act.SwitchWorkspaceRelative(1)

-- Fuzzy picker to choose workspace
act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' }

You can show the current workspace name in your status bar — I noticed you already have update-status set up, so this would fit
naturally there alongside the leader indicator.

---
pane:split() direction model

Splits always subdivide the calling pane, not the window:

-- direction = 'Right'  → new pane appears to the RIGHT of the calling pane
-- direction = 'Bottom' → new pane appears BELOW the calling pane
-- size < 1.0           → fraction of the calling pane's size
-- size >= 1            → exact number of cells

So if you call pane:split({ direction = 'Bottom', size = 0.4 }) on a pane that's already been split, you're splitting just that
pane, not the full window height. This is important when building multi-pane layouts — the order and which pane you call split on
matters.

---
Practical note for your setup

Given you're already using this in doom_install.sh with zsh and the project is Hyprland/Arch focused, a practical layout might look
like:

- Workspace doom — project editing + git pane
- Workspace sys — btop + journalctl or a general shell
- Workspace default — clean shell, spawned fresh

1. Fuzzy menu to pick and trigger a layout

  ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } only lists already-open workspaces. For picking and creating a layout, you need
  InputSelector — WezTerm's built-in fuzzy picker that you populate with whatever choices you want.

  -- Define your layouts
  local layouts = {
      { id = 'doom',  label = 'DOOM — editor + git + shell' },
      { id = 'sys',   label = 'System — btop + logs' },
      { id = 'clean', label = 'Clean shell' },
  }

  -- Layout builder functions
  local function build_layout(id, window, pane)
      local mux = wezterm.mux
      if id == 'doom' then
          local _, main, _ = mux.spawn_window({ workspace = 'doom', cwd = wezterm.home_dir .. '/projects/DOOM' })
          local git_pane = main:split({ direction = 'Right', size = 0.3 })
          local shell_pane = main:split({ direction = 'Bottom', size = 0.35 })
          git_pane:send_text('git status\n')
          main:activate()

      elseif id == 'sys' then
          local _, main, _ = mux.spawn_window({ workspace = 'sys' })
          local logs_pane = main:split({ direction = 'Right', size = 0.5 })
          main:send_text('btop\n')
          logs_pane:send_text('journalctl -f\n')

      elseif id == 'clean' then
          mux.spawn_window({ workspace = 'clean' })
      end
  end

  -- Key binding: LEADER + l opens the layout picker
  { key = 'l', mods = 'LEADER', action = act.InputSelector {
      title   = 'Open Layout',
      fuzzy   = true,
      choices = layouts,
      action  = wezterm.action_callback(function(window, pane, id, label)
          if id then build_layout(id, window, pane) end
      end),
  }},

  InputSelector fields that matter:

  ┌──────────────┬─────────────────────────────────────────────────────────────────────────────────────────┐
  │    Field     │                                      What it does                                       │
  ├──────────────┼─────────────────────────────────────────────────────────────────────────────────────────┤
  │ choices      │ Array of { id, label } — id is what your callback receives, label is what the user sees │
  ├──────────────┼─────────────────────────────────────────────────────────────────────────────────────────┤
  │ fuzzy = true │ Enables typing to filter the list                                                       │
  ├──────────────┼─────────────────────────────────────────────────────────────────────────────────────────┤
  │ title        │ Header text of the picker                                                               │
  ├──────────────┼─────────────────────────────────────────────────────────────────────────────────────────┤
  │ action       │ Callback called with (window, pane, id, label) on selection; both are nil if cancelled  │
  └──────────────┴─────────────────────────────────────────────────────────────────────────────────────────┘

  ---
  2. Auto-triggering a layout by directory

  There are two practical approaches:

  A — Fuzzy directory picker that creates a workspace (recommended)

  Uses zoxide query -l to get your recently visited directories, shows them in InputSelector, then creates a workspace + layout for
  whichever you pick. No plugin needed:

  local function zoxide_dirs()
      local choices = {}
      local handle = io.popen('zoxide query -l 2>/dev/null')
      if handle then
          for line in handle:lines() do
              local name = line:match('^.*/(.+)$') or line
              table.insert(choices, { id = line, label = name .. '  ' .. line })
          end
          handle:close()
      end
      return choices
  end

  local function open_dir_workspace(window, pane, dir, _)
      if not dir then return end
      local name = dir:match('^.*/(.+)$') or dir
      local mux = wezterm.mux

      -- Only build the layout if the workspace doesn't already exist
      for _, ws in ipairs(mux.get_workspace_names()) do
          if ws == name then
              window:perform_action(act.SwitchToWorkspace { name = name }, pane)
              return
          end
      end

      local _, main, _ = mux.spawn_window({ workspace = name, cwd = dir })
      local git_pane = main:split({ direction = 'Right', size = 0.3, cwd = dir })
      git_pane:send_text('git status\n')
      main:activate()
  end

  { key = 'p', mods = 'LEADER', action = act.InputSelector {
      title   = 'Open Project',
      fuzzy   = true,
      choices = wezterm.action_callback(function() return zoxide_dirs() end),
      action  = wezterm.action_callback(open_dir_workspace),
  }},

  The key detail: before creating a new layout it checks mux.get_workspace_names() — so if you've already opened that project, it just
   switches to the existing workspace instead of rebuilding the layout on top of it.

  B — Shell function with wezterm cli

  Add this to your .zshrc. Whenever you run proj ~/projects/DOOM, it creates a workspace and layout from the shell side:

  proj() {
      local dir="${1:-.}"
      local name="${dir##*/}"

      # Create workspace with a layout using wezterm's CLI
      local pane_id
      pane_id=$(wezterm cli spawn --new-window --workspace "$name" --cwd "$dir")

      wezterm cli split-pane --pane-id "$pane_id" --right --percent 30 --cwd "$dir"
      wezterm cli activate-workspace "$name"
  }

  wezterm cli commands used here:

  ┌───────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────┐
  │                          Command                          │                      What it does                       │
  ├───────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ wezterm cli spawn --new-window --workspace NAME --cwd DIR │ Create a new window in a named workspace at a directory │
  ├───────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ wezterm cli split-pane --pane-id ID --right --percent 30  │ Split a specific pane                                   │
  ├───────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ wezterm cli send-text --pane-id ID "text"                 │ Send a command to a pane                                │
  ├───────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────┤
  │ wezterm cli activate-workspace NAME                       │ Switch the GUI to a named workspace                     │
  └───────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────┘

  ---
  Which to use

  ┌────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────┐
  │                     Situation                      │                          Best approach                          │
  ├────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ You have 2–5 predefined layouts you rotate between │ InputSelector with a hardcoded layout table                     │
  ├────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ You work across many project directories           │ Zoxide-based directory picker                                   │
  ├────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ You want to trigger it from the shell / scripts    │ wezterm cli shell function                                      │
  ├────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────┤
  │ You want both (pick layout and pick directory)     │ InputSelector for layouts → each layout builder prompts for dir │
  └────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────┘

  The most powerful combo is the zoxide picker: you cd around normally and zoxide learns your directories — then in WezTerm you hit a
  keybind, fuzzy-search the dir, and your layout appears automatically. Want me to write that up for your config?

# Hardening zen
https://github.com/arkenfox/user.js/wiki
https://github.com/Codextor/better-zen

Yes, this is exactly what Firefox's profile system is designed for. Since Zen is a Firefox fork it inherits it completely.

  ---
  How profiles work

  Each profile is a fully isolated directory under ~/.zen/ with its own:
  - user.js / prefs.js (settings)
  - Extensions
  - Cookies and logins
  - History and cache
  - Certificates

  The two instances don't share anything. You apply arkenfox only to the regular profile and leave the platforms profile untouched.

  ---
  Creating the two profiles

  Open Zen and go to about:profiles. Create two named profiles:

  - regular — your hardened daily driver
  - platforms — streaming only, permissive cookies and logins

  Or from the terminal:
  zen --ProfileManager

  ---
  Running both at the same time

  By default Firefox-based browsers refuse to open a second instance if one is already running. The --no-remote flag bypasses that:

  Regular (hardened)
  zen --no-remote -P regular

  Platforms (permissive)
  zen --no-remote -P platforms

  You can put these in shell aliases in your .zshrc:

  alias zen-regular='zen --no-remote -P regular'
  alias zen-platforms='zen --no-remote -P platforms'

  Or as separate launcher scripts in ~/.local/bin/ using the same naming convention as your other doom-* scripts:

  ~/.local/bin/doom-browser
  zen --no-remote -P regular

  ~/.local/bin/doom-browser-platforms
  zen --no-remote -P platforms

# Firewall ufw
sudo ufw default deny incoming
  sudo ufw default allow outgoing
  This is the correct baseline for a desktop. All unsolicited inbound connections are blocked. Outgoing is unrestricted, which is
  standard for desktop use.

sudo systemctl enable ufw
  Correct. The firewall comes back up automatically on reboot.

The rule uses from 172.16.0.0/12 which covers the entire Docker private network range (172.16–172.31). The dynamic bridge IP
  detection is well done — instead of hardcoding 172.17.0.1, it actually queries Docker to find the real gateway. The fallback is
  sensible.

 This is the most important thing in the whole script and it's handled correctly. Docker has a well-known security flaw: it directly
  manipulates iptables and bypasses UFW entirely, meaning container-exposed ports are reachable from the internet even though UFW
  should block them. ufw-docker install patches this. It's also correctly placed after ufw --force enable.

  The conditional install in aur.sh (only if Docker is present) is also correct.

Close mail server port

Logging added
  
# \[Z\]earch extension
Mode State Machine

This is the backbone of the entire extension. Everything routes through it.

NORMAL
  ├── z             → HINT_CLICK
  ├── Shift+Z       → HINT_NEW_TAB
  ├── Alt+Z         → HINT_PREVIEW
  ├── Ctrl+Shift+Z  → HINT_MULTI_NEW_TAB
  ├── Alt+Shift+Z   → HINT_INCOGNITO
  ├── y             → NORMAL_Y (prefix state, not a full mode)
  ├── m             → MARK_CREATE
  ├── `             → MARK_JUMP
  └── Alt+h/j/k/l  → scroll (stateless, stays in NORMAL)

NORMAL_Y  (y was pressed, waiting for second key)
  ├── z             → HINT_YANK
  └── anything else → NORMAL  (discard, pass key through)

HINT_*  (all hint modes share the same overlay, differ only in action)
  ├── letter        → filter visible hints
  ├── valid match   → execute action → NORMAL
  └── Escape        → dismiss overlay → NORMAL

 HINT_MULTI_NEW_TAB / HINT_INCOGNITO
   ├── letter        → append to input, filter visible hints by current input
   ├── exact match   → open tab/window immediately
   │                   remove that label from overlay
   │                   clear input buffer
   │                   remaining labels stay — no re-labelling
   └── Escape        → dismiss overlay → NORMAL

MARK_CREATE
  ├── a–z           → save local mark (url + scroll pos) → NORMAL
  ├── A–Z / 0–9    → save global mark → NORMAL
  └── Escape        → NORMAL

MARK_JUMP
  ├── a–z           → restore local mark (scroll) → NORMAL
  ├── A–Z / 0–9    → navigate to global mark url + scroll → NORMAL
  └── Escape        → NORMAL

NORMAL_Y is not a true mode — it's just a one-frame prefix flag inside NORMAL. Same pattern could apply to any future two-key
sequences.

```
Project Structure

  zen-vim/
  ├── manifest.json
  │
  ├── background/
  │   └── background.js        # anything requiring elevated context:
  │                            #   - open incognito tabs
  │                            #   - navigate tabs (global mark jumps)
  │                            #   - store/retrieve global marks
  │
  ├── content/
  │   ├── index.js             # entry point — wires all modules, injects CSS,
  │   │                        #   creates shadow container
  │   │
  │   ├── state.js             # the FSM — single source of truth for current mode,
  │   │                        #   exports getMode(), transition(event)
  │   │
  │   ├── keyboard.js          # keydown listener (capture phase), decides
  │   │                        #   whether to consume or pass through, routes
  │   │                        #   to state.js
  │   │
  │   ├── scroll.js            # alt+hjkl, smooth scrollBy, respects
  │   │                        #   active scrollable container
  │   │
  │   ├── hints/
  │   │   ├── index.js         # hint mode orchestrator, coordinates the rest
  │   │   ├── finder.js        # DOM walker — finds all hintable elements,
  │   │   │                    #   filters off-screen, hidden, zero-size
  │   │   ├── labels.js        # generates shortest unique char combos
  │   │   │                    #   from a charset (e.g. "asdfjkl;")
  │   │   └── overlay.js       # shadow DOM container, positions label nodes,
  │   │                        #   handles keystroke filtering, multi-select state
  │   │
  │   └── marks/
  │       ├── index.js         # orchestrates create/jump, dispatches to
  │       │                    #   local or global based on char case
  │       ├── local.js         # storage.local keyed by hostname+path+char
  │       └── global.js        # messages background to store/retrieve,
  │                            #   handles cross-page navigation + scroll timing
  │
  ├── shared/
  │   └── messages.js          # message type constants shared by
  │                            #   content ↔ background
  │
  └── icons/
      └── icon-48.png

  ---
  manifest.json

  {
    "manifest_version": 3,
    "name": "zen-vim",
    "version": "0.1.0",
    "description": "Keyboard-driven navigation for Zen Browser",

    "browser_specific_settings": {
      "gecko": {
        "id": "zen-vim@yourdomain.com",
        "strict_min_version": "109.0"
      }
    },

    "permissions": [
      "activeTab",
      "storage",
      "tabs",
      "clipboardWrite"
    ],

    "host_permissions": ["<all_urls>"],

    "background": {
      "service_worker": "background/background.js"
    },

    "content_scripts": [
      {
        "matches": ["<all_urls>"],
        "js": ["content/index.js"],
        "run_at": "document_idle",
        "all_frames": false
      }
    ]
  }

  all_frames: false keeps it simple for now — iframe support can be added later without changing the architecture.
```
  
```
Key Things to Know Before Writing Code

  1. Key event interception

  Register in capture phase so you get the event before the page does:

  window.addEventListener('keydown', handler, true)  // true = capture

  Inside the handler, when the extension consumes the key:
  event.preventDefault()
  event.stopPropagation()

  When NOT to intercept — check before doing anything:
  function isTypingContext(el) {
    const tag = el.tagName
    return tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT'
        || el.isContentEditable
  }

  Exception: Escape should always work regardless of focus, so it can always dismiss hint mode.

  2. Shadow DOM for the hint overlay

  This is non-negotiable — without it, the page's CSS will break your hint labels:

  const host = document.createElement('div')
  host.id = 'zen-vim-root'
  // host has no visual presence
  document.documentElement.appendChild(host)

  const shadow = host.attachShadow({ mode: 'closed' })
  // all hint labels go inside shadow, completely isolated from page styles

  The hint container inside shadow should be:
  #overlay {
    position: fixed;
    inset: 0;
    pointer-events: none;   /* don't block page clicks when not in hint mode */
    z-index: 2147483647;    /* max z-index */
  }

  3. What counts as hintable

  finder.js needs to be thoughtful here — too narrow misses elements, too broad creates hundreds of useless hints:

  const HINTABLE_SELECTORS = [
    'a[href]',
    'button:not([disabled])',
    'input:not([disabled]):not([type="hidden"])',
    'select:not([disabled])',
    'textarea:not([disabled])',
    '[role="button"]',
    '[role="link"]',
    '[role="menuitem"]',
    '[role="tab"]',
    '[onclick]',
    '[tabindex]:not([tabindex="-1"])',
  ].join(',')

  After finding them, filter out elements that are not actually visible:
  function isVisible(el) {
    const rect = el.getBoundingClientRect()
    if (rect.width === 0 || rect.height === 0) return false
    if (rect.bottom < 0 || rect.top > window.innerHeight) return false
    const style = window.getComputedStyle(el)
    return style.visibility !== 'hidden' && style.display !== 'none'
           && style.opacity !== '0'
  }

  4. Label generation

  Generate the shortest combinations possible from a charset:

  function generateLabels(count, charset = 'asdfjkl;') {
    const labels = []
    const n = charset.length
    // single chars first, then two-char combos, etc.
    for (const ch of charset) labels.push(ch)
    if (labels.length >= count) return labels.slice(0, count)
    for (const a of charset)
      for (const b of charset) labels.push(a + b)
    if (labels.length >= count) return labels.slice(0, count)
    // extend to 3 if needed (rare, means 64+ links on page)
    // ...
    return labels.slice(0, count)
  }

  5. Alt+z preview — simulating Alt+click

  Zen handles the preview window natively on Alt+click. The extension just needs to fire a real mouse event with altKey: true:

  function previewElement(el) {
    el.dispatchEvent(new MouseEvent('click', {
      altKey: true,
      bubbles: true,
      cancelable: true,
      view: window
    }))
  }

  If Zen intercepts Alt+click at the browser level before the DOM, this won't work — in that case the fallback is
  browser.tabs.create({ url: href }) with some Zen-specific API if one exists. Test this first.

  6. Global marks and cross-page scroll timing

  When jumping to a global mark on a different page, you navigate then need to scroll — but you can't scroll before the page loads.
  The pattern:

  - Content script messages background: JUMP_GLOBAL_MARK with { url, scrollX, scrollY }
  - Background calls tabs.update({ url }) and stores the pending scroll in a map keyed by tab ID
  - Content script on each page load messages background: PAGE_READY
  - Background checks if there's a pending scroll for that tab, sends EXECUTE_SCROLL back
  - Content script scrolls to position

  7. Mode status indicator

  Worth adding from day one — a small fixed badge showing current mode, again inside the shadow DOM so it doesn't conflict with page
  layout:

  [ HINT ]  [ MARK CREATE ]  [ MARK JUMP ]

  Appears bottom-right, only visible when not in NORMAL mode. Tiny but makes the extension feel grounded and debuggable while
  developing.

  ---
  Background ↔ Content Message Types (shared/messages.js)

  export const MSG = {
    // content → background
    OPEN_INCOGNITO:    'OPEN_INCOGNITO',     // { url }
    SET_GLOBAL_MARK:   'SET_GLOBAL_MARK',    // { char, url, scrollX, scrollY }
    GET_GLOBAL_MARK:   'GET_GLOBAL_MARK',    // { char }
    JUMP_GLOBAL_MARK:  'JUMP_GLOBAL_MARK',   // { char } (background does full nav+scroll)
    PAGE_READY:        'PAGE_READY',

    // background → content
    EXECUTE_SCROLL:    'EXECUTE_SCROLL',     // { scrollX, scrollY }
    MARK_DATA:         'MARK_DATA',          // { char, url, scrollX, scrollY } (response)
  }

  ---
  Build Order Recommendation

  Build in this order — each step is independently testable:

  1. keyboard.js + state.js — get the FSM working, log mode transitions to console, verify keys are intercepted correctly and typing
  in inputs still works
  2. scroll.js — straightforward, adds Alt+hjkl, verify it doesn't fire in inputs
  3. hints/labels.js — pure function, easiest to unit test in isolation
  4. hints/finder.js — test on different page types, tune the selector list
  5. hints/overlay.js — the visual layer, get labels appearing in the right positions
  6. hints/index.js — wire click action first (z), then add the other modes one by one
  7. marks/local.js — storage read/write, test create then jump on the same page
  8. background.js — incognito tabs, then global mark navigation
  9. marks/global.js — cross-page jumps, the scroll timing logic


  What this means for overlay.js

  The overlay needs to track two separate things:

  hints[]          — full list of { element, label, node } — built once on mode enter
  inputBuffer      — string being typed right now — resets to '' after each match

  On each keystroke:
  1. Append key to inputBuffer
  2. Check if inputBuffer exactly matches any remaining hint label → if yes, fire and clear
  3. If not an exact match yet, dim/hide hints that no longer start with inputBuffer (so user gets visual feedback they're on track)
  4. If inputBuffer matches nothing at all (impossible prefix) → clear buffer, restore all remaining labels to full visibility

  On a successful match:
  function onMatch(hint) {
    openTab(hint.element)          // or openPrivate()
    hint.node.remove()             // remove that label from the shadow DOM
    hints.splice(hints.indexOf(hint), 1)  // remove from tracking list
    inputBuffer = ''               // reset — all remaining labels fully visible again
  }

  The hint.node.remove() is the key detail — you surgically remove just that one label node from the shadow DOM without touching
  anything else. The rest stay exactly where they are.

  ---
  One edge case worth handling

  If the user types a character that is a valid prefix for some hints but the buffer could never complete to a full match (e.g.
  charset is asdfjkl; and they type q), reset the buffer silently and restore full visibility. Otherwise the user is stuck with a
  blank screen and no way out except Escape.

  function hasAnyMatch(buffer, hints) {
    return hints.some(h => h.label.startsWith(buffer))
  }

  // in keydown handler for multi modes:
  inputBuffer += key
  if (!hasAnyMatch(inputBuffer, remainingHints)) {
    inputBuffer = ''
    restoreAllVisible()
  }
```

# New Subject
