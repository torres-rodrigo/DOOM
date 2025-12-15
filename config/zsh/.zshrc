# Set dir to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source zinit
source "${ZINIT_HOME}/zinit.zsh"

# Starship
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# Plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions

# Load completions
autoload -U compinit && compinit

# Autosuggestions settings
HISTSIZE=1000
HISTFILE="$XDG_STATE_HOME/zsh/history"
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

# Completion styling
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# FZF
source <(fzf --zsh)

# DEFAULTS
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi

# ALIASES
alias v='nvim'
alias g='git'
alias lg='lazygit'
alias ls='ls -la --color'
alias sp='sudo pacman'
alias config='cd $HOME/.config/'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias gf='git fetch'       # git fetch
alias gaa='git add .'      # git add all
alias gau='git add -u'     # git add updated
alias gst='git status'     # git status
alias gs='git status -s'   # git status -s
alias gc='git commit'      # git commit
alias gcm='git commit -m'  # git commit -m
alias gp='git push'        # git push
alias gpl='git pull'       # git pull
