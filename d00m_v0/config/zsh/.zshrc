# ── Completion ────────────────────────────────────────────────────────────────
autoload -U compinit && compinit -d "${XDG_CACHE_HOME}/zsh/zcompdump"

# ── Plugins ───────────────────────────────────────────────────────────────────
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── FZF ───────────────────────────────────────────────────────────────────────
source <(fzf --zsh)
# Ctrl+R: command history  Ctrl+T: file selector  Alt+C: directory jump

# Completion styling
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ── History ───────────────────────────────────────────────────────────────────
HISTSIZE=5000
HISTFILE="$XDG_STATE_HOME/zsh/.zsh_history"
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups \
       hist_save_no_dups hist_find_no_dups

# ── Keybindings ───────────────────────────────────────────────────────────────
bindkey '^y' autosuggest-accept
bindkey '^g' autosuggest-accept
bindkey '^n' history-search-forward
bindkey '^p' history-search-backward
bindkey '^[' undo                       # Ctrl + [ undo
bindkey '^]' redo                       # Ctrl + ] redo
bindkey '^H' backward-kill-word         # Ctrl + H delete word backwards
bindkey '^[[3;5~' kill-word             # Ctrl + Delete delete word forwards
bindkey '\e[1;5D' backward-word         # Ctrl + Left
bindkey '\e[1;5C' forward-word          # Ctrl + Right
bindkey '^[k' clear-line                # Alt+K TODO
bindkey '^[y' copy-line                 # Alt+Y TODO
# Ctrl + a: Go to beginning of prompt
# Ctrl + e: Go to end of prompt
# Ctrl + f: Go forward in prompt
# Ctrl + b: Go backwards in prompt

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X' edit-command-line          # Ctrl + X vim mode for command line

# ── Environment ───────────────────────────────────────────────────────────────
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export BAT_THEME=ansi

# ── Prompt ────────────────────────────────────────────────────────────────────
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# ── Aliases ───────────────────────────────────────────────────────────────────
alias v='nvim'
alias z='cd'
alias ld='cd -'
alias lg='lazygit'
alias ls='eza -lha --icons --group-directories-first'
alias lsf='eza -lha --icons --only-files'
alias lsd='eza -lha --icons --only-dirs'
alias tree='eza --tree --icons'
alias config='cd $HOME/.config/'
alias today='date "+%Y-%m-%d"'
alias dat='date "+%Y-%m-%d %H:%M:%S"'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ..l='cd .. && eza -lha --icons --group-directories-first'
alias ...l='cd ../.. && eza -lha --icons --group-directories-first'
alias ....l='cd ../../.. && eza -lha --icons --group-directories-first'

