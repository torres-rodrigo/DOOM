# NixOS Documentation

> Research, notes, and decisions for building a full NixOS setup.
> This is the living document — all findings go here.

---

## Table of Contents
1. [Overview & Philosophy](#overview--philosophy)
2. [The Dendritic Pattern](#the-dendritic-pattern)
3. [Core Technology Stack](#core-technology-stack)
4. [Installation Workflow](#installation-workflow)
5. [Configuration Structure](#configuration-structure)
6. [Key Tools Reference](#key-tools-reference)
7. [Secrets Management](#secrets-management)
8. [Advanced Patterns](#advanced-patterns)
9. [Learning Resources](#learning-resources)
10. [Decisions Log](#decisions-log)
11. [**Complete Step-by-Step Setup Guide**](#complete-step-by-step-setup-guide)

---

## Overview & Philosophy

NixOS is a Linux distribution built on the **Nix package manager**, where the entire OS configuration is:
- **Declarative**: you describe the desired state, not the steps to get there
- **Reproducible**: the same config always produces the same system
- **Atomic**: upgrades and rollbacks are instant and safe
- **Immutable**: the Nix store (`/nix/store`) is read-only

The modern approach (2026) uses **Nix Flakes** as the foundation. Everything — packages, system config, user config, disk layout, secrets — is declared in Nix and version-controlled.

---

## The Dendritic Pattern

> The pattern the user was thinking of. It is real and was presented at NixCon 2025.

**What it is:** A configuration organization philosophy proposed by [mightyiam (Dawn)](https://github.com/mightyiam/dendritic). Originally titled "every file is a flake-parts module."

**Core principle:** Every `.nix` file (except entry points like `flake.nix` and `default.nix`) is a **top-level flake-parts module** that can read from and contribute to the top-level configuration.

**Key properties:**
- File paths represent *features*, not types — files can be freely renamed, moved, or split without breaking anything
- No manual `imports = [ ... ]` lists — all files are auto-loaded via [`vic/import-tree`](https://github.com/vic/import-tree)
- Using `specialArgs` / `extraSpecialArgs` to pass values between NixOS, Home Manager, and nix-darwin configs is explicitly considered an **anti-pattern**
- Instead: define your own flake-parts-level options or use `let` bindings
- Lower-level configs (NixOS, Home Manager, nix-darwin) are stored as *option values* in the top-level config
- Can work both with and without flake-parts (flake-less mode)

**Community ecosystem:**
- [mightyiam/dendritic](https://github.com/mightyiam/dendritic) — canonical reference implementation
- [Dendrix](https://discourse.nixos.org/t/dendrix-dendritic-nix-configurations-distribution/65853) — community distro inspired by editor distros (Spacemacs-style), built on dendritic to lower onboarding barrier
- [fbosch/nixos](https://github.com/fbosch/nixos) — real-world config using dendritic + flake-parts
- [Bad3r/nixos](https://github.com/Bad3r/nixos) — NixOS IaC using dendritic + flake-parts
- [NixCon 2025 talk](https://talks.nixcon.org/nixcon-2025/talk/REJ3LF/)
- [Discourse thread](https://discourse.nixos.org/t/the-dendritic-pattern/61271)

**Assessment:** This is an advanced pattern. Best approached after understanding standard modular NixOS configs. The standard modular approach is recommended as the starting point.

---

## Core Technology Stack

The recommended modern NixOS stack for 2026:

| Concern | Tool | Notes |
|---|---|---|
| Config format | **Nix Flakes** | De facto standard. Reproducible, lockfile-based |
| Flake structure | **flake-parts** | Modular flake composition, replaces flake-utils |
| Disk layout | **disko** | Declarative partitioning as NixOS module |
| Installation | **nixos-anywhere + disko** | Remote/unattended, single command |
| User environment | **Home Manager (NixOS module)** | Managed via `nixos-rebuild`, not separate |
| Secrets | **sops-nix** or **agenix** | See Secrets section |
| Config pattern | Modular → Dendritic (advanced) | Start modular, evolve to dendritic |
| Remote updates | `nixos-rebuild --target-host` or **deploy-rs** | deploy-rs has auto-rollback |
| State | **Impermanence** (optional) | Ephemeral root, explicit persistent state |

---

## Installation Workflow

The modern recommended installation is **flake + disko + nixos-anywhere** — fully declarative, repeatable, unattended.

### Pre-requisites
- A machine or VM running a NixOS minimal ISO (or any Linux with SSH)
- SSH access to the target machine
- Your config flake in a git repo

### Step-by-Step

1. **Write your flake** with disko disk layout included as a NixOS module
2. **Define `disk-config.nix`** (popular: GPT + EFI + LUKS + btrfs subvolumes)
3. **Test in a VM first:**
   ```bash
   nix run github:nix-community/nixos-anywhere -- --flake .#hostname --vm-test
   ```
4. **Boot target into NixOS minimal ISO** (or any Linux with SSH)
5. **Run nixos-anywhere:**
   ```bash
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#hostname \
     --generate-hardware-config nixos-generate-config ./hardware-configuration.nix \
     root@<ip-address>
   ```
   This will:
   - Partition and format disks via disko
   - Install NixOS
   - Reboot into the new system
6. **Commit `hardware-configuration.nix`** back to your repo
7. **Future updates:**
   ```bash
   nixos-rebuild switch --flake .#hostname --target-host user@host
   ```

### Important Notes
- Always `git add` new `.nix` files before building (untracked files are not in the Nix store)
- Commit `flake.lock` to your repo
- Never store unencrypted secrets in `flake.nix` (the Nix store is world-readable)
- nixos-anywhere requires target has 1GB+ RAM (for kexec)

---

## Configuration Structure

### Recommended Directory Layout

```
my-nixos-config/
├── flake.nix                  ← entry point, defines inputs and outputs
├── flake.lock                 ← auto-generated, commit this
├── hosts/
│   └── myhostname/
│       ├── default.nix        ← host-specific config
│       ├── hardware-configuration.nix   ← auto-generated by nixos-generate-config
│       └── disk-config.nix    ← disko disk layout
├── modules/
│   ├── nixos/                 ← NixOS system modules
│   │   ├── boot.nix
│   │   ├── networking.nix
│   │   ├── desktop.nix
│   │   └── fonts.nix
│   └── home-manager/          ← Home Manager user modules
│       ├── terminal.nix
│       ├── editor.nix
│       └── browser.nix
├── home/
│   └── username/
│       └── home.nix           ← user-level home-manager config
├── pkgs/                      ← custom packages
└── overlays/                  ← nixpkgs overlays
```

### Minimal `flake.nix` skeleton

```nix
{
  description = "My NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, ... } @ inputs: {
    nixosConfigurations.myhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        ./hosts/myhostname
        ./modules/nixos/boot.nix
        ./modules/nixos/networking.nix
        {
          home-manager.users.myuser = import ./home/myuser/home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
```

---

## Key Tools Reference

### Nix Flakes
The standard for reproducible NixOS configs. Provides:
- Locked dependency graph via `flake.lock`
- Standardized `inputs`/`outputs` schema
- Atomic upgrades and rollbacks
- Shareable configs runnable anywhere without local install

**NixOS channel choices:**
- `nixos-unstable` — latest packages, rolling
- `nixos-25.11` — current stable (as of 2026)
- Mix: system on stable, some packages from unstable overlay

### flake-parts
Applies the NixOS module system to flakes themselves. Replaces the deprecated `flake-utils`.
- `perSystem` attribute handles multi-architecture boilerplate
- Community modules at [flake.parts](https://flake.parts/)
- Foundation for the dendritic pattern

### disko
Declarative disk partitioning as a NixOS module.
- Supports: LUKS, LVM, btrfs/ZFS/bcachefs/ext4, GPT/MBR
- New `disko-install` tool = disko + nixos-install in one step
- Disk config is just a Nix file — version controlled

**Example disko config (GPT + EFI + btrfs):**
```nix
{
  disko.devices = {
    disk.main = {
      device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
```

### nixos-anywhere
Remote NixOS installer over SSH. Uses `kexec` to boot a RAM NixOS environment on the target, then runs disko to partition, then `nixos-install` to deploy. Single CLI command. Works on Hetzner, Vultr, bare metal LANs, VMs.

### Home Manager
Manages per-user packages and dotfiles declaratively.

**Integration modes:**
1. **Standalone** — `home-manager switch` independently; portable across non-NixOS
2. **NixOS module** (recommended for NixOS) — builds with system via `nixos-rebuild switch`
3. **nix-darwin module** — for macOS

### deploy-rs vs nixos-rebuild --target-host

| Feature | nixos-rebuild | deploy-rs |
|---|---|---|
| Auto rollback | No | Yes (magic rollback) |
| Multi-host | Manual | Yes |
| Root-less | No | Yes |
| Simplicity | Simple | More setup |

---

## Secrets Management

**Rule:** Never store unencrypted secrets in the Nix store (it is world-readable at `/nix/store`).

### sops-nix
- Encryption: GPG, age, AWS/GCP/Azure KMS, HashiCorp Vault
- Secret formats: YAML, JSON, INI, dotenv, binary
- Supports templating
- Best for: cloud environments, multiple secret formats, team setups

### agenix
- Encryption: age only (using SSH public keys)
- One file per secret
- Minimal codebase — very auditable
- No templating
- Best for: simple personal setups, existing SSH keys

### Comparison

| | sops-nix | agenix |
|---|---|---|
| Encryption backends | GPG, age, AWS/GCP/Azure KMS, Vault | age only |
| Secret format | YAML, JSON, INI, dotenv, binary | one file per secret |
| Templating | Yes | No |
| Cloud KMS | Yes | No |
| Simplicity | Moderate | Very simple |
| SSH key support | Via age | Yes (directly) |

**Recommendation:** Start with **agenix** for simplicity. Move to **sops-nix** if you need cloud KMS or multi-format secrets.

---

## Advanced Patterns

### Impermanence
The `/` filesystem is wiped on every reboot (via tmpfs or btrfs snapshot rollback). Since NixOS only truly needs `/nix` and `/boot`, all other state is ephemeral unless explicitly declared as persistent.

**Benefits:**
- Eliminates configuration drift completely
- Forces all state to be declared explicitly
- System is always in a known good state after reboot

**How it works:**
- Mount `/` as tmpfs
- Declare persistent paths in `environment.persistence`
- On each boot, only declared paths survive

**Resources:**
- [impermanence GitHub](https://github.com/nix-community/impermanence)
- [NixOS Wiki — Impermanence](https://wiki.nixos.org/wiki/Impermanence)

### snowfall-lib
Convention-over-configuration alternative to flake-parts. Auto-discovers systems, packages, modules from directory layout. More opinionated, less flexible than dendritic/flake-parts.

---

## Learning Resources

| Resource | Type | Notes |
|---|---|---|
| [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/) | Book | Best comprehensive modern guide |
| [NixOS Manual](manual.md) | Manual | Official NixOS 25.11 docs (local copy) |
| [NixOS Wiki](https://wiki.nixos.org/) | Wiki | Community wiki, very useful |
| [nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) | Template | Well-documented starter boilerplate |
| [flake.parts](https://flake.parts/) | Docs | flake-parts documentation and modules |
| [disko](https://github.com/nix-community/disko) | Tool | Declarative disk partitioning |
| [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) | Tool | Remote NixOS installer |
| [Home Manager Manual](https://nix-community.github.io/home-manager/) | Manual | Official Home Manager docs |
| [Dendritic pattern](https://github.com/mightyiam/dendritic) | Pattern | Advanced config organization |
| [NixCon 2025 — Dendritic](https://talks.nixcon.org/nixcon-2025/talk/REJ3LF/) | Talk | Original NixCon 2025 presentation |
| [Discourse: config structure](https://discourse.nixos.org/t/how-do-you-structure-your-nixos-configs/65851) | Community | Community discussion on config organization |

---

## Decisions Log

| Date | Decision | Rationale |
|---|---|---|
| 2026-03-24 | Use Nix Flakes as base | De facto standard, reproducible, lockfile |
| 2026-03-24 | Use flake-parts for flake structure | Modern, replaces flake-utils, enables dendritic |
| 2026-03-24 | Use disko for disk layout | Declarative, version-controlled, works with nixos-anywhere |
| 2026-03-24 | Use nixos-anywhere for installation | Unattended, repeatable, single command |
| 2026-03-24 | Home Manager as NixOS module | Single `nixos-rebuild switch` manages everything |
| 2026-03-24 | Start with modular pattern, not dendritic | Dendritic is advanced; learn fundamentals first |
| 2026-03-24 | Evaluate sops-nix vs agenix later | Depends on secret requirements; agenix simpler to start |

---

## Complete Step-by-Step Setup Guide

> The complete practical guide to setting up NixOS from zero to a fully working system.
> Uses the 2026 best-practice stack: Flakes + flake-parts + disko + nixos-anywhere + Home Manager + agenix.

---

### Phase 0: Before You Begin

#### 0.1 Hardware Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| RAM (for nixos-anywhere kexec) | 1 GB | 2 GB+ |
| Disk space | 20 GB | 50 GB+ |
| Architecture | x86_64 or aarch64 | x86_64-linux |
| Boot mode | BIOS or UEFI | UEFI (preferred) |
| Network | Required during install | Wired preferred |

#### 0.2 What You Need Before Starting

- A machine or VM to install NixOS on, booted into a NixOS minimal ISO (or any Linux with SSH)
- A separate machine (your workstation) with Nix installed — this is where you write and push your config
- An SSH key pair — your public key will be baked into the NixOS config
- A git repository (local or hosted) to store your configuration
- Network access from both machines

#### 0.3 Install Nix on Your Workstation (if not on NixOS)

If you are writing the config from a Linux or macOS machine that is not NixOS, install Nix first.
The **Determinate Nix Installer** is the recommended approach — it sets up flakes and nix-command by default:

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Restart your shell after installing.

Verify:
```bash
nix --version
# nix (Nix) 2.x.x
```

#### 0.4 Enable Flakes (if using plain Nix installer)

If you used the official Nix installer (not Determinate), enable flakes manually:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

#### 0.5 Understanding the Philosophy

Before writing a single line of config, internalise these principles:

1. **The Nix store is immutable and world-readable.** `/nix/store` contains everything. Never put secrets there. The store path of a file is determined by its content hash — the same content always produces the same path.

2. **Every rebuild is atomic.** Either your new config builds completely or the system stays on the old one. You cannot end up in a half-upgraded state.

3. **`git add` is part of the workflow.** Nix flakes only see files that are tracked by git (even if not committed). If you create a new `.nix` file and don't `git add` it, the build will fail as if the file doesn't exist.

4. **`nixos-rebuild switch` is the main day-to-day command.** It builds, activates, and sets your config as the boot default in one step.

5. **Hardware-configuration is generated, not hand-written.** `hardware-configuration.nix` is auto-generated from your actual hardware. It lives in your repo but you never edit it manually.

---

### Phase 1: Setting Up the Config Repository

#### 1.1 Create the Repository

On your workstation:

```bash
mkdir nixos-config
cd nixos-config
git init
git branch -M main
```

#### 1.2 Create the Directory Structure

```bash
mkdir -p hosts/myhostname
mkdir -p modules/nixos
mkdir -p modules/home-manager
mkdir -p home/myuser
mkdir -p pkgs
mkdir -p overlays
```

Final structure:
```
nixos-config/
├── flake.nix
├── flake.lock                  ← auto-generated, commit it
├── hosts/
│   └── myhostname/
│       ├── default.nix         ← host-specific config
│       ├── hardware-configuration.nix  ← auto-generated at install time
│       └── disk-config.nix     ← disko disk layout
├── modules/
│   ├── nixos/                  ← system-level modules
│   │   ├── boot.nix
│   │   ├── networking.nix
│   │   ├── users.nix
│   │   ├── locale.nix
│   │   └── desktop.nix         ← optional, if using a desktop
│   └── home-manager/           ← user-level modules
│       ├── shell.nix
│       ├── editor.nix
│       └── git.nix
├── home/
│   └── myuser/
│       └── home.nix
├── pkgs/                       ← custom packages (empty for now)
└── overlays/                   ← nixpkgs overlays (empty for now)
```

#### 1.3 Write the Root `flake.nix`

This is the entry point of your entire configuration. Every tool, every module, every package version is declared here.

```nix
# flake.nix
{
  description = "My NixOS configuration";

  inputs = {
    # nixpkgs — the package collection. Use unstable for latest packages,
    # or nixos-25.11 for a stable release.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # home-manager — manages user environment declaratively.
    # "follows" means it uses the same nixpkgs version as above,
    # avoiding a second copy of the package collection.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # disko — declarative disk partitioning.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # agenix — secrets management using age encryption.
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, agenix, ... } @ inputs:
  let
    # The system architecture. Change to "aarch64-linux" for ARM.
    system = "x86_64-linux";
  in
  {
    nixosConfigurations = {
      # Replace "myhostname" with your actual hostname.
      myhostname = nixpkgs.lib.nixosSystem {
        inherit system;
        # specialArgs passes extra arguments to all modules.
        # "inputs" gives every module access to flake inputs (e.g., inputs.agenix).
        specialArgs = { inherit inputs; };
        modules = [
          # Tool modules — order does not matter, they merge.
          disko.nixosModules.disko
          agenix.nixosModules.default
          home-manager.nixosModules.home-manager

          # Host-specific config.
          ./hosts/myhostname

          # System modules.
          ./modules/nixos/boot.nix
          ./modules/nixos/networking.nix
          ./modules/nixos/users.nix
          ./modules/nixos/locale.nix

          # Home Manager configuration for each user.
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.myuser = import ./home/myuser/home.nix;
          }
        ];
      };
    };
  };
}
```

> **What `useGlobalPkgs` and `useUserPackages` do:**
> - `useGlobalPkgs = true` — Home Manager uses the same `pkgs` as the system (not a separate nixpkgs instance). Reduces build time and disk usage.
> - `useUserPackages = true` — User packages are installed into the system profile, making them available system-wide. Required for some programs that need `/etc` integration.

---

### Phase 2: Disk Layout with Disko

Disko describes your disk layout in Nix. This replaces manual partitioning and makes your disk setup reproducible and version-controlled.

#### 2.1 Choose Your Layout

Two options are provided below. Start with Option A (simpler). Move to Option B if you need LUKS encryption.

---

**Option A: GPT + EFI + ext4 (Simple, no encryption)**

```nix
# hosts/myhostname/disk-config.nix
{
  disko.devices = {
    disk = {
      main = {
        # Change to your actual disk device (check with: lsblk)
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition — where the bootloader lives.
            # Must be FAT32, at least 256MB. 512MB is comfortable.
            ESP = {
              size = "512M";
              type = "EF00";  # EFI System Partition type code
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            # Swap partition — optional but recommended.
            # Rule of thumb: match your RAM if you want hibernation,
            # otherwise 4-8GB is fine.
            swap = {
              size = "8G";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true;  # enable hibernation support
              };
            };

            # Root partition — takes the rest of the disk.
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
```

---

**Option B: GPT + EFI + LUKS + btrfs (Encrypted, with subvolumes)**

This is the more advanced setup. LUKS encrypts the entire root partition. btrfs subvolumes allow snapshots and efficient storage.

```nix
# hosts/myhostname/disk-config.nix
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";  # change to your disk
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition.
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            # LUKS-encrypted partition containing everything else.
            luks = {
              size = "100%";
              content = {
                type = "luks";
                # The name used to open the device: /dev/mapper/cryptroot
                name = "cryptroot";
                # Recommended settings for modern hardware:
                settings = {
                  allowDiscards = true;    # enable TRIM for SSDs
                  bypassWorkqueues = true; # better SSD performance
                };
                # The content inside the LUKS container:
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];   # force format
                  subvolumes = {
                    # Root subvolume — the main filesystem.
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # Home subvolume — user data, separate for easy snapshots.
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # Nix store subvolume — large, benefits from compression.
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # Swap file inside btrfs.
                    # Note: swap files on btrfs require special handling.
                    # Alternatively, use a separate partition for swap.
                    "/swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "8G";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
```

> **btrfs mount options explained:**
> - `compress=zstd` — transparent compression. Reduces disk usage by 20-40% on typical workloads with minimal CPU overhead.
> - `noatime` — don't update file access timestamps. Reduces write amplification significantly.

---

### Phase 3: NixOS System Configuration

#### 3.1 Host Entry Point

```nix
# hosts/myhostname/default.nix
{ config, pkgs, inputs, ... }:
{
  imports = [
    # Generated at install time — describes your hardware.
    # Do not edit manually.
    ./hardware-configuration.nix
    # Disk layout declared with disko.
    ./disk-config.nix
  ];

  # System-wide packages available to all users.
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    tree
  ];

  # Allow unfree packages (e.g., NVIDIA drivers, some firmware).
  nixpkgs.config.allowUnfree = true;

  # Nix daemon settings.
  nix.settings = {
    # Enable flakes and the new nix command.
    experimental-features = [ "nix-command" "flakes" ];
    # Use the binary cache to avoid building everything from source.
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
    # Allow your user to use nix commands without sudo.
    trusted-users = [ "root" "myuser" ];
  };

  # Automatic garbage collection — removes old generations.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Keep the system consistent with your flake.
  # Disables imperative package management (nix-env -i, etc.).
  nix.settings.nix-path = [ "nixpkgs=${inputs.nixpkgs}" ];

  # NixOS version. Do not change after installation unless you know what you're doing.
  # This does NOT control which packages are installed — that's handled by nixpkgs input.
  # It controls whether certain migration scripts run during upgrades.
  system.stateVersion = "25.11";
}
```

#### 3.2 Boot Configuration

```nix
# modules/nixos/boot.nix
{ config, pkgs, lib, ... }:
{
  # systemd-boot is the recommended bootloader for UEFI systems.
  # It is simpler and more reliable than GRUB for single-OS setups.
  boot.loader.systemd-boot = {
    enable = true;
    # Limit the number of boot entries kept. Older generations are
    # still accessible via nixos-rebuild but won't clutter the menu.
    configurationLimit = 10;
    # Allow editing kernel cmdline at boot (disable in production).
    editor = false;
  };

  # Mount the EFI partition at /boot.
  boot.loader.efi.canTouchEfiVariables = true;

  # For BIOS systems (legacy boot), replace the above with:
  # boot.loader.grub = {
  #   enable = true;
  #   device = "/dev/sda";  # the disk, not a partition
  # };

  # Latest Linux kernel. Use linux_lts for the Long-Term Support kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Kernel parameters. Add as needed.
  boot.kernelParams = [
    # "quiet"        # suppress boot messages
    # "splash"       # show plymouth splash screen
  ];

  # Enable Plymouth (boot splash screen). Optional.
  # boot.plymouth.enable = true;

  # Load kernel modules early if needed.
  # boot.initrd.kernelModules = [ "amdgpu" ];  # for AMD GPU users
}
```

#### 3.3 Networking

```nix
# modules/nixos/networking.nix
{ config, pkgs, ... }:
{
  # Set the hostname. Must match what you used in flake.nix nixosConfigurations.
  networking.hostName = "myhostname";

  # NetworkManager — the standard for desktop systems.
  # Handles wired, wireless, VPN connections with a GUI/CLI.
  networking.networkmanager.enable = true;

  # Firewall — enabled by default. Open ports as needed.
  networking.firewall = {
    enable = true;
    # Example: open SSH port
    # allowedTCPPorts = [ 22 ];
    # Example: open a range of ports
    # allowedTCPPortRanges = [ { from = 8000; to = 8100; } ];
  };

  # SSH daemon. Disable if this is a desktop-only machine.
  services.openssh = {
    enable = true;
    settings = {
      # Never allow root login over SSH.
      PermitRootLogin = "no";
      # Only allow key-based authentication. Disable password auth.
      PasswordAuthentication = false;
      # Only allow key-based authentication.
      KbdInteractiveAuthentication = false;
    };
  };
}
```

#### 3.4 Users

```nix
# modules/nixos/users.nix
{ config, pkgs, ... }:
{
  # Disable mutableUsers to make the system fully declarative.
  # With this set to false, you CANNOT use passwd to change passwords.
  # All passwords must be set declaratively or via hashedPasswordFile.
  # Start with true during setup, set to false once comfortable.
  users.mutableUsers = true;

  users.users.myuser = {
    isNormalUser = true;
    # Description shown in the login screen.
    description = "My User";
    # Groups:
    # - wheel: sudo access
    # - networkmanager: manage network connections without sudo
    # - video: access to GPU/display devices
    # - audio: access to audio devices
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];

    # Your SSH public key — used for remote login AND for agenix secrets.
    # Replace with your actual public key.
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA...your-public-key-here... myuser@workstation"
    ];

    # Set an initial hashed password.
    # Generate with: mkpasswd -m sha-512
    # Once the system is running, you can change it with passwd.
    # initialHashedPassword = "$6$...";
    # OR for initial setup convenience:
    initialPassword = "changeme";  # change immediately after first login!
  };

  # Allow users in the wheel group to use sudo without a password.
  # Remove this line once you're comfortable with NixOS.
  security.sudo.wheelNeedsPassword = false;
}
```

#### 3.5 Locale and Time

```nix
# modules/nixos/locale.nix
{ config, ... }:
{
  # Timezone. Find yours at: timedatectl list-timezones
  time.timeZone = "Europe/Lisbon";

  # System locale — affects language, date format, number format.
  i18n.defaultLocale = "en_US.UTF-8";

  # Extra locale settings. Mix and match as needed.
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "pt_PT.UTF-8";
    LC_IDENTIFICATION = "pt_PT.UTF-8";
    LC_MEASUREMENT    = "pt_PT.UTF-8";
    LC_MONETARY       = "pt_PT.UTF-8";
    LC_NAME           = "pt_PT.UTF-8";
    LC_NUMERIC        = "pt_PT.UTF-8";
    LC_PAPER          = "pt_PT.UTF-8";
    LC_TELEPHONE      = "pt_PT.UTF-8";
    LC_TIME           = "pt_PT.UTF-8";
  };

  # Console keyboard layout.
  console = {
    keyMap = "us";  # or "pt" for Portuguese
    # font = "Lat2-Terminus16";  # optional console font
  };

  # X11 keyboard layout (if using a desktop environment).
  services.xserver.xkb = {
    layout = "us";
    # variant = "";  # e.g., "intl" for international layout
    # options = "caps:escape";  # remap CapsLock to Escape
  };
}
```

#### 3.6 Desktop Environment (Optional)

Only add this if you want a graphical desktop. Skip for headless servers.

```nix
# modules/nixos/desktop.nix
{ config, pkgs, ... }:
{
  # Enable the X11 windowing system.
  # Even if you use Wayland, some tools still need X11 support.
  services.xserver.enable = true;

  # --- GNOME Desktop ---
  services.xserver.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # --- OR: Plasma (KDE) ---
  # services.displayManager.sddm.enable = true;
  # services.desktopManager.plasma6.enable = true;

  # --- OR: Hyprland (Wayland tiling compositor, no GNOME/KDE) ---
  # programs.hyprland.enable = true;
  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;

  # Enable sound with PipeWire — the modern audio server.
  # PipeWire replaces PulseAudio and JACK.
  hardware.pulseaudio.enable = false;  # disable PulseAudio if using PipeWire
  security.rtkit.enable = true;         # real-time priority for PipeWire
  services.pipewire = {
    enable = true;
    alsa.enable = true;        # ALSA compatibility
    alsa.support32Bit = true;  # 32-bit ALSA (needed for some games/apps)
    pulse.enable = true;       # PulseAudio compatibility layer
    jack.enable = true;        # JACK compatibility layer (for audio production)
  };

  # Bluetooth.
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;  # Bluetooth manager GUI

  # Fonts — essential for a good desktop experience.
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
    ];
    fontconfig = {
      defaultFonts = {
        serif     = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "Fira Code" ];
        emoji     = [ "Noto Color Emoji" ];
      };
    };
  };
}
```

> **Add `./modules/nixos/desktop.nix`** to the `modules` list in `flake.nix` if you create this file.

---

### Phase 4: Home Manager Configuration

Home Manager manages everything at the user level: dotfiles, shell config, user packages, editor settings, git config, and more.

#### 4.1 User Home Config Entry Point

```nix
# home/myuser/home.nix
{ config, pkgs, inputs, ... }:
{
  # Home Manager needs to know your username and home directory.
  home.username = "myuser";
  home.homeDirectory = "/home/myuser";

  # This value should match the NixOS stateVersion.
  # Like system.stateVersion, do not change it after the first activation.
  home.stateVersion = "25.11";

  # Let Home Manager manage itself when used as a NixOS module.
  programs.home-manager.enable = true;

  # User-level packages — installed only for this user.
  # Prefer declaring packages in program-specific modules below,
  # but for one-off tools, list them here.
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    eza       # modern ls replacement
    fzf
    jq
    unzip
    p7zip
  ];

  # Import sub-modules that configure specific programs.
  imports = [
    ./shell.nix
    ./git.nix
    ./editor.nix
  ];
}
```

#### 4.2 Shell Configuration

```nix
# home/myuser/shell.nix
# (imported from home.nix)
{ config, pkgs, ... }:
{
  # Zsh — the recommended shell for NixOS users.
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Shell aliases.
    shellAliases = {
      ls    = "eza";
      ll    = "eza -la";
      la    = "eza -la --git";
      tree  = "eza --tree";
      cat   = "bat";
      grep  = "rg";
      find  = "fd";
      # NixOS-specific aliases
      nrs   = "sudo nixos-rebuild switch --flake .#myhostname";
      nrb   = "sudo nixos-rebuild boot --flake .#myhostname";
      nrt   = "sudo nixos-rebuild test --flake .#myhostname";
      nfu   = "nix flake update";
      ngc   = "sudo nix-collect-garbage --delete-older-than 30d";
      nls   = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    };

    # Commands to run when starting an interactive shell.
    initExtra = ''
      # Add local scripts to PATH
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };

  # Set zsh as the default shell.
  # Also add zsh to /etc/shells in your NixOS config:
  # programs.zsh.enable = true;  (in a NixOS module, not home-manager)
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SHELL  = "${pkgs.zsh}/bin/zsh";
  };

  # Starship prompt — works with any shell.
  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[λ](bold green)";
        error_symbol   = "[λ](bold red)";
      };
    };
  };

  # fzf — fuzzy finder, integrates with shell history and file search.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # direnv — automatically loads environment when entering a directory.
  # Essential for per-project nix dev shells.
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;  # nix-specific integration with caching
  };
}
```

> **Important:** To make zsh the default login shell system-wide, add this to a NixOS module:
> ```nix
> programs.zsh.enable = true;
> users.users.myuser.shell = pkgs.zsh;
> ```

#### 4.3 Git Configuration

```nix
# home/myuser/git.nix
# (imported from home.nix)
{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName  = "Your Name";
    userEmail = "your@email.com";

    # Sign commits with SSH key — more modern than GPG.
    signing = {
      key = "~/.ssh/id_ed25519.pub";
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      # Use SSH for GitHub instead of HTTPS.
      url."git@github.com:".insteadOf = "https://github.com/";
      # Better diff output.
      diff.algorithm = "histogram";
      merge.conflictstyle = "zdiff3";
    };

    # delta — a better diff viewer.
    delta = {
      enable = true;
      options = {
        navigate    = true;
        light       = false;
        line-numbers = true;
        side-by-side = true;
      };
    };

    # Global gitignore — files ignored in all repos.
    ignores = [
      ".DS_Store"
      "*.swp"
      ".direnv"
      ".env"
      ".envrc"
    ];
  };
}
```

#### 4.4 Editor Configuration (Neovim)

```nix
# home/myuser/editor.nix
# (imported from home.nix)
{ config, pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias  = true;
    vimAlias = true;

    # Extra packages available to Neovim (LSP servers, formatters, etc.)
    extraPackages = with pkgs; [
      # Language servers
      nil          # Nix LSP
      lua-language-server
      # Formatters
      nixpkgs-fmt
      stylua
    ];

    # Neovim plugins managed by Nix — fully declarative.
    plugins = with pkgs.vimPlugins; [
      # Plugin manager (lazy-loading capable)
      lazy-nvim

      # UI
      catppuccin-nvim    # color scheme
      lualine-nvim       # status line
      nvim-tree-lua      # file explorer

      # Editing
      nvim-treesitter    # syntax highlighting
      nvim-lspconfig     # LSP client
      nvim-cmp           # completion engine
      luasnip            # snippets

      # Nix-specific
      vim-nix
    ];

    # Neovim Lua config.
    extraLuaConfig = ''
      -- Set leader key
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- Basic settings
      vim.opt.number         = true
      vim.opt.relativenumber = true
      vim.opt.expandtab      = true
      vim.opt.tabstop        = 2
      vim.opt.shiftwidth     = 2
      vim.opt.termguicolors  = true
      vim.opt.signcolumn     = "yes"
      vim.opt.undofile       = true
      vim.opt.ignorecase     = true
      vim.opt.smartcase      = true

      -- Colorscheme
      vim.cmd.colorscheme("catppuccin-mocha")
    '';
  };
}
```

---

### Phase 5: Secrets Management with agenix

Secrets (passwords, API keys, tokens) must never be stored in plaintext in your config — the Nix store is world-readable. agenix encrypts secrets with `age`, using your SSH keys.

#### 5.1 How agenix Works

1. You have an SSH key pair. The public key is in your config, the private key stays on your machine.
2. You encrypt a secret with one or more public keys — only holders of the matching private key can decrypt.
3. Encrypted secrets live in your git repo (safe to commit — they are ciphertext).
4. At system activation time, agenix decrypts each secret and places it at a path in `/run/agenix/` (a tmpfs — secrets never hit disk unencrypted).
5. Your NixOS config references the decrypted path.

#### 5.2 Create `secrets.nix`

This file tells agenix which keys can decrypt which secrets. It is NOT encrypted — it's just a mapping of secret files to their authorized public keys.

```nix
# secrets/secrets.nix
let
  # Your SSH public key. Must match the private key on the machine
  # that will activate the config.
  myuser = "ssh-ed25519 AAAA...your-public-key...";

  # The host SSH key — generated at first boot.
  # Get it after first install with: cat /etc/ssh/ssh_host_ed25519_key.pub
  # Then update this value and re-encrypt all secrets for the host.
  myhostname = "ssh-ed25519 AAAA...host-public-key...";

  # Group all keys that should be able to decrypt everything.
  all = [ myuser myhostname ];
in
{
  # Each entry declares a secret file and who can decrypt it.
  "secrets/userPassword.age".publicKeys = all;
  "secrets/wireguardKey.age".publicKeys = all;
  # Add more secrets as needed.
}
```

#### 5.3 Encrypt a Secret

```bash
# Install agenix CLI (run from your config repo root).
# On a NixOS machine with your flake, it's already available via the module.
# On other machines, use nix run:
nix run github:ryantm/agenix -- --help

# Create the secrets directory.
mkdir -p secrets

# Encrypt a secret interactively.
# This will open your editor; type the secret, save, and quit.
# agenix reads public keys from secrets/secrets.nix automatically.
nix run github:ryantm/agenix -- -e secrets/userPassword.age

# The resulting .age file is safe to commit to git.
git add secrets/
```

#### 5.4 Use Secrets in Your NixOS Config

```nix
# In any NixOS module (e.g., hosts/myhostname/default.nix)
{ config, ... }:
{
  # Declare the secret — agenix will decrypt it at activation time.
  age.secrets.userPassword = {
    # Path to the encrypted file, relative to the flake root.
    file = ../../secrets/userPassword.age;
    # Who can read the decrypted file. Defaults to root only.
    owner = "myuser";
    mode  = "0400";
  };

  # Use the decrypted secret path in your config.
  users.users.myuser = {
    isNormalUser = true;
    # Point to the decrypted password file instead of using initialPassword.
    hashedPasswordFile = config.age.secrets.userPassword.path;
    # config.age.secrets.userPassword.path resolves to /run/agenix/userPassword
  };
}
```

#### 5.5 Re-encrypting Secrets

When you add a new host or user key, re-encrypt all secrets so the new key can decrypt them:

```bash
nix run github:ryantm/agenix -- -r
```

---

### Phase 6: Installing with nixos-anywhere

This is the step where your declarative config becomes a running system.

#### 6.1 Prerequisites for This Step

- Your config repo is in a git repository
- All new files are staged (`git add .`)
- The target machine is booted into a NixOS minimal ISO (or any Linux with SSH access and 1GB+ RAM)
- You know the target machine's IP address
- You can SSH into the target as root (the NixOS ISO allows this by default after setting a password with `passwd`)

#### 6.2 Test in a VM First

Before touching real hardware, validate your config in a virtual machine. nixos-anywhere can build and boot a QEMU VM with your config:

```bash
# From your config repo root:
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myhostname \
  --vm-test

# This builds and runs a QEMU VM. If it boots successfully,
# your config is structurally sound.
```

#### 6.3 Set SSH Access on the Target

On the target machine (booted into NixOS ISO), set a root password so nixos-anywhere can connect:

```bash
# On the target machine:
passwd   # sets root password
ip a     # note the IP address
```

Or, if you have an SSH key and the ISO has it loaded, skip the password step.

#### 6.4 Run the Installation

From your workstation (not the target machine):

```bash
# Basic install (config already has hardware-configuration.nix placeholder):
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myhostname \
  root@<TARGET-IP>

# If you DON'T have hardware-configuration.nix yet, generate it on the fly:
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myhostname \
  --generate-hardware-config nixos-generate-config ./hosts/myhostname/hardware-configuration.nix \
  root@<TARGET-IP>
```

**What happens during installation:**
1. nixos-anywhere SSHes into the target as root
2. It uploads a kexec environment and reboots the target into a minimal NixOS RAM disk
3. disko runs and partitions/formats the disk according to your `disk-config.nix`
4. nixos-install installs your system closure from the Nix store
5. The target reboots into your new NixOS system

The entire process takes 5-20 minutes depending on network speed and config complexity.

#### 6.5 Commit hardware-configuration.nix

If you used `--generate-hardware-config`, the file was written to your local repo. Commit it:

```bash
git add hosts/myhostname/hardware-configuration.nix
git commit -m "add hardware-configuration for myhostname"
git push
```

---

### Phase 7: First Boot Checklist

After the target reboots into NixOS, go through this checklist:

#### 7.1 Verify Basic Functionality

```bash
# SSH into the new system as your user:
ssh myuser@<TARGET-IP>

# Check NixOS version:
nixos-version

# Check your current generation:
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Check systemd services:
systemctl status

# Check failed services:
systemctl --failed

# Check journal for errors:
journalctl -p err -b
```

#### 7.2 Set Your Password

If you used `initialPassword = "changeme"`, change it immediately:

```bash
passwd
```

#### 7.3 Test Rollback (Important!)

The ability to roll back is one of NixOS's most powerful features. Test it now before you need it:

```bash
# List available generations:
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to the previous generation:
sudo nixos-rebuild switch --rollback

# Or rollback to a specific generation:
sudo nix-env --switch-generation 1 --profile /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch

# Roll forward again (apply your current config):
sudo nixos-rebuild switch --flake /path/to/your/config#myhostname
```

You can also rollback at boot time — the GRUB/systemd-boot menu shows all generations.

#### 7.4 Verify Secrets (if using agenix)

```bash
# Check that decrypted secrets exist at runtime:
ls -la /run/agenix/

# Check the age of secrets activation:
systemctl status agenix.service
```

---

### Phase 8: Day-to-Day Operations

#### 8.1 The Basic Workflow

Every change to your system follows this loop:

```
Edit .nix file → git add → Test → Apply
```

```bash
# 1. Edit your config
vim modules/nixos/networking.nix

# 2. Stage changes (required for flakes to see new/changed files)
git add -A

# 3. Test the build without applying (catches syntax errors)
sudo nixos-rebuild build --flake .#myhostname

# 4. Test the new config without making it the boot default
sudo nixos-rebuild test --flake .#myhostname

# 5. Apply and make it the boot default
sudo nixos-rebuild switch --flake .#myhostname

# 6. Commit once you're satisfied
git commit -m "update networking config"
```

#### 8.2 Updating the System

Updating NixOS means updating your flake inputs (the nixpkgs version pin):

```bash
# Update all inputs to their latest versions:
nix flake update

# Or update a single input:
nix flake update nixpkgs

# Then rebuild to apply the updates:
sudo nixos-rebuild switch --flake .#myhostname

# Commit the updated lockfile:
git add flake.lock
git commit -m "update flake inputs $(date +%Y-%m-%d)"
```

> **Tip:** `nix flake update` only updates `flake.lock`. Your `flake.nix` is unchanged. The lockfile pins every input to an exact git commit hash — reproducibility guaranteed.

#### 8.3 Adding a Package

**System-wide package** (available to all users):

```nix
# In hosts/myhostname/default.nix or a NixOS module
environment.systemPackages = with pkgs; [
  # ... existing packages ...
  firefox
];
```

**User package** (available only to myuser):

```nix
# In home/myuser/home.nix
home.packages = with pkgs; [
  # ... existing packages ...
  firefox
];
```

**Searching for packages:**

```bash
# Search nixpkgs directly:
nix search nixpkgs firefox

# Or use the web UI:
# https://search.nixos.org/packages
```

#### 8.4 Garbage Collection

Old generations accumulate in the Nix store. Clean them up:

```bash
# Delete system generations older than 30 days:
sudo nix-collect-garbage --delete-older-than 30d

# Delete all old system generations (keep only current):
sudo nix-collect-garbage -d

# Also clean user profiles:
nix-collect-garbage --delete-older-than 30d

# Check Nix store size before/after:
du -sh /nix/store
```

Automatic garbage collection is configured in Phase 3.1 (`nix.gc`).

#### 8.5 Checking What Changed Between Generations

```bash
# Show diff between generations 1 and 2:
nix store diff-closures \
  /nix/var/nix/profiles/system-1-link \
  /nix/var/nix/profiles/system-2-link

# Show diff between current and previous:
nix store diff-closures \
  /nix/var/nix/profiles/system-1-link \
  /nix/var/nix/profiles/system
```

#### 8.6 Applying Config from Anywhere (Remote)

If your config is in a git repo, you can apply it to the target machine without being physically present:

```bash
# Apply config from a remote git repo directly:
sudo nixos-rebuild switch \
  --flake "github:yourusername/nixos-config#myhostname"

# Apply to a remote machine from your workstation:
sudo nixos-rebuild switch \
  --flake .#myhostname \
  --target-host myuser@<TARGET-IP> \
  --build-host localhost  # builds on your workstation, sends result
```

#### 8.7 Common nixos-rebuild Commands Summary

| Command | What it does |
|---|---|
| `nixos-rebuild switch` | Build, activate, set as boot default |
| `nixos-rebuild test` | Build and activate, but do NOT set as boot default. Safe to test. |
| `nixos-rebuild boot` | Build and set as boot default, but do NOT activate now |
| `nixos-rebuild build` | Build only. Check for errors without changing anything. |
| `nixos-rebuild build-vm` | Build and run a QEMU VM with your config |
| `nixos-rebuild switch --rollback` | Activate the previous generation |
| `nixos-rebuild repl` | Open a REPL with your config loaded for inspection |

---

### Phase 9: Advanced Next Steps

These are not required for a working system but are the natural next steps as you get comfortable.

#### 9.1 Multiple Hosts in One Flake

As you add more machines, add them to `nixosConfigurations` in `flake.nix`:

```nix
nixosConfigurations = {
  desktop    = nixpkgs.lib.nixosSystem { ... };
  laptop     = nixpkgs.lib.nixosSystem { ... };
  homeserver = nixpkgs.lib.nixosSystem { ... };
};
```

Share common modules across hosts, override per-host as needed. This is the modular pattern's main benefit.

#### 9.2 Automatic Deployment with deploy-rs

For updating remote machines with automatic rollback on failure:

```bash
# Add to flake.nix inputs:
# deploy-rs.url = "github:serokell/deploy-rs";

# Define deployment in flake.nix outputs:
# deploy.nodes.myhostname = {
#   hostname = "192.168.1.100";
#   profiles.system = {
#     user = "root";
#     path = deploy-rs.lib.x86_64-linux.activate.nixos
#       self.nixosConfigurations.myhostname;
#   };
# };

# Deploy:
nix run github:serokell/deploy-rs -- .#myhostname
```

deploy-rs automatically rolls back if the activation fails or if SSH connection drops (the "magic rollback" feature).

#### 9.3 Impermanence — Ephemeral Root

The impermanence pattern wipes `/` on every reboot. Since NixOS only needs `/nix` and `/boot`, everything else is ephemeral unless explicitly declared.

```nix
# Add to inputs: impermanence.url = "github:nix-community/impermanence";
# Add to modules: inputs.impermanence.nixosModules.impermanence

# Then declare what persists:
environment.persistence."/persist" = {
  hideMounts = true;
  directories = [
    "/var/log"
    "/var/lib/bluetooth"
    "/var/lib/nixos"
    "/var/lib/systemd/coredump"
    "/etc/NetworkManager/system-connections"
  ];
  files = [
    "/etc/machine-id"
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
  ];
};
```

Benefit: Your system is always in an exactly known state. Configuration drift becomes impossible.

#### 9.4 Toward the Dendritic Pattern

Once you understand the modular pattern, you can evolve toward dendritic:

1. Add `flake-parts` as an input and restructure `flake.nix` to use `mkFlake`
2. Add `vic/import-tree` to auto-load modules — eliminates manual `imports = [...]`
3. Define top-level flake-parts options for values shared across NixOS/home-manager
4. Stop using `specialArgs`/`extraSpecialArgs` — pass values via flake-parts options instead

Start with: [mightyiam/dendritic](https://github.com/mightyiam/dendritic) and [fbosch/nixos](https://github.com/fbosch/nixos) as reference configs.

#### 9.5 Maintaining `flake.lock`

Your `flake.lock` pins every input to an exact revision. This means:

- **Reproducibility**: running `nixos-rebuild switch` on any machine with the same lock gives the same result
- **Auditability**: you can see exactly what changed in each `nix flake update`
- **Safety**: updates only happen when you explicitly run `nix flake update`

Always commit `flake.lock`. Think of it like `package-lock.json` or `Cargo.lock`.

---

### Quick Reference: File Checklist

Before running nixos-anywhere, verify you have all required files:

```
nixos-config/
├── flake.nix                                ✓ required
├── hosts/myhostname/default.nix             ✓ required
├── hosts/myhostname/disk-config.nix         ✓ required (disko)
├── hosts/myhostname/hardware-configuration.nix  ← generated by nixos-anywhere
├── modules/nixos/boot.nix                   ✓ required
├── modules/nixos/networking.nix             ✓ required
├── modules/nixos/users.nix                  ✓ required
├── modules/nixos/locale.nix                 ✓ required
├── home/myuser/home.nix                     ✓ required (if using home-manager)
├── home/myuser/shell.nix                    ✓ required (imported from home.nix)
├── home/myuser/git.nix                      ✓ required (imported from home.nix)
├── home/myuser/editor.nix                   ✓ required (imported from home.nix)
└── secrets/secrets.nix                      ✓ required (if using agenix)
```

**Before every build:**
```bash
git add -A   # always! flakes only see tracked files
```

### Quick Reference: Troubleshooting

| Problem | Likely cause | Fix |
|---|---|---|
| `error: file 'xxx' was not found` | New file not git-tracked | `git add` the file |
| Build fails with syntax error | Nix syntax error | Check with `nix-instantiate --parse file.nix` |
| `nixos-anywhere` fails: `kexec` error | Target has <1GB RAM | Add RAM, or use traditional install |
| Secret not decrypted | Host key not in `secrets.nix` | Add host pubkey, re-encrypt with `agenix -r` |
| Wrong disk device in disko | `device` in disk-config.nix is wrong | Check with `lsblk` on target before install |
| Boot fails after install | Bootloader config error | Boot from ISO, mount, fix `boot.nix`, reinstall |
| Package not found | Wrong package name | Search: `nix search nixpkgs <name>` |
| Home manager conflict | System and user config conflict | Check `home-manager.useGlobalPkgs` setting |
