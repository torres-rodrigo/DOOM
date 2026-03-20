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

# Git Fix if asked to change to a new branch or lots of breaking changes
1. Clone branch
2. git reset --hard origin/\<TARGET_BRANCH\>
3. git cherry-pick \<MY_CHANGES_COMMIT_HASH\>
4. git push --force-with-lease

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

bookmarks
y youtube
gh github
cf custom forge

p paramount


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

# Git diff with pager
Maintain regular git diff and use an alias for delta diff
```
[alias]
  delta = -c core.pager=delta diff
  deltas = -c core.pager=delta -c delta.side-by-side=true diff

[merge] # check if needed I need to try it out with an actual merge conflict
	conflictStyle = zdiff3

[delta]
	navigate = true
	dark = true
	line-numbers = true
	file-style = "cyan bold"
	file-decoration-style = "white ul"
	hunk-header-style = "cyan bold"
	hunk-header-decoration-style = "white box"
	line-numbers-left-style = white
	line-numbers-right-style = white
	wrap-max-lines = 0
	keep-plus-minus-markers = true
  hyperlinks = true
  #hyperlinks-file-link = search for zed and nvim format
  #hyperlinks-file-link = "code://file/{path}:{line}"
```
good note to add to gl aka git log, -p: shows diff changes added in commit
Make function for the advance git command where it prompts you to enter the line numbers, maybe have a toggable preview as well
```
[core]
  editor = nvim
```

# Neovim features
Leader o same as o but then go back to normal mode
leader shift o same as O but then go back to normal mode
Add auto update file on changes from the outside
toggle background
:highlight Normal ctermbg=none guibg=none
```
On Linux, custom URI handlers use .desktop files registered via xdg-mime.

  1. Create the handler script at ~/.local/bin/nvim-handler.sh:
  #!/bin/bash
  URI="$1"
  QUERY="${URI#nvim://open?}"

  # Parse path and line from query string
  read -r FILE_PATH LINE_NUM < <(python3 -c "
  import urllib.parse, sys
  params = dict(urllib.parse.parse_qsl(sys.argv[1]))
  print(params.get('path', ''), params.get('line', ''))
  " "$QUERY")

  ARGS=("$FILE_PATH")
  [ -n "$LINE_NUM" ] && ARGS=("+$LINE_NUM" "$FILE_PATH")

  # Adjust to your terminal emulator (kitty, alacritty, foot, etc.)
  exec kitty nvim "${ARGS[@]}"

  chmod +x ~/.local/bin/nvim-handler.sh

  2. Create ~/.local/share/applications/nvim-handler.desktop:
  [Desktop Entry]
  Type=Application
  Name=Neovim URI Handler
  Exec=/home/rodrigo/.local/bin/nvim-handler.sh %u
  MimeType=x-scheme-handler/nvim;
  NoDisplay=true
  Terminal=false

  3. Register and update the database:
  xdg-mime default nvim-handler.desktop x-scheme-handler/nvim
  update-desktop-database ~/.local/share/applications/

  4. Test it:
  xdg-open "nvim://open?path=/etc/hosts&line=1"
```

# Lazygit config
lazygit -h
-c --config             Print the default config
-cd --print-config-dir   Print the config directory
```
nerdFontsVersion = "3"
```

