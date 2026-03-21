# Install log helpers.
#
# Layout:
#   ┌──────────────────────────────┐  ← scroll region (print_step, gum spinner)
#   │                              │
#   ├──────────────────────────────┤  ← separator (fixed)
#   │  → log line 1               │  ← log tail (fixed, absolute positioned)
#   │  → log line 2               │
#   └──────────────────────────────┘
#
# The scroll region covers the top portion of the terminal. The bottom
# _LOG_ROWS+1 lines are reserved for the live log tail and never scroll.
# The background monitor writes there using absolute positioning, so it never
# races with gum or print_step output in the scroll region.

_LOG_ROWS=8

start_log_output() {
  local term_h
  term_h=$(tput lines 2>/dev/null || echo 24)

  # Row indices (1-based, as terminals expect)
  local scroll_end=$(( term_h - _LOG_ROWS - 1 ))
  local sep_row=$(( term_h - _LOG_ROWS ))
  local log_start=$(( term_h - _LOG_ROWS + 1 ))

  # Export so the background subshell can read them
  export _LOG_SCROLL_END="$scroll_end"
  export _LOG_SEP_ROW="$sep_row"
  export _LOG_START_ROW="$log_start"

  # Save cursor position (right after the logo) before doing any absolute
  # positioning — restored at the end so print_step appears below the logo.
  printf "\033[s"

  # Set scroll region — only lines 1..$scroll_end scroll
  printf "\033[1;%dr" "$scroll_end"

  # Draw separator line
  local sep_line
  sep_line="$(printf '─%.0s' $(seq 1 "${TERM_WIDTH:-80}"))"
  printf "\033[%d;1H\033[2K\033[90m%s\033[0m" "$sep_row" "$sep_line"

  # Clear log area
  local i
  for (( i=0; i<_LOG_ROWS; i++ )); do
    printf "\033[%d;1H\033[2K" $(( log_start + i ))
  done

  # Restore cursor to just below the logo so output flows from there
  printf "\033[u"

  hide_cursor

  # Background monitor — writes log lines into the reserved bottom area.
  # Uses save/restore around each write so the cursor in the scroll region
  # (used by gum spin and print_step) is not left in the wrong place.
  (
    while true; do
      mapfile -t _lines < <(tail -n "$_LOG_ROWS" "$DOOM_INSTALL_LOG_FILE" 2>/dev/null)

      printf "\033[s"  # save cursor (in scroll region)

      local j
      for (( j=0; j<_LOG_ROWS; j++ )); do
        printf "\033[%d;1H\033[2K" $(( _LOG_START_ROW + j ))
        local line="${_lines[j]:-}"
        if [[ -n "$line" ]]; then
          printf "\033[90m    → %s\033[0m" "${line:0:$(( TERM_WIDTH - 8 ))}"
        fi
      done

      printf "\033[u"  # restore cursor to scroll region
      sleep 0.2
    done
  ) &
  monitor_pid=$!
}

stop_log_output() {
  if [[ -n ${monitor_pid:-} ]]; then
    kill "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true
    unset monitor_pid
  fi

  # Restore full-terminal scroll region and leave cursor at bottom
  printf "\033[r"
  tput cup "$(tput lines 2>/dev/null || echo 24)" 0
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
# Shows a gum spinner in the scroll region while the script runs.
# All stdout and stderr go to $DOOM_INSTALL_LOG_FILE (visible in the log tail).
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
