#!/bin/bash

# Exit if a command exits witha a non-zero status
set -eE

# Error catching
catch_errors() {
    echo -e "\n\e[31mDOOM installation failed!\e[0m"
    echo
    echo "The following command finished with exit code $?:"
    echo "$BASH_COMMAND"
    echo
}

# Set the trap
trap catch_errors ERR