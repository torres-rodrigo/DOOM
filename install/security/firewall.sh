#!/bin/bash
set -euo pipefail

echo "Configuring UFW firewall..."

# Default policies: deny incoming, allow outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow LocalSend ports
sudo ufw allow 53317/udp comment 'LocalSend'
sudo ufw allow 53317/tcp comment 'LocalSend'

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

# Enable UFW service to start on boot
sudo systemctl enable ufw

# Install Docker protections if Docker is installed
if command -v docker &>/dev/null; then
    if command -v ufw-docker &>/dev/null; then
        echo "Installing ufw-docker protections..."
        sudo ufw-docker install || {
            echo "Warning: ufw-docker install failed"
        }
        sudo ufw reload
    else
        echo "Warning: ufw-docker not found - Docker firewall bypass protection not installed"
        echo "Consider running: paru -S ufw-docker"
    fi
fi

echo "Firewall configured and enabled"