# ── Git ───────────────────────────────────────────────────────────────────────
alias gf='git fetch'                                             # git fetch
alias gp='git pull'                                              # git pull
ga() {                                                           # git add interactive
    local files
    files=($(git status --porcelain | rg "^.[^ }]" | cut -c4- \
        | fzf -m \
              --prompt 'Files  : ' \
              --preview 'git diff --color=always {};' \
              --bind='ctrl-a:select-all' \
              --height=95%))
    [[ -n "$files" ]] && git add "${files[@]}"
}
alias gaa='git add .'                                            # git add all
alias gau='git add -u'                                           # git add updated
alias gap='git add --patch'                                      # git add patch
gc() { [[ $# -eq 0 ]] && git commit || git commit -m "$*"; }     # git commit
alias gca='git commit --amend'                                   # git commit amend
alias guc='git reset HEAD~1 --soft'                              # git undo commit but keep changes'
alias guch='git reset HEAD~1 --hard'                             # git undo commit and discard changes
alias gpu='git push'                                             # git push
alias gst='git xstatus'                                          # git status
alias gs='git xstatus -s'                                        # git status short
alias gl='git xlog'                                              # git log opt -p shows diffs
alias gb='git xbranch'                                           # git branch opt -d and -D for deleting
alias gbr='git xbranch -r'                                       # git branch remote
alias gsb='git switch'                                           # git switch branch
alias gcb='git switch -c'                                        # git create branch
alias gd='git xdiff'                                             # git diff
alias gdp='git xdiff --diff-algorithm=patience'                  # git diff patience
alias gdd='git xdelta'                                           # git delta diff patience
alias gdds='git xdeltas'                                         # git delta diff side by side patience
alias gsl='git stash list'                                       # git stash list
gsa() { git stash push -u -m ${*:-WIP $(dat)}; }                 # git stash all message ''
gss() { git stash push --staged -m ${*:-WIP $(dat)}; }           # git stash staged message ''
gsap() { git stash apply "stash@{${1:-0}}"; }                    # git stash apply opt X for specific, latest default
gsd() { git stash drop "stash@{${1:-0}}"; }                      # git stash drop opt X for specific, latest default
alias gr='git restore'                                           # git restore
alias grr='git reset --hard @{u}'                                # git reset to remote
alias grl='git reset --hard HEAD'                                # git reset local
alias gbl='git xdblame'                                          # git blame
alias grv='git revert -n'                                        # git revert and stage <commit hashes>
alias grvc='git revert'                                          # git revert and commit <commit hashes>

# ── Search functions ──────────────────────────────────────────────────────────
zle_z() { zd; zle reset-prompt; }
zle -N zle_z
bindkey '\e.' zle_z                     # Alt + . directory jump with preview

zd() {
    local parameter=(.)

    [[ -n "$1" && -d "$1" ]] && parameter+=("$1")

    local dir
    dir=$(fd --type directory --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf --prompt 'Directory  : ' \
              --preview 'eza --tree --color=always --icons=always {};' \
              --height=95%)
    
    [[ -n "$dir" ]] && cd "$dir" || return
}

zf() {
    local parameter=(.)

    [[ -n "$1" && -d "$1" ]] && parameter+=("$1")

    local file
    file=$(fd --type file --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf --prompt 'Files  : ' \
              --preview 'bat --color=always {};' \
              --height=95%)

    [[ -n "$file" ]] && cd "${file:h}" || return
}

za() {
    local parameter=(.)

    [[ -n "$1" && -d "$1" ]] && parameter+=("$1")

    local sel
    sel=$(fd --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf --prompt 'Search  &  : ' \
              --preview '[[ -d {} ]] && eza --tree --color=always --icons=always {} || bat --color=always {}' \
              --height=95%)
    
    [[ -z "$sel" ]] && return

    [[ -d "$sel" ]] && cd "$sel" || cd "$(dirname "$sel")"
}

vz() {
    if [[ -n "$1" && -f "$1" ]]; then 
        v "$@"; 
        return; 
    fi

    local parameter=(.)

    [[ -n "$1" && -d "$1" ]] && parameter+=("$1")

    local -a sel=("${(@f)$(fd --follow --hidden --exclude .git --no-ignore "${parameter[@]}" \
        | fzf --prompt 'Search  &  : ' \
              --multi \
              --preview '[[ -d {} ]] && eza --tree --color=always --icons=always {} || bat --color=always {}' \
              --height=95%)}")
    
    [[ -n "$sel" ]] && v "${sel[@]}"
}

# ── Package helpers ───────────────────────────────────────────────────────────
pkginfo() {
    local pkg
    if [[ -n "$1" ]]; then
        pkg="$1"
    else
        pkg=$(paru -Qq 2>/dev/null | fzf \
            --prompt="Select 󰏖 package > " \
            --header="Enter: confirm | Esc: cancel" \
            --border \
            --height=95% \
            --reverse) || return
    fi

    [[ -z "$pkg" ]] && return

    local YELLOW="\033[38;5;180m"
    local RESET="\033[0m"
    
    local raw
    raw=$(pacman -Qi "$pkg" 2>/dev/null)
    [[ -z "$raw" ]] && { echo "Package not found."; return; }

    _pf() { grep -m1 "^$1[[:space:]]*:" <<< "$raw" | sed 's/^[^:]*: //'; }

    echo -e "${YELLOW}Name           :${RESET} $(_pf Name)"
    echo -e "${YELLOW}Version        :${RESET} $(_pf Version)"
    echo -e "${YELLOW}Description    :${RESET} $(_pf Description)"
    echo -e "${YELLOW}Licenses       :${RESET} $(_pf Licenses)"
    echo -e "${YELLOW}Install Size   :${RESET} $(_pf "Installed Size")"
    echo -e "${YELLOW}Install Date   :${RESET} $(_pf "Install Date")"
    echo -e "${YELLOW}Install Reason :${RESET} $(_pf "Install Reason")"
    echo ""

    for label in "Depends On:pactree -d 1" "Required By:pactree -r -d 1" "Optional Dependencies:pactree -o -d 1"; do
        local lbl="${label%%:*}" cmd="${label##*:}"
        echo -e "${YELLOW}${lbl}${RESET}"
        if $cmd "$pkg" &>/dev/null; then
            $cmd "$pkg" | tail -n +2
        else
            echo "None"
        fi
        echo ""
    done

    echo -e "${YELLOW}Build Date     :${RESET} $(_pf "Build Date")"
    echo -e "${YELLOW}Replaces       :${RESET} $(_pf Replaces)"
    echo -e "${YELLOW}Install Script :${RESET} $(_pf "Install Script")"
    echo -e "${YELLOW}Validated By   :${RESET} $(_pf "Validated By")"
    echo -e "${YELLOW}Conflicts With :${RESET} $(_pf "Conflicts With")"
    echo -e "${YELLOW}Packager       :${RESET} $(_pf Packager)"
    echo ""
    echo -e "${YELLOW}Architecture   :${RESET} $(_pf Architecture)"
    echo -e "${YELLOW}URL            :${RESET} $(_pf URL)"
    echo -e "${YELLOW}Groups         :${RESET} $(_pf Groups)"
    echo -e "${YELLOW}Provides       :${RESET} $(_pf Provides)"
}

orphans() {
    local orphans selected
    orphans=$(paru -Qdtq 2>/dev/null) || true
    
    [[ -z "$orphans" ]] && { echo "No orphan packages found."; return; }

    selected=$(echo "$orphans" | fzf --multi \
        --prompt="Select 󰏖 packages to remove > " \
        --header="Enter: confirm | Esc: cancel | Ctrl-A: select all" \
        --preview='paru -Qi {} 2>/dev/null || echo "Package info not available"' \
        --preview-window=right:60% \
        --border \
        --height=95% \
        --bind='ctrl-a:select-all' \
        --reverse) || return
    
    [[ -z "$selected" ]] && return

    echo ""
    echo "Selected $(echo "$selected" | wc -l) package(s) for removal:"
    echo "─────────────────────────────────────────"
    echo "$selected"
    echo "─────────────────────────────────────────"
    echo ""
    read "REPLY?Remove these packages? [Y/n]: "
    [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]] && echo "$selected" | xargs paru -Rns --noconfirm
}

rmpkgs() {
    local list_flag="-Qq"
    [[ $1 == -e ]] && list_flag="-Qeq"

    local selected
    selected=$(paru $list_flag 2>/dev/null | fzf --multi \
        --prompt="Select 󰏖 packages to remove > " \
        --header="Enter: confirm | Esc: cancel" \
        --preview='paru -Qi {} 2>/dev/null || echo "Package info not available"' \
        --preview-window=right:60% \
        --border \
        --height=95% \
        --reverse) || return
    
    [[ -z "$selected" ]] && return

    echo ""
    echo "Selected $(echo "$selected" | wc -l) package(s) for removal:"
    echo "─────────────────────────────────────────"
    echo "$selected"
    echo "─────────────────────────────────────────"
    echo ""
    read "REPLY?Remove these packages? [Y/n]: "
    [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]] && echo "$selected" | xargs paru -Rns --noconfirm
}
