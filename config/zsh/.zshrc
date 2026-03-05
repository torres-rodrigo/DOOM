# ============================================
# ZINIT INITIALIZATION
# ============================================
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

# ============================================
# PLUGINS
# ============================================
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
zinit wait lucid for Aloxaf/fzf-tab
zinit light zsh-users/zsh-syntax-highlighting

# ============================================
# PLUGIN CONFIGURATION
# ============================================
# FZF-tab settings
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' fzf-flags --bind=tab:accept

# FZF
source <(fzf --zsh)
# Ctrl + r: Command history
# Ctrl + t: Selector
# **<TAB>: Fuzzy Finding
# Alt + c: Directory switching
# Alt + .: Directory switching with preview

# Completion styling
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ============================================
# SHELL CONFIGURATION
# ============================================
# History settings
HISTSIZE=5000
HISTFILE="$XDG_STATE_HOME/zsh/.zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

bindkey '^y' autosuggest-accept
bindkey '^g' autosuggest-accept
bindkey '^n' history-search-forward
bindkey '^p' history-search-backward
# Ctrl + a: Go to beginning of prompt
# Ctrl + e: Go to end of prompt
# Ctrl + f: Go forward in prompt
# Ctrl + b: Go backwards in prompt

bindkey '^[' undo                   # Ctrl + [ undo
bindkey '^]' redo                   # Ctrl + ] redo

bindkey '^H' backward-kill-word     # Ctrl + H delete word backwards
bindkey '^[[3;5~' kill-word         # Ctrl + Delete delete word forwards
bindkey '\e[1;5D' backward-word     # Ctrl + Left move word backwards
bindkey '\e[1;5C' forward-word      # Ctrl + Right move word forwards

bindkey '^[k' clear-line            # Alt + K: Clear line TODO
bindkey '^[y' copy-line             # Alt + Y: Copy line

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X' edit-command-line      # Ctrl + X vim mode for command

# ============================================
# ENVIRONMENT VARIABLES
# ============================================
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi

# ============================================
# PROMPT
# ============================================
# Starship
if command -v starship &> /dev/null; then
eval "$(starship init zsh)"
fi

# ============================================
# ALIASES & FUNCTIONS
# ============================================
# Basic utilities
alias v='nvim'
alias z='cd'
alias ld='cd -'
alias g='git'                             # Possible delete
alias lg='lazygit'
alias ls='eza -lha --icons --group-directories-first'
alias lsf='eza -lha --icons --only-files' # List only files
alias lsd='eza -lha --icons --only-dirs'  # List only directories
alias tree='eza --tree --icons'
alias sp='sudo pacman'                    # Possible delete
alias config='cd $HOME/.config/'
alias today='date "+%Y-%m-%d"'
alias dat='date "+%Y-%m-%d %H:%M:%S"'     # date and time

# Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ..l='cd .. && eza -lha --icons --group-directories-first'
alias ...l='cd ../.. && eza -lha --icons --group-directories-first'
alias ....l='cd ../../.. && eza -lha --icons --group-directories-first'

# Git aliases
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
alias gst='git xstatus'                                # git status
alias gs='git xstatus -s'                              # git status short
alias gl='git xlog'                                    # git log
alias gb='git xbranch'                                 # git branch opt -d and -D for deleting
alias gbr='git xbranch -r'                             # git branch remote
alias gsb='git switch'                                 # git switch branch
alias gcb='git switch -c'                              # git create branch
alias gd='git xdiff'                                   # git diff
alias gdp='git xdiff --diff-algorithm=patience'        # git diff patience
alias gsl='git stash list'                             # git stash list
gsa() { git stash push -u -m ${*:-WIP $(dat)}; }       # git stash all message ''
gss() { git stash push --staged -m ${*:-WIP $(dat)}; } # git stash staged message ''
gsap() { git stash apply "stash@{${1:-0}}" }           # git stash apply opt X for specific, latest default
gsd() { git stash drop "stash@{${1:-0}}" }             # git stash drop opt X for specific, latest default
alias gr='git restore'                                 # git restore
alias grr='git reset --hard @{u}'                      # git reset to remote
alias grl='git reset --hard HEAD'                      # git reset local
alias gbl='git xblame'                                 # git blame
alias grv='git revert -n'                              # git revert and stage <commit hashes>
alias grvc='git revert'                                # git revert and commit <commit hashes>