# Implement an encryption system for github
  Approach 1: File-level encryption (git-crypt)

  How it works:
  - Git has clean and smudge filter hooks — clean runs before staging, smudge runs after checkout
  - git-crypt hooks into these filters to transparently encrypt/decrypt specific files
  - You mark which files to encrypt via .gitattributes
  - GitHub stores the encrypted blobs; locally they appear as plaintext

  Workflow:
  local plaintext → [clean filter encrypts] → staged ciphertext → push to GitHub
  GitHub ciphertext → pull → [smudge filter decrypts] → local plaintext

  Pros: File names and commit history still visible on GitHub, partial browsing possible
  Cons: Metadata is exposed (file names, tree structure, commit messages)

  ---
  Approach 2: Full repository encryption (git-remote-gcrypt)

  How it works:
  - Encrypts the entire pack before it reaches the remote
  - GitHub literally stores encrypted binary blobs — no file names, no history, nothing readable
  - Uses GPG keys for access control

  Pros: Nothing is readable on GitHub
  Cons: Completely opaque — no browsing, no PRs, no diffs on GitHub. Also slower.

  ---
  Key distribution (the hard problem)

  Both approaches reduce to: how do authorized people get the key?

  - Symmetric key: one shared secret, simpler but you can't revoke individual access
  - GPG keys: each collaborator has their own keypair, the repo key is encrypted to each person's public key — you can revoke
  individual access by removing their key and rotating

  ┌──────────────────┬──────────────────┬───────────────────┐
  │                  │    git-crypt     │ git-remote-gcrypt │
  ├──────────────────┼──────────────────┼───────────────────┤
  │ Granularity      │ Per-file         │ Whole repo        │
  ├──────────────────┼──────────────────┼───────────────────┤
  │ GitHub browsable │ Partially        │ No                │
  ├──────────────────┼──────────────────┼───────────────────┤
  │ Access control   │ GPG or symmetric │ GPG               │
  ├──────────────────┼──────────────────┼───────────────────┤
  │ Complexity       │ Low              │ Medium            │
  └──────────────────┴──────────────────┴───────────────────┘

  I would have a "mirrored" set up.
  A working copy in a folder inside the repo that gets ignored.
  And the encrypted copy that gets sent to github.
  I would also have a "mapping file" like you suggested, and I would create a script that takes the contents of the files i
  modified in the working copy and applies them to the respective "encrypted name one".
  I would then use the git-crypt approach.
  I would also have a commit file, where commit messages get stored there and for the actual git commit I take the last message
  from there and encrypt it. that will be handled by the script.
  Do not respect project structure in encrypted copy, everything goes to the same directory

# DOOM
                    =================     ===============     ===============   ========  ========
                    \\ . . . . . . .\\   //. . . . . . .\\   //. . . . . . .\\  \\. . .\\// . . //
                    ||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\/ . . .||
                    || . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||
                    ||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||
                    || . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\ . . . . ||
                    ||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\_ . .|. .||
                    || . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\ `-_/| . ||
                    ||_-' ||  .|/    || ||    \|.  || `-_|| ||_-' ||  .|/    || ||   | \  / |-_.||
                    ||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \  / |  `||
                    ||    `'         || ||         `'    || ||    `'         || ||   | \  / |   ||
                    ||            .===' `===.         .==='.`===.         .===' /==. |  \/  |   ||
                    ||         .=='   \_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \/  |   ||
                    ||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \/  |   ||
                    ||   .=='    _-'          `-__\._-'         `-_./__-'         `' |. /|  |   ||
                    ||.=='    _-'                                                     `' |  /==.||
                    =='    _-'                                                            \/   `==
                    \   _-'                                                                `-_   /
                    `''                                                                      ``'

# ArchInstall config
https://github.com/archlinux/archinstall/blob/master/examples/config-sample.json

# Custom Cursor Theme Guide

A complete reference for building a mixed cursor theme from multiple source themes,
mapping every cursor state to a file, and applying it system-wide on Wayland.

---

## Wayland Compatibility

**Yes — XCursor works fully on Wayland.** There is no separate Wayland cursor
format. Wayland compositors (including mango WM) load cursor themes through
`libxcursor`, the same library used on X11, driven by the same environment
variables (`XCURSOR_THEME`, `XCURSOR_SIZE`). The XCursor binary format is the
universal standard on Linux regardless of display server.

Hyprland introduced an optional `hyprcursor` format (SVG-based, resolution-
independent), but it falls back to XCursor. For mango WM, plain XCursor is the
correct format.

---

## XDG-Compliant Install Path

`~/.icons/` is a **legacy** path from the old X11 icon spec. The XDG Base
Directory standard places icon themes (including cursor themes) at:

```
$XDG_DATA_HOME/icons/   →   ~/.local/share/icons/
```

Both paths are searched by `libxcursor`, but `~/.local/share/icons/` is the
correct modern location. All examples in this guide use it.

**One caveat:** some GNOME apps on Wayland only find themes in `~/.local/share/icons`
if `XCURSOR_PATH` explicitly includes it (see Section 5).

---

## 1. How XCursor Themes Work

Every cursor theme is a directory with this structure:

```
~/.local/share/icons/MyTheme/
├── index.theme        ← metadata: name, optional fallback chain
├── cursor.theme       ← optional: shorthand pointing to index.theme name
└── cursors/           ← one binary XCursor file per cursor name
    ├── default
    ├── text
    ├── pointer
    ├── xterm          ← usually a symlink → text
    └── ...
