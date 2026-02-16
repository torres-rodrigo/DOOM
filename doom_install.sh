#!/bin/bash

# Exit if a command exits with a non-zero status
set -eEo pipefail

# Export directories first (needed for checkpoint directory)
export DOOM_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"
export ZIG_GLOBAL_CACHE_DIR="$XDG_CACHE_HOME/zig"
export ZIG_GLOBAL_PACKAGE_DIR="$XDG_DATA_HOME/zig"
export NUGET_PACKAGES="$XDG_CACHE_HOME/nuget"
export DOTNET_CLI_HOME="$XDG_CONFIG_HOME/dotnet"
export DOTNET_CLI_CACHE_HOME="$XDG_CACHE_HOME/dotnet"

export ZDOTDIR="$HOME/.config/zsh"

SPACER="============================================="

# Checkpoint system
CHECKPOINT_DIR="$XDG_STATE_HOME/doom-install"
CHECKPOINT_FILE="$CHECKPOINT_DIR/checkpoints"
mkdir -p "$CHECKPOINT_DIR"

checkpoint_exists() {
    [[ -f "$CHECKPOINT_FILE" ]] && grep -q "^$1:" "$CHECKPOINT_FILE"
}

checkpoint_create() {
    echo "$1:$(date '+%Y-%m-%d %H:%M:%S')" >> "$CHECKPOINT_FILE"
}

checkpoint_clear() {
    rm -rf "$CHECKPOINT_DIR"
    mkdir -p "$CHECKPOINT_DIR"
    echo "Checkpoints cleared - starting fresh installation"
    echo ""
}

get_next_phase() {
    # Define all phases in order
    local phases=(
        "phase_0_preflight:0. PREFLIGHT CHECKUPS"
        "phase_1_system_update:1. SYSTEM UPDATE"
        "phase_2_packages:2. PACKAGES"
        "phase_3_config_setup:3. CONFIG SETUP"
        "phase_3.5_hardware_system_setup:3.5. HARDWARE & SYSTEM SETUP"
        "phase_4_login_display_manager:4. LOGIN & DISPLAY MANAGER SETUP"
    )

    # Find first incomplete phase
    for phase_entry in "${phases[@]}"; do
        local phase_id="${phase_entry%%:*}"
        local phase_label="${phase_entry#*:}"
        if ! checkpoint_exists "$phase_id"; then
            echo "$phase_label"
            return
        fi
    done

    echo "All phases completed"
}

# Parse command-line arguments
for arg in "$@"; do
    case $arg in
        --clear|--fresh|-f)
            checkpoint_clear
            ;;
        --help|-h)
            echo "DOOM Installation Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --clear, --fresh, -f    Clear checkpoints and start fresh"
            echo "  --help, -h              Show this help message"
            echo ""
            echo "Checkpoint file: $CHECKPOINT_FILE"
            exit 0
            ;;
    esac
done

# Check for existing checkpoints
if [[ -f "$CHECKPOINT_FILE" ]]; then
    echo "$SPACER"
    echo "   Previous Installation Detected!"
    echo "$SPACER"
    echo ""
    echo "Completed phases:"
    while IFS=: read -r phase timestamp; do
        phase_display=$(echo "$phase" | sed 's/phase_/Phase /; s/_/ /g')
        echo "  ✓ $phase_display ($timestamp)"
    done < "$CHECKPOINT_FILE"
    echo ""

    next_phase=$(get_next_phase)
    echo "Next phase: $next_phase"
    echo ""

    echo "Options:"
    echo "  [r] Resume from last checkpoint"
    echo "  [s] Start fresh (clear checkpoints)"
    echo "  [q] Quit"
    echo ""
    read -p "Enter choice [r/s/q]: " -n 1 -r
    echo ""
    echo ""

    case $REPLY in
        [Rr]) echo "Resuming installation..." ;;
        [Ss]) checkpoint_clear ;;
        [Qq]) exit 0 ;;
        *) echo "Invalid choice, resuming..."; echo "" ;;
    esac
fi

# Error catching
catch_errors() {
    echo -e "\n\e[31mDOOM installation failed!\e[0m"
    echo
    echo
    if [[ -n "$CURRENT_SCRIPT" ]]; then
        echo "Failed in: $CURRENT_SCRIPT"
    fi
    echo
    echo "The following command finished with exit code $?"
    echo "$BASH_COMMAND"
    echo
    echo "Run the installer again to resume from the last checkpoint."
    echo
}

# Set the trap
trap catch_errors ERR INT TERM

# Track script being run
CURRENT_SCRIPT=""

run_script() {
    CURRENT_SCRIPT="$1"
    source "$1"
    CURRENT_SCRIPT=""
}

#PREFLIGHT CHECKUP
if ! checkpoint_exists "phase_0_preflight"; then
    echo "0. PREFLIGHT CHECKUPS"
    run_script "$DOOM_DIR/preflight/preflight.sh"
    checkpoint_create "phase_0_preflight"
    echo "$SPACER"
    echo
else
    echo "0. PREFLIGHT CHECKUPS (✓ skipped - already completed)"
    echo "$SPACER"
    echo
fi
#END PREFLIGHT CHECKUP

