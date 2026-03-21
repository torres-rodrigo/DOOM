# Install log helpers.
# run_logged() shows a gum spinner while each subscript runs and captures all
# output to $DOOM_INSTALL_LOG_FILE. start/stop_log_output are no-ops kept for
# call-site compatibility.

start_log_output() { :; }
stop_log_output()  { :; }

start_install_log() {
  touch "$DOOM_INSTALL_LOG_FILE"
  export DOOM_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
  echo "=== doom_v0 Installation Started: $DOOM_START_TIME ===" >> "$DOOM_INSTALL_LOG_FILE"
  start_log_output
}

stop_install_log() {
  stop_log_output
  show_cursor

  if [[ -n ${DOOM_INSTALL_LOG_FILE:-} ]]; then
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "=== doom_v0 Installation Completed: $end_time ===" >> "$DOOM_INSTALL_LOG_FILE"

    if [[ -n ${DOOM_START_TIME:-} ]]; then
      local start_epoch=$(date -d "$DOOM_START_TIME" +%s)
      local end_epoch=$(date -d "$end_time" +%s)
      local duration=$(( end_epoch - start_epoch ))
      local mins=$(( duration / 60 ))
      local secs=$(( duration % 60 ))
      echo "=== Total install time: ${mins}m ${secs}s ===" >> "$DOOM_INSTALL_LOG_FILE"
    fi
  fi
}

# Run a subscript in a logged subshell.
# All stdout and stderr from the subscript go to the log file.
# Shows a gum spinner while running; falls back to silent logging if gum is
# not yet available (e.g. before pacman.sh installs it).
run_logged() {
  local script="$1"
  local title
  title="$(basename "$script" .sh)"
  export CURRENT_SCRIPT="$script"

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: $script" >> "$DOOM_INSTALL_LOG_FILE"

  if command -v gum &>/dev/null; then
    gum spin --spinner dot --title "    $title" -- \
      bash -c "source \"$script\" >> \"$DOOM_INSTALL_LOG_FILE\" 2>&1"
  else
    bash -c "source \"$script\"" >> "$DOOM_INSTALL_LOG_FILE" 2>&1
  fi

  local exit_code=$?

  if (( exit_code == 0 )); then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed: $script" >> "$DOOM_INSTALL_LOG_FILE"
    unset CURRENT_SCRIPT
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: $script (exit code: $exit_code)" >> "$DOOM_INSTALL_LOG_FILE"
  fi

  return $exit_code
}