# [Z]earch Functions
zle_z() {
    local dir=$(fd --type d --hidden --exclude .git \
              | fzf --prompt 'Directory  : ' --height=95% --preview 'eza --tree --color=always --icons=always {};') || return

    if [ -n "$dir" ]; then
        cd "$dir"
    fi

    zle reset-prompt
}
zle -N zle_z
bindkey '\e.' zle_z
# Alt + .: Directory switching with preview

# Zearch & List
zl() {
    local dir=$(fd --type d --hidden --exclude .git \
        | fzf --prompt 'Directory  : ' --height=95% --preview 'eza --tree --color=always --icons=always {};' ) || return

    if [ -n "$dir" ]; then
       cd "$dir"
       eza -lha --icons --group-directories-first
    fi
}

# Zearch Dir
zd() {
    local parameter=(.)

    if [ -n "$1" ] && [ -d "$1" ]; then
        parameter+=("$1")
    fi

    local dir=$(fd --type directory --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf \
            --prompt 'Directory  : ' \
            --preview 'eza --tree --color=always --icons=always {};' \
            --height=95% \
    )

    if [ -n "$dir" ]; then
        cd "$dir" || return
    fi
}

# Zearch File Dir
zf() {
    local parameter=(.)

    if [ -n "$1" ] && [ -d "$1" ]; then
        parameter+=("$1")
    fi

    local file=$(fd --type file --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf \
            --prompt 'Files  : ' \
            --preview 'bat --color=always {};' \
            --height=95% \
    )

    if [ -n "$file" ]; then
        cd "${file:h}" || return
    fi
}

# Vim Zearch
vz() {
    if [[ -n "$1" && -f "$1" ]]; then
        v "$@"
        return
    fi

    local parameter=(.)

    if [ -n "$1" ] && [ -d "$1" ]; then
        parameter+=("$1")
    fi

    local -a files=("${(@f)$(fd --type file --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf \
            --prompt 'Files  : ' \
            --multi \
            --preview 'bat --color=always {};' \
            --height=95%
    )}")

    if [ -n "$files" ]; then  
        v "${files[@]}"
    fi
}

# Remove Orphans
orphans() {
    orphans=$(paru -Qdtq 2>/dev/null || true)

    if [[ -z "$orphans" ]]; then
        echo "✓ No orphan packages found!"
        return
    fi

    selected=$(echo "$orphans" | fzf --multi \
        --prompt="Select 󰏖 packages to remove > " \
        --header="Enter: confirm | Esc: cancel | Ctrl-Space: select |  Ctrl-A: select all" \
        --preview='paru -Qi {} 2>/dev/null || echo "Package info not available"' \
        --preview-window=right:60%:wrap \
        --border \
        --height=95% \
        --bind='ctrl-a:select-all' \
        --reverse) || {
        return
    }

    if [[ -z "$selected" ]]; then
      return
    fi

    selected_count=$(echo "$selected" | wc -l)
    echo ""
    echo "Selected $selected_count package(s) for removal:"
    echo "─────────────────────────────────────────"
    echo "$selected"
    echo "─────────────────────────────────────────"
    echo ""

    read "REPLY?Remove these packages? [Y/n]: "

    if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Removing packages..."
        # Use xargs to pass packages to paru, -Rns removes with dependencies
        echo "$selected" | xargs paru -Rns --noconfirm
        echo ""
        echo "✓ Packages removed successfully"
    fi
}

