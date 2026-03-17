# Change the user's default shell to Zsh.

echo "Changing default shell to zsh..."

if ! command -v zsh &>/dev/null; then
  echo "ERROR: zsh is not installed."
  return 1 2>/dev/null || exit 1
fi

ZSH_PATH=$(which zsh)

# Ensure zsh is listed in /etc/shells (required by chsh)
if ! grep -q "^$ZSH_PATH$" /etc/shells; then
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
fi

sudo chsh -s "$ZSH_PATH" "$USER"

# Tell Zsh where to find all config files.
# /etc/zsh/zshenv is the first file Zsh reads, before ZDOTDIR is known,
# so setting it here makes ~/.config/zsh the source for .zshenv, .zshrc, etc.
if ! grep -q 'ZDOTDIR' /etc/zsh/zshenv 2>/dev/null; then
  echo 'export ZDOTDIR="$HOME/.config/zsh"' | sudo tee -a /etc/zsh/zshenv >/dev/null
  echo "ZDOTDIR set in /etc/zsh/zshenv"
fi

echo "Default shell: zsh ($ZSH_PATH)"
