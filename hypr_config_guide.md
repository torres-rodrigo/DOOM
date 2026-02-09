# Hyprland Configuration Guide
**Comparison of calos, dotfiles, and omarchy projects**

---

## Part 1: Settings Comparison Tables

All settings are compared side-by-side for easy reference.

### File Organization Structure

| Project | Files Used |
|---------|-----------|
| **calos** | monitors.conf, input.conf, keybindings.conf, autostart.conf, interface.conf, games.conf, theme/hyprland.conf |
| **dotfiles** | monitors.conf, input.conf, bindings.conf, envs.conf, looknfeel.conf, autostart.conf, animations.conf, windowsrules.conf, tiling.conf, media.conf |
| **omarchy** | defaults + user overrides (monitors.conf, input.conf, bindings.conf, looknfeel.conf, autostart.conf) |

---

### Ecosystem & XWayland Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `ecosystem.no_update_news` | `true` | Not set | `true` | Disable update notifications |
| `ecosystem.no_donation_nag` | `true` | Not set | Not set | Disable donation prompts |
| `xwayland.force_zero_scaling` | `true` | Not set | `true` | Force XWayland apps to scale 1x (HiDPI fix) |

---

### General Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `gaps_in` | `5` | `5` | `5` | Inner gaps between windows (px) |
| `gaps_out` | `10` | `12` | `10` | Outer gaps from screen edge (px) |
| `border_size` | `2` | `2` | `2` | Window border width (px) |
| `col.active_border` | `rgba(33ccffee) rgba(00ff99ee) 45deg` | `$secondary` | `$activeBorderColor` | Active window border color |
| `col.inactive_border` | `rgba(595959aa)` | `$outline_variant` | `$inactiveBorderColor` | Inactive window border color |
| `resize_on_border` | `false` | `true` | `false` | Click border to resize |
| `allow_tearing` | `true` | Not set | `false` | Enable tearing (gaming) |
| `layout` | `dwindle` | Not set | `dwindle` | Tiling layout algorithm |

---

### Cursor Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `inactive_timeout` | `5` | `1` | Not set | Hide cursor after N seconds |
| `no_warps` | `true` | Not set | Not set | Don't warp cursor to window center |
| `hide_on_key_press` | Not set | Not set | `true` | Hide cursor when typing |

---

### Decoration Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `rounding` | `7` | `10` | `0` | Corner radius (px) |

#### Blur Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `enabled` | `true` | `true` | `true` | Enable blur |
| `size` | `10` | `7` | `2` | Blur radius (px) |
| `passes` | `1` | `4` | `2` | Blur passes (more=stronger) |
| `ignore_opacity` | `true` | `true` | Not set | Blur regardless of opacity |
| `vibrancy` | `0.1696` | Not set | Not set | Vibrancy strength |
| `noise` | Not set | `0.0117` | Not set | Noise overlay |
| `contrast` | Not set | `0.8916` | `0.75` | Contrast adjustment |
| `brightness` | Not set | `0.8172` | `0.60` | Brightness adjustment |
| `xray` | Not set | `false` | Not set | X-ray mode |
| `popups` | Not set | `true` | Not set | Blur popups |
| `special` | Not set | Not set | `true` | Blur special workspaces |

#### Shadow Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `enabled` | `true` | Not set | `true` | Enable shadows |
| `range` | `15` | Not set | `2` | Shadow size (px) |
| `render_power` | `3` | Not set | `3` | Shadow intensity (1-4) |
| `color` | `rgba(1a1a1aee)` | Not set | `rgba(1a1a1aee)` | Shadow color |

---

### Input Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `kb_layout` | `us` | Not set | `us` | Keyboard layout |
| `kb_options` | Not set | `compose:ralt` | `compose:caps` | Compose key config |
| `follow_mouse` | `1` | `1` | `1` | Focus follows mouse |
| `repeat_rate` | `40` | Commented | Not set | Keyboard repeat rate (char/s) |
| `repeat_delay` | `600` | Commented | Not set | Repeat delay (ms) |
| `sensitivity` | `-0.80` | `0.40` | `0` | Mouse sensitivity |
| `numlock_by_default` | Not set | `true` | Not set | Enable numlock on start |

#### Touchpad Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `natural_scroll` | Not set | `false` | `false` | Reverse scroll direction |
| `scroll_factor` | Not set | `0.4` | Not set | Scroll speed multiplier |

