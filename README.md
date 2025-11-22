1 Base arch install
audio setup on installer
add disk encryption

TODO
split up packages installation into base
and those that require other configuration firefox, go, rust, etc
switch oh-my-posh for starship
create alias vf vim file, open file in vim using fzf
Create alias vd vim dir, open vim on directory

z() {
  local search_dir

  if [ -n "$1" ]; then
    search_dir="$1"
  else
    search_dir="."
  fi

  local dir
  dir=$(fd --type d . "$search_dir" 2>/dev/null | fzf)

  if [ -n "$dir" ]; then
    cd "$dir" || return
  fi
}

_z_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -d -- "$cur") )
}
complete -F _z_completion z

zf() {
  local search_dir

  if [ -n "$1" ]; then
    search_dir="$1"
  else
    search_dir="."
  fi

  local file
  file=$(fd --type f . "$search_dir" 2>/dev/null | fzf)

  if [ -n "$file" ]; then
    cd "$(dirname "$file")" || return
  fi
}

_zf_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -d -- "$cur") )
}
complete -F _zf_completion zf


# Register the same function for both z and zf
complete -F _z_completion z
complete -F _z_completion zf


Check if swap is necesary 
What to do about btrfs sub partitions

# XDG Base Directory defaults
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# Rust
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export PATH="$CARGO_HOME/bin:$PATH"

# Firefox (manual workaround)
export MOZILLA_HOME="$XDG_CONFIG_HOME/firefox"
export MOZ_CACHE_DIR="$XDG_CACHE_HOME/firefox"

# Go
export GOPATH="$XDG_DATA_HOME/go"
export GOCACHE="$XDG_CACHE_HOME/go-build"
export PATH="$GOPATH/bin:$PATH"

git section
git install public version
git setup private version


DOOM
DOOM – DOOM OS Of Machines
DOOM – DOOM OS Of Malevolence
DOOM – DOOM Overengineered Obsolete Malware
DOOM – DOOM Over Optimized Meaninglessly

DOOM - Daemon Overrun OS Malware

DOOM – Daemonized OS Of Mayhem

DOOM – Domination OS Of Mayhem
DOOM – Domination Of Oppressed Minds
DOOM – Domination Of One’s Mind

DOOM – Duct-taped OS Of Mediocrity

DOOM – Documentation Obfuscated Or Missing

DOOM – Doomscrolling Over Outrage Media
DOOM – Doomscrolling Over Opinions & Misinformation

DOOM – Deploying Outdated Obsolete Modules

DOOM – Debugging Our Own Madness

DOOM – Deploy Once, Ommit Mistakes

DOOM – Design Over Optimized Meaninglessly

DOOM – Discipline Overcomes Our Midiocrity

Logo
start with "italic" inverted satanic cross
maybe add like a double orthodox russian cross at the top 
surround it with two circles and place runes or symbols
skull at the bottom
R rune
strength, courage, protection rune
axes?

name monogram
R, could be mirrored
T as a sword

DOOM mascot a combination of conan the barberian and the black knight from MP
Have a funny attitude Deadpool/Mask/Johnny Cage
Have a clippy like behavior
Big fucking sword and swole
    
