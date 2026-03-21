# Install log helpers.
#
# All script output is shown live in the terminal AND written to the log file
# via tee. sudo password prompts and interactive selections are fully visible
# because nothing is suppressed or redirected away from the terminal.

start_log_output() { :; }
stop_log_output()  { :; }

start_install_log() {
  touch "$DOOM_INSTALL_LOG_FILE"
  export DOOM_START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
  echo "=== doom_v0 Installation Started: $DOOM_START_TIME ===" >> "$DOOM_INSTALL_LOG_FILE"
}

stop_install_log() {
  show_cursor

  if [[ -n ${DOOM_INSTALL_LOG_FILE:-} ]]; then
    local end_time
    end_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo "=== doom_v0 Installation Completed: $end_time ===" >> "$DOOM_INSTALL_LOG_FILE"

    if [[ -n ${DOOM_START_TIME:-} ]]; then
      local start_epoch end_epoch duration mins secs
      start_epoch=$(date -d "$DOOM_START_TIME" +%s)
      end_epoch=$(date -d "$end_time" +%s)
      duration=$(( end_epoch - start_epoch ))
      mins=$(( duration / 60 ))
      secs=$(( duration % 60 ))
      echo "=== Total install time: ${mins}m ${secs}s ===" >> "$DOOM_INSTALL_LOG_FILE"
    fi
  fi
}

# Run a subscript and show all its output live in the terminal.
# tee writes the same output to the log file simultaneously.
# sudo prompts and interactive selections are fully visible — nothing is hidden.
run_logged() {
  local script="$1"
  local title
  title="$(basename "$script" .sh)"
  export CURRENT_SCRIPT="$script"

  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting: $script" >> "$DOOM_INSTALL_LOG_FILE"

  bash -c "source \"$script\"" 2>&1 | tee -a "$DOOM_INSTALL_LOG_FILE"
  local exit_code=${PIPESTATUS[0]}

  if (( exit_code == 0 )); then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Completed: $script" >> "$DOOM_INSTALL_LOG_FILE"
    unset CURRENT_SCRIPT
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed: $script (exit code: $exit_code)" >> "$DOOM_INSTALL_LOG_FILE"
  fi

  return $exit_code
}