---

### Misc Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `disable_hyprland_logo` | `true` | `true` | `true` | Hide logo on empty workspace |
| `disable_splash_rendering` | `true` | `true` | `true` | Hide splash text |
| `focus_on_activate` | `true` | `true` | `true` | Focus when app activates |
| `animate_manual_resizes` | `true` | Not set | Not set | Animate manual resize |
| `disable_watchdog_warning` | `true` | Not set | Not set | Disable watchdog warnings |
| `anr_missed_pings` | Not set | `3` | `3` | Pings before marking ANR |
| `on_focus_under_fullscreen` | Not set | `1` | `1` | Minimize fullscreen on focus |
| `key_press_enables_dpms` | Not set | `true` | `true` | Wake on key press |
| `mouse_move_enables_dpms` | Not set | `true` | `true` | Wake on mouse move |

---

### Dwindle Layout Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `pseudotile` | `true` | Not set | `true` | Enable pseudotiling |
| `preserve_split` | `true` | Not set | `true` | Keep split direction |
| `force_split` | `2` | Not set | `2` | Force split direction (2=right/bottom) |

---

### Master Layout Settings

| Setting | calos | dotfiles | omarchy | Description |
|---------|-------|----------|---------|-------------|
| `new_status` | `master` | Not set | `master` | Default status for new windows |

---

### Environment Variables

| Variable | calos | dotfiles | omarchy | Description |
|----------|-------|----------|---------|-------------|
| `XCURSOR_SIZE` | Not set | `24` | `24` | Cursor size |
| `HYPRCURSOR_SIZE` | Not set | `24` | `24` | Hyprland cursor size |
| `GDK_BACKEND` | Not set | `wayland,x11,*` | `wayland,x11,*` | GTK backend |
| `QT_QPA_PLATFORM` | Not set | `wayland;xcb` | `wayland;xcb` | Qt platform |
| `QT_STYLE_OVERRIDE` | Not set | `kvantum` | `kvantum` | Qt theme engine |
| `SDL_VIDEODRIVER` | Not set | `wayland` | `wayland` | SDL video driver |
| `MOZ_ENABLE_WAYLAND` | Not set | `1` | `1` | Firefox Wayland |
| `ELECTRON_OZONE_PLATFORM_HINT` | Not set | `wayland` | `wayland` | Electron Wayland |
| `OZONE_PLATFORM` | Not set | `wayland` | `wayland` | Chromium Wayland |
| `XDG_SESSION_TYPE` | Not set | `wayland` | `wayland` | Session type |
| `XDG_CURRENT_DESKTOP` | Not set | `Hyprland` | `Hyprland` | Desktop for portals |
| `XDG_SESSION_DESKTOP` | Not set | `Hyprland` | `Hyprland` | Session desktop |
| `GTK_THEME` | Not set | `adw-gtk3-dark` | Not set | GTK theme |
| `EDITOR` | Not set | `nvim` | Not set | Default editor |
| `XCOMPOSEFILE` | Not set | Not set | `~/.XCompose` | XCompose file |

---

## Part 2: Ready-to-Use Configuration Files

These files combine the best settings from all three projects.

### File: `hyprland.conf` (Main Config)

```conf
# DOOM Hyprland Configuration
# Main configuration file - sources all other configs

# Ecosystem settings
ecosystem {
  no_update_news = true
  no_donation_nag = true
}

# XWayland settings
xwayland {
  force_zero_scaling = true
}

# General settings
general {
  allow_tearing = true
}

# Misc settings (common across all projects)
misc {
  disable_hyprland_logo = true
  disable_splash_rendering = true
  focus_on_activate = true
  animate_manual_resizes = true
}

# Persistent workspace
workspace = 1, persistent:true

# Source all configuration files
source = ~/.config/hypr/envs.conf
source = ~/.config/hypr/monitors.conf
source = ~/.config/hypr/input.conf
source = ~/.config/hypr/looknfeel.conf
source = ~/.config/hypr/bindings.conf
source = ~/.config/hypr/windows.conf
source = ~/.config/hypr/autostart.conf
```

---

### File: `envs.conf` (Environment Variables)

