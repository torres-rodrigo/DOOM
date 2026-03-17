print_step "Installing base packages"
run_logged $DOOM_INSTALL/packaging/base.sh

print_step "Installing laptop packages (if applicable)"
run_logged $DOOM_INSTALL/packaging/laptop.sh

print_step "Installing AUR packages"
run_logged $DOOM_INSTALL/packaging/aur.sh

print_step "Installing optional packages"
run_logged $DOOM_INSTALL/packaging/optional.sh
