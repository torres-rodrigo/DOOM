# XDG PATHS
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# RUST
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"

# GO
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go/mod"

# Zig
export ZIG_GLOBAL_CACHE_DIR="$XDG_CACHE_HOME/zig"
export ZIG_GLOBAL_PACKAGE_DIR="$XDG_DATA_HOME/zig"

# .NET (C# / F#)
export NUGET_PACKAGES="$XDG_CACHE_HOME/nuget"
export DOTNET_CLI_HOME="$XDG_CONFIG_HOME/dotnet"
export DOTNET_CLI_CACHE_HOME="$XDG_CACHE_HOME/dotnet"

# STARSHIP
export STARSHIP_CONFIG="$XDG_CONFIG_HOME/starship/starship.toml"

# FZF
export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git --no-ignore'
export FZF_DEFAULT_OPTS='--layout=reverse --prompt="> " --border --ansi --bind "shift-tab:toggle+up,tab:toggle+down,ctrl-g:accept"'

# LESS
export LESSHISTFILE="-"

# PATH
export PATH="$HOME/.local/bin:$CARGO_HOME/bin:$GOPATH/bin:$PATH"