```conf
# Environment Variables
# See https://wiki.hyprland.org/Configuring/Environment-variables/

# Cursor size
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24

# Force Wayland for all apps
env = GDK_BACKEND,wayland,x11,*
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_STYLE_OVERRIDE,kvantum
env = SDL_VIDEODRIVER,wayland
env = MOZ_ENABLE_WAYLAND,1
env = ELECTRON_OZONE_PLATFORM_HINT,wayland
env = OZONE_PLATFORM,wayland
env = XDG_SESSION_TYPE,wayland

# Desktop portal support
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_DESKTOP,Hyprland

# Default editor
env = EDITOR,nvim

# GTK theme (optional - customize to your preference)
# env = GTK_THEME,adw-gtk3-dark

# NVIDIA variables (uncomment if using NVIDIA GPU)
# env = NVD_BACKEND,direct
# env = LIBVA_DRIVER_NAME,nvidia
# env = __GLX_VENDOR_LIBRARY_NAME,nvidia

# Gum terminal styling (optional)
env = GUM_CONFIRM_PROMPT_FOREGROUND,6
env = GUM_CONFIRM_SELECTED_FOREGROUND,0
env = GUM_CONFIRM_SELECTED_BACKGROUND,2
env = GUM_CONFIRM_UNSELECTED_FOREGROUND,0
env = GUM_CONFIRM_UNSELECTED_BACKGROUND,8
```

---

### File: `monitors.conf` (Monitor Configuration)

```conf
# Monitor Configuration
# See https://wiki.hyprland.org/Configuring/Monitors/
# List monitors: hyprctl monitors
# Format: monitor = name, resolution@refresh, position, scale

# Auto-detect (good default for single monitor or automatic setup)
monitor = ,preferred,auto,1

# Examples for specific setups:

# Single 1440p 144Hz monitor
# monitor = ,2560x1440@144,auto,1

# Dual monitor setup
# monitor = HDMI-A-1,1920x1080@100,auto,1
# monitor = eDP-1,preferred,0x0,1

# HiDPI laptop + external monitor
# monitor = DP-5,6016x3384@60,auto,2
# monitor = eDP-1,2880x1920@120,auto,2

# Laptop screen toggle keybinds (optional)
# bindd = SUPER ALT, H, Laptop screen off, exec, hyprctl keyword monitor "eDP-1,disable"
# bindd = SUPER ALT, L, Laptop screen on, exec, hyprctl keyword monitor "eDP-1,preferred,0x0,1"

# Workspace to monitor assignment (optional)
# workspace = 1, monitor:HDMI-A-1
# workspace = 2, monitor:eDP-1
```

---

### File: `input.conf` (Input Devices)

```conf
# Input Device Configuration
# See https://wiki.hyprland.org/Configuring/Variables/#input

input {
  kb_layout = us
  kb_variant =
  kb_model =
  kb_options = compose:caps  # Use Caps Lock as compose key
  kb_rules =

  follow_mouse = 1
  numlock_by_default = true

  # Keyboard repeat settings
  repeat_rate = 40
  repeat_delay = 600

  # Mouse sensitivity (-1.0 to 1.0, 0 = no modification)
  # Adjust to your preference
  sensitivity = 0

  touchpad {
    natural_scroll = false
    scroll_factor = 0.4
  }
}

# Cursor settings
cursor {
  inactive_timeout = 5
  no_warps = true
  hide_on_key_press = false
}

# Gestures (3-finger swipe for workspace switching)
gesture = 3, horizontal, workspace

# DPMS (screen wake) settings
misc {
  key_press_enables_dpms = true
  mouse_move_enables_dpms = true
}
```

---

### File: `looknfeel.conf` (Appearance & Animations)

