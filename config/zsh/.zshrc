# Set dir to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source zinit
source "${ZINIT_HOME}/zinit.zsh"

# Load completions
autoload -U compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"

# Plugins
zinit wait lucid for \
  zsh-users/zsh-autosuggestions \
  zsh-users/zsh-completions

zinit wait lucid for Aloxaf/fzf-tab

zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' fzf-flags --bind=tab:accept

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X' edit-command-line

# Starship
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# Autosuggestions settings
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
alias ld='cd -'
alias g='git'
alias lg='lazygit'
alias ls='eza -lha --icons'
alias tree='eza --tree --icons'
alias sp='sudo pacman'
alias config='cd $HOME/.config/'
alias today='date "+%Y-%m-%d"'
alias dat='date "+%Y-%m-%d %H:%M:%S"' # date and time 

zle_z() {
    local dir=$(fd --type d --hidden --exclude .git \
              | fzf --height=60% --preview 'eza --tree --color=always --icons=always {};') || return

    if [ -n "$dir" ]; then
        cd "$dir"
    fi

    zle reset-prompt
}
zle -N zle_z
bindkey '\e.' zle_z

zl() {
    local dir=$(fd --type d --hidden --exclude .git \
        | fzf --height=60% --preview 'eza --tree --color=always --icons=always {};' ) || return

    if [ -n "$dir" ]; then
       cd "$dir"
       eza -lha --icons
    fi
}

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ..l='cd .. && eza -lha --icons'
alias ...l='cd ../.. && eza -lha --icons'
alias ....l='cd ../../.. && eza -lha --icons'

alias gf='git fetch'                                   # git fetch
alias gp='git pull'                                    # git pull
alias gaa='git add .'                                  # git add all
alias gau='git add -u'                                 # git add updated
alias gap='git add --patch'                            # git add patch
gc() { git commit -m "${*:-WIP}" }                     # git commit
alias gca='git commit --amend'                         # git commit amend
alias guc='git reset HEAD~1 --soft'                    # git undo commit but keep changes'
alias guch='git reset HEAD~1 --hard'                   # git undo commit and discard changes
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
alias gsl='git stash list'                             # git stash list
gsa() { git stash push -u -m ${*:-WIP $(dat)}; }       # git stash all message ''
gss() { git stash push --staged -m ${*:-WIP $(dat)}; } # git stash staged message ''
gsap() { git stash apply "stash@{${1:-0}}" }           # git stash apply opt X for specific, latest default
gsd() { git stash drop "stash@{${1:-0}}" }             # git stash drop opt X for specific, latest default
alias gr='git restore'                                 # git restore
alias grr='git reset --hard @{u}'                      # git reset to remote
alias grl='git reset --hard HEAD'                      # git reset local 

zd() {
    local parameter=(.)

    if [ -n "$1" ] && [ -d "$1" ]; then
        parameter+=("$1")
    fi

    local dir=$(fd --type directory --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf \
            --prompt 'Directory : ' \
            --preview 'eza --tree --color=always --icons=always {};' \
            --height=95% \
    )

    if [ -n "$dir" ]; then
        cd "$dir" || return
    fi
}

zf() {
    local parameter=(.)

    if [ -n "$1" ] && [ -d "$1" ]; then
        parameter+=("$1")
    fi

    local file=$(fd --type file --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf \
            --prompt 'Files : ' \
            --preview 'bat --color=always {};' \
            --height=95% \
    )

    if [ -n "$file" ]; then
        cd "${file:h}" || return
    fi
}

vz() {
    local parameter=(.)

    if [ -n "$1" ] && [ -d "$1" ]; then
        parameter+=("$1")
    fi

    local -a files=("${(@f)$(fd --type file --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf \
            --prompt 'Files : ' \
            --multi \
            --preview 'bat --color=always {};' \
            --height=60%
    )}")

    if [ -n "$files" ]; then  
        v "${files[@]}"
    fi
}

zinit light zsh-users/zsh-syntax-highlighting
