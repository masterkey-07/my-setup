#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Symlink the configs in dotfiles/ into $HOME (the list is link_configs in
# lib.sh, shared with healthcheck.sh). Edit them in place and commit.

link_configs link
seed_configs seed

mkdir -p "$HOME/Repositories" "$HOME/Playground" "$HOME/Books" "$HOME/Vault"
