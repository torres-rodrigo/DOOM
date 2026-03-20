# Podman Installation & Setup Guide
## A Beginner-Friendly, Step-by-Step Guide for Windows and Linux

---

## Table of Contents

1. [What is Podman? (And Why Should You Care?)](#1-what-is-podman-and-why-should-you-care)
2. [Key Concepts You Need to Know Before Starting](#2-key-concepts-you-need-to-know-before-starting)
3. [Installing Podman on Windows](#3-installing-podman-on-windows)
4. [Installing Podman on Linux](#4-installing-podman-on-linux)
5. [Verifying Your Installation](#5-verifying-your-installation)
6. [Your First Container — Hello World](#6-your-first-container--hello-world)
7. [Essential Podman Commands for Beginners](#7-essential-podman-commands-for-beginners)
8. [Troubleshooting Common Issues](#8-troubleshooting-common-issues)
9. [Next Steps](#9-next-steps)

---

## 1. What is Podman? (And Why Should You Care?)

### The Simple Explanation

Imagine you want to run a web server, a database, or any application — but you don't want to install it directly on your computer. You don't want it to conflict with other software, you don't want to mess with your system settings, and you want to be able to delete it cleanly when you're done.

**Containers** solve this problem. A container is like a lightweight, self-contained box that holds an application and everything it needs to run (libraries, settings, dependencies). You run the box, the app works, and when you're done, you delete the box — no mess left behind.

**Podman** is a tool that lets you create, run, and manage these containers. Think of it as a container engine — the software that powers and manages your containers.

### Podman vs Docker — What's the Difference?

You may have heard of **Docker**, which is the most popular container tool. Podman is a direct alternative. Here is why many people prefer Podman:

| Feature | Docker | Podman |
|---|---|---|
| Requires a background service (daemon) | Yes | No |
| Runs as root by default | Yes | No (rootless by default) |
| License | Partly commercial | Fully open source (Apache 2.0) |
| Docker compatibility | Native | Very high (mostly drop-in replacement) |
| Security | Lower (root daemon) | Higher (rootless architecture) |

The biggest difference: Docker requires a **daemon** — a background service that runs as the root (administrator) user on your system at all times. If that daemon has a bug or gets compromised, an attacker has root access to your machine.

Podman has **no daemon**. Each container runs as a normal process owned by your user account. This is called **rootless mode** and it is considered much safer. Podman was designed from the ground up with security in mind.

> **In short:** Podman does everything Docker does, is more secure, is fully open source, and for most use cases, you can use the exact same commands — just replace `docker` with `podman`.

---

## 2. Key Concepts You Need to Know Before Starting

Before you install anything, let's make sure you understand a few core concepts. This will make everything else much easier.

### Images

An **image** is a read-only template used to create containers. Think of it as a recipe or a blueprint. Images are stored in **registries** (like Docker Hub or Quay.io) and you download (pull) them to your machine.

Example: The `nginx` image is a blueprint for running the Nginx web server.

### Containers

A **container** is a running instance of an image. It's the actual live, working copy. You can create many containers from the same image — just like you can bake many cakes from the same recipe.

Containers are isolated from each other and from your host system. They have their own file system, their own network, and their own processes.

### Registries

A **registry** is a storage service for images — like a library or app store for containers. The most popular one is **Docker Hub** (`docker.io`). Podman uses multiple registries by default, including:

- `docker.io` — Docker Hub (the largest public registry)
- `quay.io` — Red Hat's registry
- `registry.fedoraproject.org` — Fedora's registry

### Volumes

When a container is deleted, all data inside it is lost. **Volumes** are a way to store data outside the container so it persists even when the container is removed. Think of a volume as an external hard drive plugged into your container.

### Ports

Your container runs in isolation, so by default nothing from the outside world can reach it. **Port mapping** lets you connect a port on your computer to a port inside the container. For example, mapping port `8080` on your machine to port `80` inside the container lets you visit `http://localhost:8080` in your browser and see what's running inside the container.

---

## 3. Installing Podman on Windows

### Why Windows Needs Extra Steps

Linux is the native home of containers — the underlying technologies (namespaces, cgroups) that make containers work are Linux kernel features. Windows does not have these natively.

To run containers on Windows, Podman creates a small **Linux virtual machine** (VM) running silently in the background. Your Podman commands run on Windows but are sent to this Linux VM to actually execute. This is similar to how Docker Desktop for Windows works.

This Linux VM is managed automatically by Podman — you don't need to configure it yourself.

### System Requirements for Windows

Before you begin, make sure your system meets these requirements:

- **OS:** Windows 10 version 1903 or later (64-bit), or Windows 11
- **RAM:** At least 4 GB (8 GB or more recommended)
- **CPU:** 64-bit processor with virtualization support
- **Virtualization must be enabled** in your BIOS/UEFI settings (most modern machines have this on by default)
- **WSL 2** (Windows Subsystem for Linux 2) must be available

To check your Windows version, press `Win + R`, type `winver`, and press Enter.

### Step 1 — Enable WSL 2 (Windows Subsystem for Linux)

WSL 2 is a feature built into Windows that allows you to run a real Linux kernel inside Windows. Podman uses it to run containers.

**Option A — Using PowerShell (Recommended)**

1. Open **PowerShell as Administrator**:
   - Press `Win` key, type `PowerShell`
   - Right-click on "Windows PowerShell" and select **"Run as administrator"**
   - Click **Yes** when asked

2. Run this single command:

```powershell
wsl --install
```

This command will:
- Enable the WSL feature
- Enable the Virtual Machine Platform feature
- Download and install the default Linux distribution (Ubuntu)
- Install WSL 2

3. **Restart your computer** when prompted. This is required.

**Option B — Manual steps (if Option A fails)**

If the above doesn't work, do it step by step:

```powershell
# Step 1: Enable WSL
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

# Step 2: Enable Virtual Machine Platform
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Restart your computer, then open PowerShell as Administrator again:

```powershell
# Step 3: Set WSL 2 as the default version
wsl --set-default-version 2
```

**Verify WSL is installed correctly:**

```powershell
wsl --version
```

You should see version information. If you see `WSL version: 2.x.x`, you're good.

### Step 2 — Download the Podman Installer

1. Open your web browser and go to the official Podman GitHub releases page:
   `https://github.com/containers/podman/releases/latest`

2. Scroll down to the **Assets** section.

3. Find and download the file named something like:
   `podman-v5.x.x-setup.exe`
   (where `5.x.x` is the version number — download the latest available)

   > **Why the official source?** Always download software from official sources. The GitHub releases page is the official, verified source for Podman. This protects you from downloading tampered or malicious software.

### Step 3 — Run the Podman Installer

1. Open your **Downloads** folder and double-click the `podman-v5.x.x-setup.exe` file.

2. If Windows shows a security warning saying "Windows protected your PC", click **"More info"** then **"Run anyway"**. This happens because the installer is not from the Windows Store, but it is safe — you downloaded it from the official GitHub repository.

3. Follow the installation wizard:
   - Click **Next** on the welcome screen
   - Accept the license agreement
   - Choose the installation directory (the default `C:\Program Files\RedHat\Podman` is fine)
   - Click **Install**

4. Wait for the installation to complete, then click **Finish**.

### Step 4 — Initialize the Podman Machine

Now that Podman is installed, you need to create and start the Linux virtual machine that will run your containers. This is done with the `podman machine` commands.

Open a new **Command Prompt** or **PowerShell** window (regular, not as Administrator — this is important for rootless operation).

**Initialize the machine** (this downloads the Linux image — may take a few minutes depending on your internet connection):

```powershell
podman machine init
```

What this does: Creates a new virtual machine configuration with sensible defaults (1 CPU, 2GB RAM, 100GB disk). The machine is named `podman-machine-default`.

**Start the machine:**

```powershell
podman machine start
```

You should see output like:
```
Starting machine "podman-machine-default"
...
Machine "podman-machine-default" started successfully
```

**Check the machine status:**

```powershell
podman machine list
```

You should see your machine listed with a `*` next to it (indicating it's the active machine) and its state as `Running`.

### Step 5 — Verify the Installation on Windows

```powershell
podman --version
```

Expected output (version number will vary):
```
podman version 5.x.x
```

```powershell
podman info
```

This shows detailed information about your Podman setup. If it runs without errors, your installation is working.

### Useful Machine Management Commands (Windows)

```powershell
# Stop the machine (when you're done for the day)
podman machine stop

# Start the machine again
podman machine start

# See all machines
podman machine list

# Remove a machine completely (destructive — all containers inside will be lost)
podman machine rm
```

> **Tip:** You can set Podman Machine to start automatically with Windows. During `podman machine init` you can add the `--now` flag, but for automatic startup on boot, this requires additional configuration. For most beginners, manually starting the machine when needed is perfectly fine.

---

## 4. Installing Podman on Linux

### Why Linux Installation is Simpler

Since containers use Linux kernel features, running Podman on Linux is straightforward — there's no virtual machine needed. Podman runs directly on your system.

The installation steps vary slightly depending on your Linux distribution. Follow the section that matches your system.

---

### 4.1 — Ubuntu / Debian (and derivatives like Linux Mint, Pop!_OS)

Ubuntu and Debian use the **APT** package manager. Podman is included in the official repositories for Ubuntu 20.10 and later, but the version may be outdated. We will add the official Kubic repository to get the latest version.

**Step 1 — Update your package list**

Always update your package list before installing anything. This ensures you're getting the latest available packages:

```bash
sudo apt update
```

> `sudo` means "run as superuser (administrator)". You'll be prompted for your password.

**Step 2 — Install required dependencies**

```bash
sudo apt install -y curl gnupg
```

- `curl` — a tool to download files from the internet
- `gnupg` — used to verify the authenticity of the repository using cryptographic signatures

**Step 3 — Add the official Podman repository**

For **Ubuntu 22.04 (Jammy)** and later:

```bash
# Create the directory for apt keyrings if it doesn't exist
sudo mkdir -p /etc/apt/keyrings

# Download and add the repository's GPG key
curl -fsSL "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/unstable/xUbuntu_$(lsb_release -rs)/Release.key" \
  | gpg --dearmor \
  | sudo tee /etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg > /dev/null

# Add the repository to your sources list
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/devel_kubic_libcontainers_unstable.gpg] \
  https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/unstable/xUbuntu_$(lsb_release -rs)/ /" \
  | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list > /dev/null
```

> **Why add a separate repository?** The version of Podman in Ubuntu's default repositories can be months or years behind. Adding the Kubic repository gives you the latest stable Podman release with all current features and bug fixes.

> **What is a GPG key?** It's a cryptographic signature that proves the packages in this repository were actually created by the repository owners, and haven't been tampered with. This is how Linux verifies software authenticity.

**Step 4 — Update package list and install Podman**

```bash
sudo apt update
sudo apt install -y podman
```

**Alternative: Install from Ubuntu's default repositories (simpler but older version)**

If you're on Ubuntu 22.04+ and just want a quick install without adding extra repositories:

```bash
sudo apt update
sudo apt install -y podman
```

This will install Podman but possibly an older version. Check the version with `podman --version` afterwards.

---

### 4.2 — Fedora

Fedora ships with Podman available in its default repositories, and often has the latest version.

**Step 1 — Update your system**

```bash
sudo dnf update -y
```

> Fedora uses **DNF** as its package manager.

**Step 2 — Install Podman**

```bash
sudo dnf install -y podman
```

That's it. Fedora makes this very simple.

---

### 4.3 — RHEL / CentOS Stream / AlmaLinux / Rocky Linux

These distributions are enterprise-focused and use DNF (or YUM for older versions).

**For RHEL 9 / CentOS Stream 9 / AlmaLinux 9 / Rocky Linux 9:**

```bash
sudo dnf install -y podman
```

**For RHEL 8 / CentOS Stream 8 / AlmaLinux 8 / Rocky Linux 8:**

```bash
# Enable the container-tools module
sudo dnf module enable -y container-tools:rhel8

# Install Podman
sudo dnf install -y podman
```

> On RHEL 8-based systems, Podman is part of the `container-tools` module. Enabling the module ensures you get all related tools together.

---

### 4.4 — Arch Linux / Manjaro

Arch Linux uses **Pacman** as its package manager.

```bash
sudo pacman -Sy podman
```

> `Sy` means "synchronize package databases and install". Arch usually has very up-to-date packages.

---

### 4.5 — openSUSE Tumbleweed / Leap

openSUSE uses **Zypper** as its package manager.

**For Tumbleweed (rolling release):**

```bash
sudo zypper install podman
```

**For Leap:**

```bash
sudo zypper install podman
```

---

### Step — Enable Rootless Containers on Linux (Important!)

After installation, there's one important configuration step to ensure rootless containers work properly. This allows your user account to run containers without needing root privileges.

**Check if you have sufficient subordinate UID/GID ranges:**

```bash
cat /etc/subuid
cat /etc/subgid
```

You should see a line with your username, like:
```
yourusername:100000:65536
```

If you don't see your username listed, add it:

```bash
# Replace "yourusername" with your actual username
sudo usermod --add-subuids 100000-165535 yourusername
sudo usermod --add-subgids 100000-165535 yourusername
```

> **Why do we need this?** Rootless containers work by mapping user IDs inside the container to a range of IDs outside the container. The `subuid` and `subgid` files define what ranges your user is allowed to use. Without this, containers can't properly isolate their user namespaces.

**After making changes, reload the configuration:**

```bash
podman system migrate
```

---

## 5. Verifying Your Installation

Regardless of whether you're on Windows or Linux, run these commands to confirm everything is working:

### Check Podman Version

```bash
podman --version
```

Expected output (your version number will differ):
```
podman version 5.3.1
```

### Check System Information

```bash
podman info
```

This prints detailed information about your Podman setup including:
- The host operating system
- Storage configuration
- Network configuration
- Security settings

If this command runs without errors, Podman is properly installed and configured.

### Run a Quick Test

```bash
podman run hello-world
```

This command:
1. Looks for the `hello-world` image locally
2. Since it's not there yet, downloads it from Docker Hub
3. Creates a container from that image
4. Runs the container (which just prints a hello message)
5. Stops the container

If you see a message like:
```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

...then everything is working perfectly.

---

## 6. Your First Container — Hello World

Let's explore what actually happens when you run a container, step by step.

### Running Your First Real Container

Let's run a simple web server. We'll use **Nginx**, which is a very popular, lightweight web server.

```bash
podman run -d -p 8080:80 --name my-first-webserver nginx
```

Let's break down exactly what this command means:

| Part | Meaning |
|---|---|
| `podman run` | Create and start a new container |
| `-d` | Run in **detached** mode (in the background, so it doesn't lock your terminal) |
| `-p 8080:80` | **Port mapping**: Connect port 8080 on your computer to port 80 inside the container |
| `--name my-first-webserver` | Give the container a friendly name so you can refer to it easily |
| `nginx` | The name of the image to use |

After running this, open your web browser and go to:
```
http://localhost:8080
```

You should see the **"Welcome to nginx!"** page. You just ran a web server in a container!

### See Your Running Containers

```bash
podman ps
```

This lists all currently running containers. You should see `my-first-webserver` listed.

### See the Container's Logs

```bash
podman logs my-first-webserver
```

This shows the output from your container — every request that has been made to the web server.

### Stop the Container

```bash
podman stop my-first-webserver
```

The container is now stopped. The Nginx web server is no longer running. If you try to visit `http://localhost:8080` in your browser, it will fail to connect.

### Start It Again

```bash
podman start my-first-webserver
```

The same container starts again from where it was. Visit `http://localhost:8080` and it works again.

### Remove the Container

When you're completely done and want to clean up:

```bash
podman stop my-first-webserver
podman rm my-first-webserver
```

> You must stop a container before you can remove it (unless you use `podman rm -f` to force-remove it while running).

---

## 7. Essential Podman Commands for Beginners

Here are the commands you'll use most often, organized by category.

### Working with Images

```bash
# Search for an image on Docker Hub
podman search ubuntu

# Download (pull) an image without running it
podman pull ubuntu:22.04

# List all images stored locally on your machine
podman images

# Remove an image from your machine
podman rmi ubuntu:22.04

# Remove all unused images (frees up disk space)
podman image prune
```

### Working with Containers

```bash
# Run a container interactively (get a terminal inside it)
# -it means: interactive + allocate a terminal
# --rm means: automatically remove the container when it exits
podman run -it --rm ubuntu:22.04 bash

# List running containers
podman ps

# List ALL containers (including stopped ones)
podman ps -a

# Start a stopped container
podman start container_name

# Stop a running container (gracefully — gives it time to shut down)
podman stop container_name

# Force-stop a container immediately
podman kill container_name

# Remove a container
podman rm container_name

# Remove all stopped containers
podman container prune
```

### Inspecting and Debugging Containers

```bash
# View the logs (output) of a container
podman logs container_name

# Follow logs in real time (like tail -f)
podman logs -f container_name

# Execute a command inside a running container
# This is very useful for debugging!
podman exec -it container_name bash

# See resource usage (CPU, memory) of running containers
podman stats

# See detailed information about a container
podman inspect container_name

# See the processes running inside a container
podman top container_name
```

### Working with Volumes (Persistent Storage)

```bash
# Create a named volume
podman volume create my-data

# List all volumes
podman volume ls

# Run a container with a named volume
# The volume "my-data" is mounted at /data inside the container
podman run -d -v my-data:/data nginx

# Run a container with a bind mount (a folder from your computer)
# /home/user/myfiles on your computer maps to /data in the container
podman run -d -v /home/user/myfiles:/data nginx

# Remove a volume
podman volume rm my-data

# Remove all unused volumes
podman volume prune
```

### System Maintenance

```bash
# Show disk usage by containers, images, and volumes
podman system df

# Remove all unused containers, images, networks, and volumes
# (a full cleanup — useful when you want to start fresh)
podman system prune -a

# Show podman system information
podman info
```

---

## 8. Troubleshooting Common Issues

### Issue: "Cannot connect to Podman" on Windows

**Symptom:** Running any `podman` command gives an error like `error during connect` or `cannot connect`.

**Cause:** The Podman Machine (the Linux VM) is not running.

**Fix:**
```powershell
podman machine start
```

Wait for it to start and try your command again.

---

### Issue: "Permission denied" on Linux

**Symptom:** You get `permission denied` errors when running container commands.

**Cause:** Your user may not have the correct subordinate UID/GID mappings.

**Fix:**
```bash
# Check if your user is in /etc/subuid and /etc/subgid
grep $USER /etc/subuid
grep $USER /etc/subgid

# If not found, add them (replace "yourusername" with your actual username)
sudo usermod --add-subuids 100000-165535 $USER
sudo usermod --add-subgids 100000-165535 $USER

# Apply the changes
podman system migrate
```

---

### Issue: "Image not found" when pulling

**Symptom:** `podman pull myimage` gives an error like `image not known`.

**Cause:** Podman may not be searching the right registry, or the image name might be wrong.

**Fix:**
```bash
# Try specifying the full registry path
podman pull docker.io/library/nginx

# Or search for the correct image name first
podman search nginx
```

---

### Issue: Port already in use

**Symptom:** `Error: address already in use` when mapping a port.

**Cause:** Something else on your computer is already using that port.

**Fix:** Either stop the conflicting service or use a different port:
```bash
# Instead of 8080, use 8081 (or any unused port)
podman run -d -p 8081:80 nginx
```

To find what's using a port on Linux:
```bash
sudo ss -tlnp | grep 8080
```

On Windows (PowerShell):
```powershell
netstat -ano | findstr :8080
```

---

### Issue: Container exits immediately

**Symptom:** You run `podman run myimage` and the container immediately stops.

**Cause:** The container's main process finished and exited. Some images (like `ubuntu`) don't run a long-running process by default.

**Fix:** Run interactively to explore:
```bash
podman run -it ubuntu bash
```

Or check the container logs to see what happened:
```bash
podman logs container_name
```

---

### Issue: "No space left on device"

**Symptom:** Operations fail with storage-related errors.

**Fix:** Clean up unused images, containers, and volumes:
```bash
# Remove unused containers
podman container prune

# Remove unused images
podman image prune -a

# Remove unused volumes
podman volume prune

# Or do everything at once
podman system prune -a --volumes
```

---

## 9. Next Steps

Now that you have Podman installed and working, here's what to explore next:

### Learn About Containerfiles (Dockerfiles)

A **Containerfile** (also called a **Dockerfile** — they're compatible) lets you build your own custom images. Instead of using pre-made images from registries, you define exactly what goes into your container.

Simple example — create a file named `Containerfile`:

```dockerfile
# Start from an Ubuntu base image
FROM ubuntu:22.04

# Update packages and install Python
RUN apt update && apt install -y python3

# Copy your application into the container
COPY myapp.py /app/myapp.py

# Define the command to run when the container starts
CMD ["python3", "/app/myapp.py"]
```

Build it with:
```bash
podman build -t myapp:latest .
```

Run it with:
```bash
podman run myapp:latest
```

### Learn About Podman Compose

**Podman Compose** lets you define and run multi-container applications (e.g., a web server + a database + a cache) using a single YAML file. It's compatible with Docker Compose files.

Install it:
```bash
# On Linux with pip
pip3 install podman-compose

# On Windows with pip
pip install podman-compose
```

### Explore Podman Desktop

**Podman Desktop** is a graphical user interface (GUI) for Podman. If you prefer visual tools over the command line, download it from `https://podman-desktop.io`.

It provides:
- Visual management of images, containers, and volumes
- Built-in terminal
- Extension support for Kubernetes and more

### Useful Learning Resources

- **Official Podman documentation:** `https://docs.podman.io`
- **Podman GitHub repository:** `https://github.com/containers/podman`
- **Container image registry (Docker Hub):** `https://hub.docker.com`
- **Red Hat's free container registry:** `https://quay.io`
- **Podman Desktop:** `https://podman-desktop.io`

---

## Quick Reference Card

```
IMAGES
  podman search <name>          Search for images
  podman pull <image>           Download an image
  podman images                 List local images
  podman rmi <image>            Remove an image

CONTAINERS
  podman run -d -p 8080:80 -name <name> <image>    Run a container
  podman run -it --rm <image> bash                  Run interactively
  podman ps                     List running containers
  podman ps -a                  List all containers
  podman start <name>           Start a stopped container
  podman stop <name>            Stop a running container
  podman rm <name>              Remove a container
  podman logs <name>            View container output
  podman exec -it <name> bash   Get a shell inside container

VOLUMES
  podman volume create <name>   Create a volume
  podman volume ls              List volumes
  podman volume rm <name>       Remove a volume

SYSTEM
  podman info                   System information
  podman system df              Disk usage
  podman system prune -a        Clean up everything unused

WINDOWS ONLY (Machine Management)
  podman machine init           Create the Linux VM
  podman machine start          Start the Linux VM
  podman machine stop           Stop the Linux VM
  podman machine list           List all machines
```

---

*Guide created for Podman 5.x. Commands and steps may vary slightly for newer versions.*
*Always refer to the official documentation at https://docs.podman.io for the most current information.*