```conf
# Look and Feel Configuration
# Decorations, blur, shadows, animations

# Variables for border colors
$activeBorderColor = rgba(33ccffee) rgba(00ff99ee) 45deg
$inactiveBorderColor = rgba(595959aa)

# General appearance
general {
  gaps_in = 5
  gaps_out = 10
  border_size = 2
  col.active_border = $activeBorderColor
  col.inactive_border = $inactiveBorderColor
  resize_on_border = false
  layout = dwindle
}

# Decoration settings
decoration {
  rounding = 7

  shadow {
    enabled = true
    range = 15
    render_power = 3
    color = rgba(1a1a1aee)
  }

  blur {
    enabled = true
    size = 8
    passes = 2
    ignore_opacity = true
    vibrancy = 0.1696
    noise = 0.0117
    contrast = 0.8916
    brightness = 0.8172
    popups = true
  }
}

# Animations
animations {
  enabled = yes, please :)

  # Bezier curves
  bezier = easeOutQuint, 0.23, 1, 0.32, 1
  bezier = easeInOutCubic, 0.65, 0.05, 0.36, 1
  bezier = linear, 0, 0, 1, 1
  bezier = almostLinear, 0.5, 0.5, 0.75, 1.0
  bezier = quick, 0.15, 0, 0.1, 1
  bezier = defout, 0.16, 1, 0.3, 1
  bezier = overshot, 0.18, 0.95, 0.22, 1.03

  # Animation definitions
  animation = global, 1, 10, default
  animation = border, 1, 5.39, easeOutQuint
  animation = windows, 1, 4.79, easeOutQuint
  animation = windowsIn, 1, 4, overshot, popin 60%
  animation = windowsOut, 1, 1.1, linear, popin 70%
  animation = fadeIn, 1, 1.73, almostLinear
  animation = fadeOut, 1, 1.46, almostLinear
  animation = fade, 1, 3.03, quick
  animation = layers, 1, 3.81, easeOutQuint
  animation = layersIn, 1, 4, easeOutQuint, fade
  animation = layersOut, 1, 1.5, linear, fade
  animation = fadeLayersIn, 1, 1.79, almostLinear
  animation = fadeLayersOut, 1, 1.39, almostLinear
  animation = workspaces, 1, 4.5, defout, slidefade 15%
  animation = specialWorkspaceIn, 1, 5, default, slidefadevert
  animation = specialWorkspaceOut, 1, 5, defout, slidefadevert
}

# Dwindle layout
dwindle {
  pseudotile = true
  preserve_split = true
  force_split = 2  # Always split to the right/bottom
}

# Master layout
master {
  new_status = master
}

# Group settings (for window tabbing)
group {
  col.border_active = $activeBorderColor
  col.border_inactive = $inactiveBorderColor

  groupbar {
    font_size = 12
    font_family = monospace
    height = 22
    text_color = rgb(ffffff)
    col.active = rgba(00000040)
    gradients = true
  }
}

# Layer rules for UI elements
# Adjust namespaces based on your apps (rofi, waybar, etc.)

# App launcher blur
layerrule = match:namespace rofi, blur on
layerrule = match:namespace rofi, ignore_alpha 0
layerrule = match:namespace rofi, animation slide bottom

# Top bar blur
layerrule = match:namespace waybar, blur on
layerrule = match:namespace waybar, ignore_alpha 0

# Notifications blur
layerrule = match:namespace notifications, blur on
layerrule = match:namespace notifications, animation slide right
```

---

### File: `windows.conf` (Window Rules)

```conf
# Window Rules
# See https://wiki.hyprland.org/Configuring/Window-Rules/

# Fix XWayland drag issues
windowrule {
  name = fix-xwayland-drags
  match:class = ^$
  match:title = ^$
  match:xwayland = true
  match:float = true
  match:fullscreen = false
  match:pin = false

  no_focus = true
}

# Suppress maximize events and set default opacity
windowrule {
  name = suppress-maximize-events
  match:class = .*

  suppress_event = maximize
  opacity = 0.95 0.86
}

# Tag definitions for bulk rules
windowrule = tag +terminal, match:class (Alacritty|kitty|ghostty|foot|wezterm)
windowrule = tag +chromium, match:class ((google-)?[cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable)
windowrule = tag +firefox, match:class ([fF]irefox|zen|librewolf)
windowrule = tag +pip, match:title (Picture.?in.?[Pp]icture)
windowrule = tag +floating, match:class ^(pavucontrol|blueman-manager|nm-connection-editor)$

# Browser rules
windowrule {
  name = chromium_rules
  match:tag = chromium

  opacity = 0.98 0.95
}

windowrule {
  name = firefox_rules
  match:tag = firefox

  opacity = 0.98 0.95
}

# Picture-in-Picture
windowrule {
  name = pip_rules
  match:tag = pip

  float = on
  pin = on
  size = 600 350
  keep_aspect_ratio = on
  border_size = 0
  opacity = 1 1
}

# Floating windows
windowrule {
  name = float_default
  match:tag = floating

  float = on
  center = on
  size = 800 600
}

# Media players (no transparency)
windowrule {
  name = media_players
  match:class = ^(vlc|mpv|ffplay|com.obsproject.Studio)$

  opacity = 1.0 1.0
  border_size = 0
}

# Workspace assignments (customize to your apps)
# windowrule = match:class (code), workspace 2
# windowrule = match:class (firefox), workspace 3
# windowrule = match:class (discord), workspace 4
# windowrule = match:class (spotify), workspace 5
```

