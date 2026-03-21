# Phase 4 — Login / Boot
# Sets up the display manager (greetd auto-login) and boot splash (Plymouth).

print_step "Configuring auto-login (greetd)"
run_logged $DOOM_INSTALL/login/greetd.sh

print_step "Configuring boot splash (Plymouth)"
run_logged $DOOM_INSTALL/login/plymouth.sh