```

**XCursor binary files** are not images. Each file can embed multiple sizes (24px,
32px, 48px, 64px, 96px) and multiple animation frames inside a single binary.
Applications pick the size closest to `XCURSOR_SIZE`.

**Symlinks are aliases.** Applications request cursors by many different names
(e.g. `hand2`, `pointer`, `pointing_hand` all mean "clickable"). Instead of
duplicating the binary, you create symlinks so all aliases resolve to one file.

**The fallback chain** (`Inherits=` in `index.theme`) lets you declare a parent
theme. Any cursor name not found in your theme is looked up in the parent, then
in the default theme. This means you only need to provide the cursors you actually
want to customise.

---

## 2. Your Available Source Themes

Stored in `~/Downloads/Cursors/Linux/`:

| Theme | Cursors dir | Count | Style |
|---|---|---|---|
| `Bibata-Modern-Ice` | `cursors/` | 145 | White, rounded, high-contrast |
| `WinSur-white-cursors` | `winsur-cursors/` | ~100 | Windows 11, white |
| `macOS` | `macOS/cursors/` | 145 | macOS Big Sur style |
| `macOS-White` | `macOS-White/cursors/` | 145 | macOS, all-white variant |
| `Posy_Cursor` | `cursors/` | 122 | Minimal, clean Windows-style |
| `Posy_Cursor_Black` | `cursors/` | 122 | Same, dark variant |
| `Posy_Cursor_Mono` | `cursors/` | 122 | Monochrome variant |

---

## 3. Cursor States → File Names

This is the definitive map. The **primary name** is the canonical file in your
`cursors/` directory. Every entry in the **aliases** column becomes a symlink
pointing at that primary file.

### Core states

| Visual state | Primary file | Aliases (symlinks → primary) |
|---|---|---|
| Normal arrow | `default` | `left_ptr`, `arrow`, `top_left_arrow`, `X_cursor`, `x-cursor` |
| Text / I-beam | `text` | `xterm`, `ibeam` |
| Pointer / clickable | `pointer` | `hand2`, `pointing_hand`, `hand1` |
| Busy spinner | `wait` | `watch` |
| Background busy (arrow + spinner) | `progress` | `left_ptr_watch`, `half-busy` |
| Precision / crosshair | `crosshair` | `cross`, `tcross`, `diamond_cross` |

### Resize states

| Visual state | Primary file | Aliases (symlinks → primary) |
|---|---|---|
| Resize horizontal ↔ | `ew-resize` | `col-resize`, `h_double_arrow`, `sb_h_double_arrow`, `size-hor`, `size_hor`, `size-hor` |
| Resize vertical ↕ | `ns-resize` | `row-resize`, `v_double_arrow`, `sb_v_double_arrow`, `size-ver`, `size_ver` |
| Resize diagonal ↘ | `nwse-resize` | `nw-resize`, `se-resize`, `bd_double_arrow`, `size_fdiag`, `size_NwSe` |
| Resize diagonal ↙ | `nesw-resize` | `ne-resize`, `sw-resize`, `fd_double_arrow`, `size_bdiag`, `size_NeSw` |
| Resize all directions | `size_all` | `move`, `fleur`, `all-scroll` |
| Resize top edge | `n-resize` | `top_side` |
| Resize bottom edge | `s-resize` | `bottom_side` |
| Resize left edge | `w-resize` | `left_side` |
| Resize right edge | `e-resize` | `right_side` |

### Interaction states

| Visual state | Primary file | Aliases (symlinks → primary) |
|---|---|---|
| Open hand / pan | `openhand` | `grab` |
| Closed hand / dragging | `closedhand` | `grabbing` |
| Not allowed | `not-allowed` | `forbidden`, `crossed_circle`, `no-drop`, `circle` |
| Help / question | `help` | `question_arrow`, `whats_this`, `left_ptr_help` |
| Context menu | `context-menu` | *(none)* |
| Copy (DnD) | `copy` | `dnd-copy` |
| Move (DnD) | `dnd-move` | *(none)* |
| Link / alias (DnD) | `alias` | `link`, `dnd-link` |
| No drop (DnD) | `dnd-none` | `dnd-no-drop`, `dnd_no_drop` |

### Specialty states

| Visual state | Primary file | Aliases (symlinks → primary) |
|---|---|---|
| Split horizontal | `split_h` | *(none)* |
| Split vertical | `split_v` | *(none)* |
| Zoom in | `zoom-in` | *(none)* |
| Zoom out | `zoom-out` | *(none)* |
| Draw / pencil | `pencil` | `pen` |
| Cell / spreadsheet | `cell` | `plus` |
| Color picker | `color-picker` | *(none)* |
| Up arrow | `up-arrow` | *(none)* |
| Vertical text | `vertical-text` | *(none)* |
| Center pointer | `center_ptr` | *(none)* |

### Hex-named files (legacy X11 hash IDs)

These are old X11 cursor shape IDs. Applications that predate named cursors
request them by hash. Create symlinks from the hash to your primary file.
The most important ones:

| Hash | Equivalent visual state |
|---|---|
| `00000000000000020006000e7e9ffc3f` | `wait` |
| `00008160000006810000408080010102` | `openhand` |
| `03b6e0fcb3499374a867c041f52298f0` | `context-menu` |
| `08e8e1c95fe2fc01f976f1e063a24ccd` | `help` |
| `1081e37283d90000800003c07f3ef6bf` | `ns-resize` |
| `2870a09082c103050810ffdffffe0204` | `move` |
| `3085a0e285430894940527032f8b26df` | `progress` |
| `3ecb610c1bf2410f44200f48c40d3599` | `not-allowed` |
| `4498f0e0c1937ffe01fd06f973665830` | `alias` |
| `5c6cd98b3f3ebcb1f9c7f1c204630408` | `copy` |
| `6407b0e94181790501fd1e167b474872` | `nwse-resize` |
| `640fb0e74195791501fd1ed57b41487f` | `nesw-resize` |
| `9081237383d90e509aa00f00170e968f` | `ns-resize` |
| `9d800788f1b08800ae810202380a0822` | `pointer` |
| `a2a266d0498c3104214a47bd64ab0fc8` | `alias` |
| `d9ce0ab605698f320427677b458ad60b` | `move` |
| `e29285e634086352946a0e7090d73106` | `move` |
| `fcf1c3c7cd4491d801f1e1c78f100000` | `ns-resize` |
| `fcf21c00b30f7e3f83fe0dfd12e71cff` | `nwse-resize` |

The safest approach: copy the hash-named files directly from whichever source
theme you are using for that visual state. Do not manually manage these symlinks
— let the source theme's existing hashes carry over.

---

## 4. Building the Custom Theme

### Step 1 — Create the directory

```bash
THEME_NAME="DoomCursor"
mkdir -p ~/.local/share/icons/$THEME_NAME/cursors
```

### Step 2 — Define your choices per state

Decide which source theme you want for each visual group. Example:

| Group | Source theme |
|---|---|
| Default arrow, progress, crosshair | Bibata-Modern-Ice |
| Pointer, open/closed hand | macOS |
| Resize cursors | Bibata-Modern-Ice |
| Wait / busy | Posy_Cursor |
| Not-allowed, help, DnD | Bibata-Modern-Ice |

### Step 3 — Copy the primary files

For each primary name, copy the file from your chosen source:

```bash
SRC_BIBATA=~/Downloads/Cursors/Linux/Bibata-Modern-Ice/cursors
SRC_MACOS=~/Downloads/Cursors/Linux/macOS/macOS/cursors
SRC_POSY=~/Downloads/Cursors/Linux/posy-s-cursor-sets/Posy_Cursor/cursors
DEST=~/.local/share/icons/DoomCursor/cursors

