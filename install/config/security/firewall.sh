# Configure UFW firewall.
# Default policy: deny all incoming, allow all outgoing.

echo "Configuring firewall..."

# Ensure IPv6 is enabled in UFW
if ! grep -q '^IPV6=yes' /etc/default/ufw; then
  sudo sed -i 's/^IPV6=.*/IPV6=yes/' /etc/default/ufw
fi

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Block outbound SMTP — port 25 is MTA-to-MTA only; mail clients use 587/465
sudo ufw deny out 25/tcp comment 'Block outbound SMTP'

# Docker: allow containers to reach the host DNS resolver
if command -v docker &>/dev/null; then
  DOCKER_BRIDGE_IP=$(docker network inspect bridge -f '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null || echo "172.17.0.1")
  sudo ufw allow in proto udp from 172.16.0.0/12 to "$DOCKER_BRIDGE_IP" port 53 comment 'Docker DNS'
fi

# Enable the firewall
sudo ufw --force enable
sudo ufw logging medium
systemctl_enable ufw

# Configure UFW log rotation
printf '/var/log/ufw.log {\n    weekly\n    rotate 4\n    size 50M\n    missingok\n    notifempty\n    compress\n    delaycompress\n}\n' \
  | sudo tee /etc/logrotate.d/ufw >/dev/null

# Set journald retention so UFW logs don't grow unbounded
if grep -q '^#*MaxRetentionSec=' /etc/systemd/journald.conf; then
  sudo sed -i 's/^#*MaxRetentionSec=.*/MaxRetentionSec=3weeks/' /etc/systemd/journald.conf
else
  sudo sed -i '/^\[Journal\]/a MaxRetentionSec=3weeks' /etc/systemd/journald.conf
fi
sudo systemctl restart systemd-journald

# Apply ufw-docker protections if both Docker and ufw-docker are present
if command -v docker &>/dev/null && command -v ufw-docker &>/dev/null; then
  sudo ufw-docker install
  sudo ufw reload
fi

echo "Firewall: OK"
