# Real-time install log monitoring.
# A background process tails the log file and reprints the last N lines
# below the logo so the user can see live progress without scrolling.

start_log_output() {
  local ANSI_SAVE_CURSOR="\033[s"
  local ANSI_RESTORE_CURSOR="\033[u"
  local ANSI_CLEAR_LINE="\033[2K"
  local ANSI_HIDE_CURSOR="\033[?25l"
  local ANSI_RESET="\033[0m"
  local ANSI_GRAY="\033[90m"

  printf $ANSI_SAVE_CURSOR
  printf $ANSI_HIDE_CURSOR

  (
    local log_lines=18
    local max_line_width=$((LOGO_WIDTH - 4))

    while true; do
      mapfile -t current_lines < <(tail -n $log_lines "$DOOM_INSTALL_LOG_FILE" 2>/dev/null)

      output=""
      for ((i = 0; i < log_lines; i++)); do
        line="${current_lines[i]:-}"
        if (( ${#line} > max_line_width )); then
          line="${line:0:$max_line_width}..."
        fi
        if [[ -n $line ]]; then
          output+="${ANSI_CLEAR_LINE}${ANSI_GRAY}${PADDING_LEFT_SPACES}  → ${line}${ANSI_RESET}\n"
        else
          output+="${ANSI_CLEAR_LINE}${PADDING_LEFT_SPACES}\n"
        fi
      done

      printf "${ANSI_RESTORE_CURSOR}%b" "$output"
      sleep 0.1
    done
  ) &
  monitor_pid=$!
}

stop_log_output() {
  if [[ -n ${monitor_pid:-} ]]; then
    kill $monitor_pid 2>/dev/null || true
    wait $monitor_pid 2>/dev/null || true
    unset monitor_pid
  fi
}

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