# Arrow group — from Bibata
cp $SRC_BIBATA/default        $DEST/default
cp $SRC_BIBATA/progress       $DEST/progress
cp $SRC_BIBATA/crosshair      $DEST/crosshair

# Text
cp $SRC_BIBATA/text           $DEST/text

# Pointer — from macOS
cp $SRC_MACOS/pointer         $DEST/pointer

# Open / closed hand — from macOS
cp $SRC_MACOS/openhand        $DEST/openhand
cp $SRC_MACOS/closedhand      $DEST/closedhand

# Wait — from Posy
cp $SRC_POSY/wait             $DEST/wait

# Resize
cp $SRC_BIBATA/ew-resize      $DEST/ew-resize
cp $SRC_BIBATA/ns-resize      $DEST/ns-resize
cp $SRC_BIBATA/nwse-resize    $DEST/nwse-resize
cp $SRC_BIBATA/nesw-resize    $DEST/nesw-resize
cp $SRC_BIBATA/size_all       $DEST/size_all

# Not-allowed / help / DnD
cp $SRC_BIBATA/not-allowed    $DEST/not-allowed
cp $SRC_BIBATA/help           $DEST/help
cp $SRC_BIBATA/copy           $DEST/copy
cp $SRC_BIBATA/alias          $DEST/alias
cp $SRC_BIBATA/dnd-move       $DEST/dnd-move
cp $SRC_BIBATA/dnd-none       $DEST/dnd-none