rmpkgs() {
    pkgs=$(paru -Qq 2>/dev/null || true)

    selected=$(echo "$pkgs" | fzf --multi \
        --prompt="Select 󰏖 packages to remove > " \
        --header="Enter: confirm | Esc: cancel | Ctrl-Space: select" \
        --preview='paru -Qi {} 2>/dev/null || echo "Package info not available"' \
        --preview-window=right:60%:wrap \
        --border \
        --height=95% \
        --reverse) || {
        return
    }

    if [[ -z "$selected" ]]; then
      return
    fi

    selected_count=$(echo "$selected" | wc -l)
    echo ""
    echo "Selected $selected_count package(s) for removal:"
    echo "─────────────────────────────────────────"
    echo "$selected"
    echo "─────────────────────────────────────────"
    echo ""

    read "REPLY?Remove these packages? [Y/n]: "

    if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "Removing packages..."
        # Use xargs to pass packages to paru, -Rns removes with dependencies
        echo "$selected" | xargs paru -Rns --noconfirm
        echo ""
        echo "✓ Packages removed successfully"
    fi
}

pkginfo() {
    local pkg="$1"

    local YELLOW="\033[38;5;180m"
    local RESET="\033[0m"

    # Fetch package data from installed packages (-Q) using | as delimiter
    local data
    data=$(expac -Q '%n|%v|%d|%L|%s|%i|%r|%D|%o|%E|%b|%R|%I|%V|%C|%p|%a|%u|%g|%P' "$pkg" 2>/dev/null)
    [[ -z "$data" ]] && { echo "Package not found."; return; }

    # Read the fields into variables
    IFS='|' read -r \
        name version desc license size instdate reason \
        depends optdepends optfor builddate replaces installscript \
        validation conflicts packager arch url groups provides \
        <<< "$data"

    # Set defaults for missing fields
    : "${license:=None}"
    : "${size:=0}"
    : "${instdate:=0}"
    : "${reason:=None}"
    : "${depends:=None}"
    : "${optdepends:=None}"
    : "${optfor:=None}"
    : "${builddate:=0}"
    : "${replaces:=None}"
    : "${installscript:=No}"
    : "${validation:=None}"
    : "${conflicts:=None}"
    : "${packager:=Unknown}"
    : "${arch:=Unknown}"
    : "${url:=None}"
    : "${groups:=None}"
    : "${provides:=None}"

    # Convert unix timestamps to human-readable dates
    instdate_fmt="None"
    [[ "$instdate" -gt 0 ]] && instdate_fmt=$(date -d @"$instdate" +"%Y-%m-%d %H:%M:%S")

    builddate_fmt="None"
    [[ "$builddate" -gt 0 ]] && builddate_fmt=$(date -d @"$builddate" +"%Y-%m-%d %H:%M:%S")

    # Main package info
    echo -e "${YELLOW}Name           :${RESET} $name"
    echo -e "${YELLOW}Version        :${RESET} $version"
    echo -e "${YELLOW}Description    :${RESET} $desc"
    echo -e "${YELLOW}Licenses       :${RESET} $license"
    echo -e "${YELLOW}Install Size   :${RESET} $size"
    echo -e "${YELLOW}Install Date   :${RESET} $instdate_fmt"
    echo -e "${YELLOW}Install Reason :${RESET} $reason"
    echo ""

    # Dependencies
    echo -e "${YELLOW}Depends On: ${RESET}"
    if pactree -d 1 "$pkg" &>/dev/null; then
        pactree -d 1 "$pkg" | tail -n +2
    else
        echo "None"
    fi
    echo ""

    # Reverse dependencies
    echo -e "${YELLOW}Required By: ${RESET}"
    if pactree -r -d 1 "$pkg" &>/dev/null; then
        pactree -r -d 1 "$pkg" | tail -n +2
    else
        echo "None"
    fi
    echo ""

    # Optional dependencies
    echo -e "${YELLOW}Optional Dependencies: ${RESET}"
    if pactree -o -d 1 "$pkg" &>/dev/null; then
        pactree -o -d 1 "$pkg" | tail -n +2
    else
        echo "None"
    fi
    echo ""

    # Optional for
    echo -e "${YELLOW}Optional For: ${RESET}"
    if [[ -n "$optfor" && "$optfor" != "None" ]]; then
        echo "$optfor" | xargs -n1
    else
        echo "None"
    fi
    echo ""

    # Other metadata
    echo -e "${YELLOW}Build Date     :${RESET} $builddate_fmt"
    echo -e "${YELLOW}Replaces       :${RESET} $replaces"
    echo -e "${YELLOW}Install Script :${RESET} $installscript"
    echo -e "${YELLOW}Validated By   :${RESET} $validation"
    echo -e "${YELLOW}Conflicts With :${RESET} $conflicts"
    echo -e "${YELLOW}Packager       :${RESET} $packager"
    echo ""

    echo -e "${YELLOW}Architecture   :${RESET} $arch"
    echo -e "${YELLOW}URL            :${RESET} $url"
    echo -e "${YELLOW}Groups         :${RESET} $groups"
    echo -e "${YELLOW}Provides       :${RESET} $provides"
}