---

### File: `bindings.conf` (Keybindings)

```conf
# Keybindings
# See https://wiki.hyprland.org/Configuring/Binds/

# Set your main modifier key
$mainMod = SUPER

# Example keybindings (customize to your preference)
# These are just placeholders - add your actual keybindings here

# bind = $mainMod, RETURN, exec, kitty
# bind = $mainMod, Q, killactive,
# bind = $mainMod, M, exit,
# bind = $mainMod, E, exec, dolphin
# bind = $mainMod, V, togglefloating,
# bind = $mainMod, R, exec, rofi -show drun
# bind = $mainMod, P, pseudo,
# bind = $mainMod, J, togglesplit,

# Move focus with mainMod + arrow keys
# bind = $mainMod, left, movefocus, l
# bind = $mainMod, right, movefocus, r
# bind = $mainMod, up, movefocus, u
# bind = $mainMod, down, movefocus, d

# Switch workspaces with mainMod + [0-9]
# bind = $mainMod, 1, workspace, 1
# bind = $mainMod, 2, workspace, 2
# ... etc

# Move active window to a workspace with mainMod + SHIFT + [0-9]
# bind = $mainMod SHIFT, 1, movetoworkspace, 1
# bind = $mainMod SHIFT, 2, movetoworkspace, 2
# ... etc
```

---

### File: `autostart.conf` (Startup Applications)

```conf
# Autostart Applications
# Run once on Hyprland startup

# Set cursor theme (adjust to your cursor theme)
exec-once = hyprctl setcursor Bibata-Modern-Ice 24

# Start your status bar (uncomment and adjust)
# exec-once = waybar

# Start notification daemon (uncomment and adjust)
# exec-once = mako
# exec-once = dunst
# exec-once = swaync

# Start wallpaper daemon (uncomment and adjust)
# exec-once = hyprpaper
# exec-once = swaybg -i ~/wallpapers/background.png

# Start authentication agent (for password prompts)
# exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

# Start clipboard manager (uncomment if using clipse or similar)
# exec-once = clipse -listen

# Add your other autostart applications here
# exec-once = discord
# exec-once = spotify
```

---

## How to Use These Files

1. **Create the directory structure:**
   ```bash
   mkdir -p ~/.config/hypr
   ```

2. **Copy each file to ~/.config/hypr/**
   - Save each section above as its respective filename

3. **Customize to your needs:**
   - Edit `monitors.conf` for your display setup
   - Edit `bindings.conf` to add your keybindings
   - Edit `autostart.conf` to add your startup apps
   - Edit `windows.conf` to add workspace assignments for your apps
   - Adjust colors, blur strength, animation speeds in `looknfeel.conf`

4. **Test and reload:**
   ```bash
   # Reload Hyprland config
   hyprctl reload
   ```

5. **Check for errors:**
   ```bash
   # View Hyprland logs
   hyprctl logs
   ```

---

## Key Differences Between Projects

- **calos**: Most feature-complete, extensive window rules, tag-based system
- **dotfiles**: Clean separation of concerns, strong Wayland forcing, NVIDIA support
- **omarchy**: Minimal approach, uses defaults + user overrides pattern

**DOOM config combines:**
- calos's comprehensive window rules and ecosystem settings
- dotfiles's environment variables and Wayland forcing
- omarchy's group settings for window tabbing
- Best animation curves from calos
- Balanced blur settings (middle ground between all three)

---

## Additional Resources

- [Hyprland Wiki](https://wiki.hyprland.org/)
- [Configuring Variables](https://wiki.hyprland.org/Configuring/Variables/)
- [Window Rules](https://wiki.hyprland.org/Configuring/Window-Rules/)
- [Animations](https://wiki.hyprland.org/Configuring/Animations/)
