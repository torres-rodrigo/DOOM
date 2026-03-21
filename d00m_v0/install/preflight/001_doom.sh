print_step "Validating system"
run_logged $DOOM_INSTALL/preflight/guard.sh

print_step "Initializing pacman"
run_logged $DOOM_INSTALL/preflight/pacman.sh

print_step "Loading checkpoints"
run_logged $DOOM_INSTALL/preflight/markers.sh

ECHO "PRE-FLIGHT CHECKS PASSED ✓"