pkginfo2() {
    local pkg="$1"

    local YELLOW="\033[38;5;180m"
    local RESET="\033[0m"

    local data
    data=$(expac -Q '%n|%v|%d|%L|%s|%i|%r|%D|%o|%b|%R|%I|%V|%C|%p|%a|%u|%g|%P' "$pkg" 2>/dev/null)
    [[ -z "$data" ]] && { echo "Package not found."; return; }

    IFS='|' read -r \
        name version desc license size instdate reason \
        depends optdepends builddate replaces installscript \
        validation conflicts packager arch url groups provides \
        <<< "$data"

    # Convert unix timestamps to readable date or None
    if [[ -n "$instdate" && "$instdate" != "0" ]]; then
        instdate_fmt=$(date -d @"$instdate" +"%Y-%m-%d %H:%M:%S")
    else
        instdate_fmt="None"
    fi
    if [[ -n "$builddate" && "$builddate" != "0" ]]; then
        builddate_fmt=$(date -d @"$builddate" +"%Y-%m-%d %H:%M:%S")
    else
        builddate_fmt="None"
    fi

    echo -e "${YELLOW}Name           :${RESET} $name"
    echo -e "${YELLOW}Version        :${RESET} $version"
    echo -e "${YELLOW}Description    :${RESET} $desc"
    echo -e "${YELLOW}Licenses       :${RESET} ${license:-None}"
    echo -e "${YELLOW}Install Size   :${RESET} $size"
    echo -e "${YELLOW}Install Date   :${RESET} $instdate_fmt"
    echo -e "${YELLOW}Install Reason :${RESET} $reason"
    echo ""

    echo -e "${YELLOW}Depends On: ${RESET}"
    if pactree -d 1 "$pkg" &>/dev/null; then
        pactree -d 1 "$pkg" | tail -n +2
    else
        echo "None"
    fi
    echo ""

    echo -e "${YELLOW}Required By: ${RESET}"
    if pactree -r -d 1 "$pkg" &>/dev/null; then
        pactree -r -d 1 "$pkg" | tail -n +2
    else
        echo "None"
    fi
    echo ""

    echo -e "${YELLOW}Optional Dependencies: ${RESET}"
    if pactree -o -d 1 "$pkg" &>/dev/null; then
        pactree -o -d 1 "$pkg" | tail -n +2
    else
        echo "None"
    fi
    echo ""

    echo -e "${YELLOW}Optional For: ${RESET}"
    local optfor
    optfor=$(expac -Q '%E' "$pkg" 2>/dev/null)
    if [[ -n "$optfor" ]]; then
        echo "$optfor" | xargs -n1
    else
        echo "None"
    fi
    echo ""

    echo -e "${YELLOW}Build Date     :${RESET} $builddate_fmt"
    echo -e "${YELLOW}Replaces       :${RESET} ${replaces:-None}"
    echo -e "${YELLOW}Install Script :${RESET} ${installscript:-No}"
    echo -e "${YELLOW}Validated By   :${RESET} ${validation:-None}"
    echo -e "${YELLOW}Conflicts With :${RESET} ${conflicts:-None}"
    echo -e "${YELLOW}Packager       :${RESET} ${packager:-Unknown}"

    echo ""
    echo -e "${YELLOW}Architecture   :${RESET} $arch"
    echo -e "${YELLOW}URL            :${RESET} ${url:-None}"
    echo -e "${YELLOW}Groups         :${RESET} ${groups:-None}"
    echo -e "${YELLOW}Provides       :${RESET} ${provides:-None}"
}
