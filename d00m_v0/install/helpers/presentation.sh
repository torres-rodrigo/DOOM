# Terminal presentation helpers: colors, logo, step indicators, padding.
# Sourced by all install scripts for consistent visual output.

export TERM_WIDTH=${COLUMNS:-80}
export TERM_HEIGHT=${LINES:-24}

# ── ANSI colors ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Logo ──────────────────────────────────────────────────────────────────────
# Quoted heredoc handles single quotes, backticks and backslashes literally.
# `read -d ''` reads until NUL/EOF and returns 1 at EOF; || true suppresses
# that so set -e does not abort the script.
read -r -d '' DOOM_LOGO << 'HEREDOC' || true

  =================     ===============     ===============   ========  ========
  \\ . . . . . . .\\   //. . . . . . .\\   //. . . . . . .\\  \\. . .\\// . . //
  ||. . ._____. . .|| ||. . ._____. . .|| ||. . ._____. . .|| || . . .\/ . . .||
  || . .||   ||. . || || . .||   ||. . || || . .||   ||. . || ||. . . . . . . ||
  ||. . ||   || . .|| ||. . ||   || . .|| ||. . ||   || . .|| || . | . . . . .||
  || . .||   ||. _-|| ||-_ .||   ||. . || || . .||   ||. _-|| ||-_.|\. . . . ||
  ||. . ||   ||-'  || ||  `-||   || . .|| ||. . ||   ||-'  || ||  `|\_ . .|. .||
  || . _||   ||    || ||    ||   ||_ . || || . _||   ||    || ||   |\ `-_/| . ||
  ||_-' ||  .|/    || ||    \|.  || `-_|| ||_-' ||  .|/    || ||   | \  / |-_.||
  ||    ||_-'      || ||      `-_||    || ||    ||_-'      || ||   | \  / |  `||
  ||    `'         || ||         `'    || ||    `'         || ||   | \  / |   ||
  ||            .===' `===.         .==='.`===.         .===' /==. |  \/  |   ||
  ||         .=='   \_|-_ `===. .==='   _|_   `===. .===' _-|/   `==  \/  |   ||
  ||      .=='    _-'    `-_  `='    _-'   `-_    `='  _-'   `-_  /|  \/  |   ||
  ||   .=='    _-'          `-__\._-'         `-_./__-'         `' |. /|  |   ||
  ||.=='    _-'                                                     `' |  /==.||
  =='    _-'                                                            \/   `==
  \   _-'                                                                `-_   /
  `''                                                                      ``'
  Arch Linux Desktop
HEREDOC

export LOGO_WIDTH=80
export LOGO_HEIGHT=21
export PADDING_LEFT=4
export PADDING_LEFT_SPACES="    "

# ── Functions ─────────────────────────────────────────────────────────────────
print_logo() {
  echo -e "${CYAN}${DOOM_LOGO}${RESET}"
  echo
}

clear_logo() {
  clear
}

# Primary step indicator — shown for each major install step
print_step() {
  echo -e "${PADDING_LEFT_SPACES}${BOLD}${GREEN}==>${RESET} ${BOLD}$1${RESET}"
}

# Informational sub-message
print_info() {
  echo -e "${PADDING_LEFT_SPACES}${CYAN}   →${RESET} $1"
}

# Non-fatal warning
print_warn() {
  echo -e "${PADDING_LEFT_SPACES}${YELLOW}  !${RESET} $1"
}

# Error message (does not exit by itself)
print_error() {
  echo -e "${PADDING_LEFT_SPACES}${RED}  ✗${RESET} $1"
}

show_cursor() {
  printf "\033[?25h"
}

hide_cursor() {
  printf "\033[?25l"
}
