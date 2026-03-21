# Log output helpers — reserved for future gum-based spinner integration.
# The background ANSI monitor was removed: cursor save/restore races with
# foreground print_step() writes and produces garbled output.
# User feedback is provided by print_step() calls in the phase entry points.
# All subprocess output is still captured in $DOOM_INSTALL_LOG_FILE.

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
# On failure the ERR trap in errors.sh fires automatically.
run_logged() {
  local script="$1"
  export CURRENT_SCRIPT="$script"

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: $script" >> "$DOOM_INSTALL_LOG_FILE"

  bash -c "source '$script'" </dev/null >> "$DOOM_INSTALL_LOG_FILE" 2>&1

  local exit_code=$?

  if (( exit_code == 0 )); then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed: $script" >> "$DOOM_INSTALL_LOG_FILE"
    unset CURRENT_SCRIPT
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: $script (exit code: $exit_code)" >> "$DOOM_INSTALL_LOG_FILE"
  fi

  return $exit_code
}
