# Set dir to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source zinit
source "${ZINIT_HOME}/zinit.zsh"

# Plugins
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Load completions
autoload -U compinit && compinit

# Starship
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# Autosuggestions settings
mkdir -p "$XDG_STATE_HOME/zsh"
HISTSIZE=1000
HISTFILE="$XDG_STATE_HOME/zsh/.zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Keymaps
bindkey '^y' autosuggest-accept
bindkey '^g' autosuggest-accept
bindkey '^n' history-search-forward
bindkey '^p' history-search-backward
# Ctrl + a: Go to begining of prompt
# Ctrl + e: Go to end of prompt
# Ctrl + f: Go foward in prompt
# Ctrl + b: Go backwards in prompt

# Completion styling
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# FZF
source <(fzf --zsh)
# Ctrl + r: Command history
# Ctrl + t: Selector
# **<TAB>: Fuzzy Finding
# Alt + c: Directory switching

# DEFAULTS
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi

# ALIASES
alias v='nvim'
alias z='cd'
alias g='git'
alias lg='lazygit'
alias ls='eza -lha --icons'
alias sp='sudo pacman'
alias config='cd $HOME/.config/'
alias today='date "+%Y-%m-%d"'
alias dat='date "+%Y-%m-%d %H:%M:%S"' # date and time 

alias ld='cd -'                      # last dir
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ..l='cd .. && eza -lha --icons'         # go up one dir and list
alias ...l='cd ../.. && eza -lha --icons'
alias ....l='cd ../../.. && eza -lha --icons'

alias gf='git fetch'                                   # git fetch
alias gp='git pull'                                    # git pull
alias gaa='git add .'                                  # git add all
alias gau='git add -u'                                 # git add updated
alias gap='git add --patch'                            # git add patch
gc() { git commit -m "${*:-WIP}" }                     # git commit
alias gcm='git commit -m'                              # git commit message
alias gca='git commit --amend'                         # git commit amend
alias gpu='git push'                                   # git push
alias gst='git status'                                 # git status
alias gs='git status -s'                               # git status short
alias gl='git log'                                     # git log
alias gb='git branch'                                  # git branch opt -d and -D for deleting
alias gbr='git branch -r'                              # git branch remote
alias gsb='git switch'                                 # git switch branch
alias gcb='git switch -c'                              # git create branch
alias gd='git diff'                                    # git diff
alias gdp='git diff --diff-algorithm=patience'         # git diff patience
alias gsl='git stash list'                             # gits stash list
gsa() { git stash push -u -m ${*:-WIP $(dat)}; }       # git stash all message ''
gss() { git stash push --staged -m ${*:-WIP $(dat)}; } # git stash staged message ''
gsap() { git stash apply "stash@{${1:-0}}" }           # git stash apply opt X for specific, latest default

zinit light zsh-users/zsh-syntax-highlighting