# Specialty
cp $SRC_BIBATA/zoom-in        $DEST/zoom-in
cp $SRC_BIBATA/zoom-out       $DEST/zoom-out
cp $SRC_BIBATA/context-menu   $DEST/context-menu
cp $SRC_BIBATA/split_h        $DEST/split_h
cp $SRC_BIBATA/split_v        $DEST/split_v
cp $SRC_BIBATA/cell           $DEST/cell
cp $SRC_BIBATA/color-picker   $DEST/color-picker
cp $SRC_BIBATA/pencil         $DEST/pencil
cp $SRC_BIBATA/vertical-text  $DEST/vertical-text
cp $SRC_BIBATA/up-arrow       $DEST/up-arrow
```

Also copy all the hex-named files from your primary source to preserve legacy
X11 compatibility:

```bash
# Copy everything from Bibata first (gets all hashes), then overwrite selectively
cp $SRC_BIBATA/* $DEST/
```

### Step 4 — Create alias symlinks

For every primary file, create symlinks for all its aliases:

```bash
cd $DEST

# default
ln -sf default left_ptr
ln -sf default arrow
ln -sf default top_left_arrow
ln -sf default X_cursor
ln -sf default x-cursor

# text
ln -sf text xterm
ln -sf text ibeam

# pointer
ln -sf pointer hand2
ln -sf pointer pointing_hand
ln -sf pointer hand1

# wait
ln -sf wait watch

# progress
ln -sf progress left_ptr_watch
ln -sf progress half-busy

# crosshair
ln -sf crosshair cross
ln -sf crosshair tcross
ln -sf crosshair diamond_cross

# ew-resize
ln -sf ew-resize col-resize
ln -sf ew-resize h_double_arrow
ln -sf ew-resize sb_h_double_arrow
ln -sf ew-resize size-hor
ln -sf ew-resize size_hor

# ns-resize
ln -sf ns-resize row-resize
ln -sf ns-resize v_double_arrow
ln -sf ns-resize sb_v_double_arrow
ln -sf ns-resize size-ver
ln -sf ns-resize size_ver

# nwse-resize
ln -sf nwse-resize nw-resize
ln -sf nwse-resize se-resize
ln -sf nwse-resize bd_double_arrow
ln -sf nwse-resize size_fdiag
ln -sf nwse-resize size_NwSe

# nesw-resize
ln -sf nesw-resize ne-resize
ln -sf nesw-resize sw-resize
ln -sf nesw-resize fd_double_arrow
ln -sf nesw-resize size_bdiag
ln -sf nesw-resize size_NeSw

# size_all (move/pan)
ln -sf size_all move
ln -sf size_all fleur
ln -sf size_all all-scroll

# not-allowed
ln -sf not-allowed forbidden
ln -sf not-allowed crossed_circle
ln -sf not-allowed no-drop
ln -sf not-allowed circle

# help
ln -sf help question_arrow
ln -sf help whats_this
ln -sf help left_ptr_help

# openhand
ln -sf openhand grab

# closedhand
ln -sf closedhand grabbing

# copy / link / dnd
ln -sf copy dnd-copy
ln -sf alias link
ln -sf alias dnd-link
ln -sf dnd-none dnd-no-drop
ln -sf dnd-none dnd_no_drop

# specialty
ln -sf pencil pen
ln -sf cell plus
```

### Step 5 — Create index.theme

```ini
[Icon Theme]
Name=DoomCursor
Comment=DOOM custom cursor — mixed theme
Inherits="Bibata-Modern-Ice"
```

The `Inherits` line is a safety net. Any cursor name your theme does not define
is looked up in Bibata first, then in the system default.

### Step 6 — Preview without applying system-wide

```bash
# Check the theme is readable
xcur2png ~/.local/share/icons/DoomCursor/cursors/default -d /tmp/cursor_preview

# Or launch any GTK app with the theme overridden
XCURSOR_THEME=DoomCursor XCURSOR_SIZE=24 gtk3-demo
```

---

## 5. Applying the Theme System-Wide

Three layers need to be updated:

**Layer 1 — Environment variables** (affects all Wayland-native apps)

Set in `~/.config/uwsm/env`:
```sh
export XCURSOR_THEME=DoomCursor
export XCURSOR_SIZE=24
# XCURSOR_PATH tells libxcursor where to search.
# ~/.local/share/icons is XDG-compliant but some GNOME apps on Wayland
# require it to be listed explicitly alongside the system path.
export XCURSOR_PATH="$HOME/.local/share/icons:/usr/share/icons"
```

**Layer 2 — GSetting** (affects GTK3/GTK4 apps and portals)

```bash
gsettings set org.gnome.desktop.interface cursor-theme 'DoomCursor'
gsettings set org.gnome.desktop.interface cursor-size 24
```

**Layer 3 — Compositor** (affects the desktop cursor itself, not app windows)

For mango WM, check its configuration for a cursor section similar to:
```
cursor_theme = DoomCursor
cursor_size  = 24
```
This is compositor-specific. Without this layer only application windows show
the custom cursor; the bare desktop/root cursor stays default.

---

## 6. Inspecting Source Theme Cursors

To see what a specific cursor file looks like before copying it:

```bash
# List all sizes embedded in a cursor binary
file ~/.icons/DoomCursor/cursors/default

# Convert to PNG to visually compare (requires xcur2png from AUR)
xcur2png ~/Downloads/Cursors/Linux/Bibata-Modern-Ice/cursors/default -d /tmp/preview
xcur2png ~/Downloads/Cursors/Linux/macOS/macOS/cursors/pointer -d /tmp/preview

# Or use the cursor inspector in any GTK app — hover a widget
```

---

## 7. Creating New Cursor Images from PNG (optional)

If you want to draw your own cursor for a specific state:

1. Create a PNG at 32×32 or 48×48 px with a transparent background
2. Create a `.cursor` config file:

```
# format: size hotspot_x hotspot_y image.png [delay_ms]
32 3 3 arrow.png
```

3. Generate the XCursor binary:

```bash
xcursorgen arrow.cursor arrow_out
cp arrow_out ~/.local/share/icons/DoomCursor/cursors/default
```

For animated cursors (e.g. the spinning wait cursor), add multiple lines to the
`.cursor` file, each with a `delay_ms` value at the end (typically 30–50ms per
frame). `xcursorgen` stacks them into one animated binary automatically.

---

## 8. The doom-cursor Script

The `doom-cursor` script (in `scripts/`) handles everything in one command:

```bash
doom-cursor DoomCursor 24       # apply theme at size 24
doom-cursor DoomCursor          # apply theme at default size (24)
doom-cursor --list              # show installed themes in ~/.local/share/icons
```

It updates gsettings, writes the env vars to `~/.config/uwsm/env`, and
notifies you. The compositor cursor requires a session restart to pick up the
change (or mango WM's reload command once its API is confirmed).

See `scripts/doom-cursor` for the implementation.

---

# d00m_v0 Gap Analysis

Comparison of d00m_v0 against DOOM, omarchy, dusky, and hybrid reference projects.
Items to address at a later time.

---

## Critical — Nothing exists for these

| Gap | What reference projects do | Mango WM alternative |
|---|---|---|
| App launcher | omarchy: Walker; dusky/hybrid: rofi-wayland | fuzzel or rofi-wayland |
| Screen locker | All use hyprlock | swaylock or gtklock |
| Idle daemon | All use hypridle | swayidle |
| Logout / power menu | dusky: wlogout; omarchy: fzf-based menu | wlogout or fzf/fuzzel menu |
| Screenshot script | DOOM: `doom-screenshot` (grim + slurp + satty) | Packages present, just no script wiring them |
| Screen recorder script | DOOM: `doom-screenrecord` (gpu-screen-recorder) | Packages present, no script |
| Clipboard UI | DOOM: `doom-clipboard` (cliphist + fzf + wl-copy) | Cliphist service exists but no way to browse history |

---

## High — Significant missing features

| Gap | Notes |
|---|---|
| Migration / update system | omarchy and hybrid both have `*-update` (snapshot + git pull + pacman + AUR + firmware + migrations) and `*-migrate` (timestamped scripts). d00m_v0 has no way to evolve after initial install |
| Btrfs snapshots | btrfs-progs installed but no snapper, no snapshot-before-update, no rollback |
| Nightlight | hyprsunset is Hyprland-specific; **wlsunset** is the mango-compatible alternative |
| Wallpaper management | `doom-theme --wallpaper` runs matugen but doesn't set the wallpaper via swaybg. No rotation, no picker, no "current wallpaper" tracking |
| AMD/Intel GPU detection | Installer only handles NVIDIA. AMD or Intel machines get no driver setup |
| Brightness control | `brightnessctl` not in packages.list. swayosd can show OSD but nothing triggers it |

---

## Medium — Polish and completeness

| Gap | Notes |
|---|---|
| fontconfig/fonts.conf | No font rendering config (hinting, antialiasing, default monospace). dusky and omarchy both deploy one |
| GTK settings.ini | Matugen writes CSS colors but no `settings.ini` — GTK apps don't know icon theme, cursor theme, or font |
| xdg-terminals.list | No preferred terminal set for `xdg-terminal-exec` |
| MIME type defaults | No `xdg-mime default` for images, video, PDF, text files |
| UWSM default apps | omarchy deploys `~/.config/uwsm/default` for default-terminal, default-browser |
| PAM fingerprint / FIDO2 scripts | Packages installed (libfido2, pam-u2f) but no setup scripts. DOOM parent has `doom-setup-fido2` and `doom-setup-fingerprint` |
| Audio output switching | No script to cycle PipeWire sinks (omarchy has one) |
| sysctl tweaks | No inotify watchers increase, no vm.swappiness, no network buffer tuning |
| gnome-keyring PAM init | Package installed but no PAM config — first app using libsecret prompts to create a keyring |
| Disable mkinitcpio during install | omarchy moves pacman hooks aside during install to avoid rebuilding initramfs per kernel package. Easy speed win |
| Hibernation setup | No hibernate-to-disk support (high value for laptops) |
| LUKS password change script | omarchy has one, d00m_v0 doesn't despite using LUKS |

---

## Low — Nice-to-haves

| Gap | Notes |
|---|---|
| Fast systemd shutdown config | Default 90s timeout; omarchy cuts it down |
| Faillock / sudo tries config | Defaults can lock you out annoyingly |
| GPG keyserver config | gopass installed but no keyserver setup |
| Reflector (mirror optimization) | Using whatever archinstall left |
| Journal size limits | Journals can grow unbounded |
| Lid close / power button (logind.conf) | TLP handles some, but explicit logind config is cleaner |
| Font cache rebuild in installer | `fc-cache -fv` after font packages install |
| kernel-modules-hook | Preserves modules after kernel upgrade (matters for NVIDIA dkms) |
| Firmware updates (fwupd) | Not in packages.list |
| Orphan package cleanup | Only cache clean, no orphan removal |
| File manager (yazi) | Commented out in packages, no config |
| Version tracking (doom-version) | No version file in the project |
| Boot messages toggle | No script to toggle `quiet` in kernel cmdline |
| Printing (CUPS) | No cups, no printing support at all |
| waypaper / swww | No wallpaper picker or transition animations |

---

## Does not apply to mango WM

Hyprland-specific features in reference projects that cannot be ported:
- hyprlock, hypridle, hyprsunset, hyprpicker, hyprpaper
- Hyprland animation presets and shader system (`hyprctl`)
- Walker's Hyprland IPC integration
- Window dispatch scripts using `hyprctl`
- Waybar (mango WM may have its own built-in bar)

---

## Architecture notes

- The biggest architectural gap is the **migration/update system** — without it, every config change after install requires manual intervention or a full reinstall.
- The biggest user-facing gaps are the **four critical missing pieces**: app launcher, screen locker, idle daemon, and power menu. Without those, the desktop is functional but not usable day-to-day.
- The migration pattern is simple: a `migrations/` directory with numbered shell scripts, a state directory tracking what has run, and a `doom-migrate` script. Combined with `doom-update` (snapshot + git pull + pacman + paru + doom-migrate), this brings d00m_v0 to parity with omarchy and hybrid.

 Core

  ┌───────────┬────────────────────────────────────────────────────────────────┐
  │ File name │                        When it appears                         │
  ├───────────┼────────────────────────────────────────────────────────────────┤
  │ default   │ Normal arrow — hovering over the desktop, buttons, most UI     │
  ├───────────┼────────────────────────────────────────────────────────────────┤
  │ text      │ Over editable text (input fields, text editors)                │
  ├───────────┼────────────────────────────────────────────────────────────────┤
  │ pointer   │ Over clickable elements (links, buttons with hand cursor)      │
  ├───────────┼────────────────────────────────────────────────────────────────┤
  │ wait      │ System is busy, cannot interact (spinning/hourglass)           │
  ├───────────┼────────────────────────────────────────────────────────────────┤
  │ progress  │ System is busy but you can still interact (arrow + spinner)    │
  ├───────────┼────────────────────────────────────────────────────────────────┤
  │ crosshair │ Precision selection (drawing apps, color pickers, sniper mode) │
  └───────────┴────────────────────────────────────────────────────────────────┘

  Resize

  ┌─────────────┬───────────────────────────────────────────────────────────────────────┐
  │  File name  │                            When it appears                            │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ n-resize    │ Dragging a top edge down/up                                           │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ s-resize    │ Dragging a bottom edge down/up                                        │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ e-resize    │ Dragging a right edge left/right                                      │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ w-resize    │ Dragging a left edge left/right                                       │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ ns-resize   │ Vertical resize handle (top/bottom borders)                           │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ ew-resize   │ Horizontal resize handle (left/right borders)                         │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ nwse-resize │ Diagonal resize — top-left or bottom-right corner                     │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ nesw-resize │ Diagonal resize — top-right or bottom-left corner                     │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ col-resize  │ Dragging a column divider left/right (tables, split panes)            │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ row-resize  │ Dragging a row divider up/down (tables, split panes)                  │
  ├─────────────┼───────────────────────────────────────────────────────────────────────┤
  │ size_all    │ Move/resize in any direction (over a window title bar or drag handle) │
  └─────────────┴───────────────────────────────────────────────────────────────────────┘

  Interaction

  ┌──────────────┬──────────────────────────────────────────────────────────────────────┐
  │  File name   │                           When it appears                            │
  ├──────────────┼──────────────────────────────────────────────────────────────────────┤
  │ openhand     │ "You can grab this" — pannable canvas, draggable map                 │
  ├──────────────┼──────────────────────────────────────────────────────────────────────┤
  │ closedhand   │ "You are grabbing" — actively panning/dragging                       │
  ├──────────────┼──────────────────────────────────────────────────────────────────────┤
  │ not-allowed  │ Action is forbidden (dropping on an invalid target, disabled button) │
  ├──────────────┼──────────────────────────────────────────────────────────────────────┤
  │ help         │ Help mode — hovering with "what's this?" active                      │
  ├──────────────┼──────────────────────────────────────────────────────────────────────┤
  │ context-menu │ Right-click menu is available                                        │
  └──────────────┴──────────────────────────────────────────────────────────────────────┘

  Drag and drop

  ┌───────────┬───────────────────────────────────────────────────┐
  │ File name │                  When it appears                  │
  ├───────────┼───────────────────────────────────────────────────┤
  │ copy      │ Dragging with copy action (Ctrl+drag)             │
  ├───────────┼───────────────────────────────────────────────────┤
  │ alias     │ Dragging to create a link/shortcut                │
  ├───────────┼───────────────────────────────────────────────────┤
  │ dnd-move  │ Dragging to move an item                          │
  ├───────────┼───────────────────────────────────────────────────┤
  │ dnd-none  │ Dragging over a target that won't accept the drop │
  └───────────┴───────────────────────────────────────────────────┘

  Specialty

  ┌───────────────┬─────────────────────────────────────────────────────────────────────┐
  │   File name   │                           When it appears                           │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ zoom-in       │ Clicking will zoom in (magnifier with +)                            │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ zoom-out      │ Clicking will zoom out (magnifier with -)                           │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ cell          │ Over a spreadsheet/table cell for selection                         │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ vertical-text │ Over vertically-oriented text                                       │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ color-picker  │ Picking a color from the screen (eyedropper)                        │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ pencil        │ Drawing/annotation mode                                             │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ split_h       │ Hovering over a horizontal split handle                             │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ split_v       │ Hovering over a vertical split handle                               │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ up-arrow      │ Selection cursor pointing up                                        │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ center_ptr    │ Arrow pointing up-center (some window managers use for root window) │
  ├───────────────┼─────────────────────────────────────────────────────────────────────┤
  │ X_cursor      │ Fallback/error cursor (large X shape)                               │
  └───────────────┴─────────────────────────────────────────────────────────────────────┘

  Edge cursors (less common, used by some WMs)

  ┌─────────────────────┬──────────────────────────────────────────────┐
  │      File name      │               When it appears                │
  ├─────────────────────┼──────────────────────────────────────────────┤
  │ top_side            │ Hovering exactly on the top edge of a window │
  ├─────────────────────┼──────────────────────────────────────────────┤
  │ bottom_side         │ Hovering exactly on the bottom edge          │
  ├─────────────────────┼──────────────────────────────────────────────┤
  │ left_side           │ Hovering exactly on the left edge            │
  ├─────────────────────┼──────────────────────────────────────────────┤
  │ right_side          │ Hovering exactly on the right edge           │
  ├─────────────────────┼──────────────────────────────────────────────┤
  │ top_left_corner     │ Hovering on the top-left corner              │
  ├─────────────────────┼──────────────────────────────────────────────┤
  │ top_right_corner    │ Hovering on the top-right corner             │
  ├─────────────────────┼──────────────────────────────────────────────┤
  │ bottom_left_corner  │ Hovering on the bottom-left corner           │
  ├─────────────────────┼──────────────────────────────────────────────┤
  │ bottom_right_corner │ Hovering on the bottom-right corner          │
  └─────────────────────┴──────────────────────────────────────────────┘
