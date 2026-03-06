#!/bin/bash
set -euo pipefail

echo "Configuring UFW firewall..."

# Ensure IPv6 support is enabled in UFW config
if grep -q '^IPV6=yes' /etc/default/ufw; then
    echo "IPv6 support already enabled in UFW"
else
    sudo sed -i 's/^IPV6=.*/IPV6=yes/' /etc/default/ufw
    echo "IPv6 support enabled in UFW"
fi

# Default policies: deny incoming, allow outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Block outbound SMTP (port 25 is MTA-to-MTA only; mail clients use 587/465)
sudo ufw deny out 25/tcp comment 'Block outbound SMTP'

# Allow LocalSend ports (only if LocalSend is installed)
if command -v localsend &>/dev/null; then
    echo "LocalSend detected - configuring firewall ports..."
    sudo ufw allow 53317/udp comment 'LocalSend'
    sudo ufw allow 53317/tcp comment 'LocalSend'
else
    echo "LocalSend not installed - skipping LocalSend ports"
fi

# Detect and configure Docker DNS if Docker is present
if command -v docker &>/dev/null; then
    echo "Docker detected - configuring firewall rules..."

    # Dynamically detect Docker bridge IP
    DOCKER_BRIDGE_IP=$(docker network inspect bridge -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null || echo "172.17.0.1")

    if [[ -n "$DOCKER_BRIDGE_IP" ]]; then
        echo "Using Docker bridge IP: $DOCKER_BRIDGE_IP"
        sudo ufw allow in proto udp from 172.16.0.0/12 to "$DOCKER_BRIDGE_IP" port 53 comment 'allow-docker-dns'
    else
        echo "Warning: Could not detect Docker bridge IP, using default 172.17.0.1"
        sudo ufw allow in proto udp from 172.16.0.0/12 to 172.17.0.1 port 53 comment 'allow-docker-dns'
    fi
fi

# Enable firewall
sudo ufw --force enable

# Enable logging at medium level (logs blocked packets and new allowed connections)
sudo ufw logging medium

# Configure log rotation for UFW logs
# On Arch with systemd-only, UFW logs are captured by journald.
# This config applies when a syslog daemon writes to /var/log/ufw.log.
printf '/var/log/ufw.log {\n    weekly\n    rotate 4\n    size 50M\n    missingok\n    notifempty\n    compress\n    delaycompress\n}\n' \
    | sudo tee /etc/logrotate.d/ufw > /dev/null
echo "UFW log rotation configured (weekly, 50M max, 4 weeks retained)"

# Configure journald retention (UFW logs live here on systemd-only systems)
if grep -q '^#*MaxRetentionSec=' /etc/systemd/journald.conf; then
    sudo sed -i 's/^#*MaxRetentionSec=.*/MaxRetentionSec=3weeks/' /etc/systemd/journald.conf
else
    sudo sed -i '/^\[Journal\]/a MaxRetentionSec=3weeks' /etc/systemd/journald.conf
fi
sudo systemctl restart systemd-journald
echo "Journald retention set to 3 weeks"

# Enable UFW service to start on boot
sudo systemctl enable ufw

# Install Docker protections if Docker is installed
if command -v docker &>/dev/null; then
    if command -v ufw-docker &>/dev/null; then
        echo "Installing ufw-docker protections..."
        if ! sudo ufw-docker install; then
            echo ""
            echo -e "\e[33m================================================\e[0m"
            echo -e "\e[33m  WARNING: ufw-docker install failed!\e[0m"
            echo -e "\e[33m  Docker container ports may bypass UFW rules,\e[0m"
            echo -e "\e[33m  exposing them to the network. Investigate\e[0m"
            echo -e "\e[33m  before using Docker on this system.\e[0m"
            echo -e "\e[33m================================================\e[0m"
            echo ""
        fi
        sudo ufw reload
    else
        echo "Warning: ufw-docker not found - Docker firewall bypass protection not installed"
        echo "Consider running: paru -S ufw-docker"
    fi
fi

echo "Firewall configured and enabled"
