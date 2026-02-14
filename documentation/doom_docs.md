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

# new subject
