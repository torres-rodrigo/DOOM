# Error recovery system.
# When any install script fails (ERR trap), the installer pauses, shows
# context from the log, and lets the user choose what to do next.

ERROR_HANDLING=false

save_original_outputs() {
  exec 3>&1 4>&2
}

restore_outputs() {
  if [[ -e /proc/self/fd/3 ]] && [[ -e /proc/self/fd/4 ]]; then
    exec 1>&3 2>&4
  fi
}

show_log_tail() {
  if [[ -f $DOOM_INSTALL_LOG_FILE ]]; then
    local log_lines=$(( TERM_HEIGHT - LOGO_HEIGHT - 20 ))
    local max_line_width=$(( LOGO_WIDTH - 4 ))

    tail -n $log_lines "$DOOM_INSTALL_LOG_FILE" | while IFS= read -r line; do
      if (( ${#line} > max_line_width )); then
        line="${line:0:$max_line_width}..."
      fi
      echo -e "${PADDING_LEFT_SPACES}  ${line}"
    done
    echo
  fi
}

show_failed_script() {
  if [[ -n ${CURRENT_SCRIPT:-} ]]; then
    echo -e "${PADDING_LEFT_SPACES}Failed script: ${RED}$CURRENT_SCRIPT${RESET}"
  else
    local cmd="$BASH_COMMAND"
    local max=$(( LOGO_WIDTH - 4 ))
    if (( ${#cmd} > max )); then
      cmd="${cmd:0:$max}..."
    fi
    echo -e "${PADDING_LEFT_SPACES}Failed command: ${RED}$cmd${RESET}"
  fi
}

catch_errors() {
  [[ $ERROR_HANDLING == "true" ]] && return
  ERROR_HANDLING=true

  local exit_code=$?

  stop_log_output 2>/dev/null || true
  restore_outputs
  clear_logo
  show_cursor

  echo -e "\n${PADDING_LEFT_SPACES}${RED}${BOLD}doom_v0 installation stopped!${RESET}\n"
  show_log_tail
  show_failed_script
  echo

  local options=("Retry installation" "View full log" "Exit")
  if command -v gum &>/dev/null; then
    while true; do
      local choice
      choice=$(gum choose "${options[@]}" --header "What would you like to do?" --height 5 --padding "1 $PADDING_LEFT")
      case "$choice" in
        "Retry installation") bash "$DOOM_PATH/doom_install.sh"; break ;;
        "View full log")
          command -v less &>/dev/null && less "$DOOM_INSTALL_LOG_FILE" || tail -40 "$DOOM_INSTALL_LOG_FILE"
          ;;
        "Exit"|"") exit 1 ;;
      esac
    done
  else
    PS3="Choose: "
    select choice in "${options[@]}"; do
      case "$choice" in
        "Retry installation") bash "$DOOM_PATH/doom_install.sh"; break ;;
        "View full log") tail -40 "$DOOM_INSTALL_LOG_FILE" ;;
        "Exit") exit 1 ;;
      esac
    done
  fi
}

exit_handler() {
  local exit_code=$?
  if (( exit_code != 0 )) && [[ $ERROR_HANDLING != "true" ]]; then
    catch_errors
  else
    stop_log_output 2>/dev/null || true
    show_cursor
  fi
}

trap catch_errors ERR INT TERM
trap exit_handler EXIT

save_original_outputs