#SYSTEM UPDATE
if ! checkpoint_exists "phase_1_system_update"; then
    echo "1. SYSTEM UPDATE"
    sudo pacman -Syu --noconfirm
    checkpoint_create "phase_1_system_update"
    echo "$SPACER"
    echo
else
    echo "1. SYSTEM UPDATE (✓ skipped - already completed)"
    echo "$SPACER"
    echo
fi
#END SYSTEM UPDATE

#PACKAGES
if ! checkpoint_exists "phase_2_packages"; then
    echo "2. PACKAGES"
    run_script "$DOOM_DIR/packages/packages.sh"
    run_script "$DOOM_DIR/packages/fonts.sh"
    run_script "$DOOM_DIR/packages/aur.sh"
    checkpoint_create "phase_2_packages"
    echo "$SPACER"
    echo
else
    echo "2. PACKAGES (✓ skipped - already completed)"
    echo "$SPACER"
    echo
fi
#END PACKAGES

#CONFIG SETUP
if ! checkpoint_exists "phase_3_config_setup"; then
    echo "3. CONFIG SETUP"
    if [[ -d "$DOOM_DIR/config" ]]; then
        cp -rf "$DOOM_DIR/config"/* ~/.config/ || {
            echo "Warning: Some config files failed to copy"
        }
        echo "Configuration files copied"
    else
        echo "Error: config directory not found at $DOOM_DIR/config"
        exit 1
    fi
    checkpoint_create "phase_3_config_setup"
    echo "$SPACER"
    echo
else
    echo "3. CONFIG SETUP (✓ skipped - already completed)"
    echo "$SPACER"
    echo
fi
#END CONFIG SETUP

#HARDWARE & SYSTEM SETUP
if ! checkpoint_exists "phase_3.5_hardware_system_setup"; then
    echo "3.5. HARDWARE & SYSTEM SETUP"
    run_script "$DOOM_DIR/install/hardware/laptop-detect.sh"
    run_script "$DOOM_DIR/install/hardware/nvidia-detect.sh"
    run_script "$DOOM_DIR/install/hardware/bluetooth.sh"
    run_script "$DOOM_DIR/install/security/firewall.sh"
    run_script "$DOOM_DIR/install/security/fingerprint.sh"
    run_script "$DOOM_DIR/install/security/fido2.sh"

    # Deploy utility scripts
    echo "Installing DOOM utility scripts..."
    mkdir -p "$HOME/.local/bin"

    # Copy scripts safely with validation
    if compgen -G "$DOOM_DIR/scripts/doom-*" > /dev/null; then
        cp -f "$DOOM_DIR/scripts/"doom-* "$HOME/.local/bin/" || {
            echo "Warning: Some scripts failed to copy"
        }

        # Make scripts executable (only if they exist)
        if compgen -G "$HOME/.local/bin/doom-*" > /dev/null; then
            chmod +x "$HOME/.local/bin/"doom-*
            echo "DOOM utility scripts installed to ~/.local/bin"
        fi
    else
        echo "Warning: No doom-* scripts found in $DOOM_DIR/scripts/"
    fi

    # Enable clipboard service
    systemctl --user enable --now doom-cliphist.service

    checkpoint_create "phase_3.5_hardware_system_setup"
    echo "$SPACER"
    echo
else
    echo "3.5. HARDWARE & SYSTEM SETUP (✓ skipped - already completed)"
    echo "$SPACER"
    echo
fi
#END HARDWARE & SYSTEM SETUP

#LOGIN & DISPLAY MANAGER SETUP
if ! checkpoint_exists "phase_4_login_display_manager"; then
    echo "4. LOGIN & DISPLAY MANAGER SETUP"
    run_script "$DOOM_DIR/login/plymouth.sh"
    run_script "$DOOM_DIR/login/greetd.sh"
    checkpoint_create "phase_4_login_display_manager"
    echo "$SPACER"
    echo
else
    echo "4. LOGIN & DISPLAY MANAGER SETUP (✓ skipped - already completed)"
    echo "$SPACER"
    echo
fi
#END LOGIN & DISPLAY MANAGER SETUP

#INSTALLATION COMPLETE
echo ""
echo "============================================="
echo "       DOOM INSTALLATION COMPLETE!          "
echo "============================================="
echo ""
echo "Automatic Features Configured:"
echo "✓ Battery monitoring (laptops only)"
echo "✓ NVIDIA drivers (if GPU detected)"
echo "✓ Firewall enabled (UFW)"
echo "✓ Clipboard history (auto-save)"
echo "✓ Power profile optimized"
echo "✓ Bluetooth ready"
echo ""
echo "Optional Setup (run manually):"
echo "• Fingerprint: doom-setup-fingerprint"
echo "• FIDO2/Yubikey: doom-setup-fido2"
echo ""
echo "New Keybindings:"
echo "• Super+V: Clipboard history"
echo "• Super+Print: Screenshot with editor"
echo "• Super+R: Screen recording (toggle)"
echo "• Super+B: Bluetooth manager"
echo "• Print: Quick screenshot"
echo ""
echo "Reboot recommended for all changes to take effect."
echo "============================================="
echo ""

# Automatically clear checkpoints after successful installation
if [[ -f "$CHECKPOINT_FILE" ]]; then
    checkpoint_clear
fi
#END INSTALLATION COMPLETE

