print_step "Deploying dotfiles"
run_logged $DOOM_INSTALL/config/dotfiles.sh

print_step "Installing utility scripts"
run_logged $DOOM_INSTALL/config/scripts.sh

print_step "Enabling user services"
run_logged $DOOM_INSTALL/config/services.sh

print_step "Setting default shell to Zsh"
run_logged $DOOM_INSTALL/config/shell/change-shell-to-zsh.sh

print_step "Detecting NVIDIA GPU"
run_logged $DOOM_INSTALL/config/hardware/nvidia-detect.sh

print_step "Enabling Bluetooth"
run_logged $DOOM_INSTALL/config/hardware/bluetooth.sh

print_step "Configuring power management"
run_logged $DOOM_INSTALL/config/hardware/laptop-detect.sh

print_step "Enabling network services"
run_logged $DOOM_INSTALL/config/hardware/network.sh

print_step "Setting up mango WM prerequisites"
run_logged $DOOM_INSTALL/config/hardware/mango.sh

print_step "Configuring firewall"
run_logged $DOOM_INSTALL/config/security/firewall.sh
