# Phase 5 — Post-install
# Final cleanup, then prompt to reboot into the finished system.

print_step "Cleaning up"
run_logged $DOOM_INSTALL/post-install/cleanup.sh

stop_install_log

echo ""
echo -e "    ${BOLD}${GREEN}doom_v0 installation complete.${RESET}"
echo ""

if command -v gum &>/dev/null; then
  gum confirm "Reboot now?" && sudo reboot || true
else
  read -rp "    Reboot now? [Y/n] " _ans
  [[ "${_ans,,}" != "n" ]] && sudo reboot
fi
