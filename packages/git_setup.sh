#!/bin/bash

# GIT Install
sudo pacman -S --noconfirm --needed git

git clone https://github.com/torres-rodrigo/DOOM.git

# read -rp "Enter your Github user name: " GIT_USER_NAME
# read -rp "Enter your Github email: " GIT_USER_EMAIL

# SSH_KEY_FILE="$HOME/.ssh/id_ed25519"
# SSH_KEY_COMMENT="$GIT_USER_EMAIL"

# git config --global user.name "$GIT_USER_NAME"
# git config --global user.email "$GIT_USER_EMAIL"

# if [ ! -f "$SSH_KEY_FILE"]; then
#     ssh-keygen -t ed25519 -C "$SSH_KEY_COMMENT" -f "$SSH_KEY_FILE"
# fi

# ssh-add "$SSH_KEY_FILE"
