# Install log helpers.
#
# Output model:
#   - print_step()  prints the step name to the terminal (natural scroll)
#   - run_logged()  shows a gum spinner while each subscript runs and writes
#                   all stdout/stderr to $DOOM_INSTALL_LOG_FILE
#   - sudo prompts  reach the terminal via /dev/tty, unaffected by redirects
#   - start/stop_log_output are kept as no-ops for call-site compatibility

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

# Run a subscript in a logged subshell.
# Shows a gum spinner while the script runs; all output goes to the log file.
# sudo password prompts reach the terminal via /dev/tty regardless of the
# stdout/stderr redirect, so they are always visible.
# Falls back to silent logging if gum is not yet available.
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
