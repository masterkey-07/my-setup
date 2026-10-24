#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Symlink the configs in dotfiles/ into $HOME (the list is link_configs in
# lib.sh, shared with healthcheck.sh). Edit them in place and commit.

link_configs link
seed_configs seed

# Weekly scan of ~/Books (dotfiles/bin/book-check); needs the user's
# systemd instance, which a plain ssh or chroot session may not have
if systemctl --user daemon-reload 2>/dev/null; then
  systemctl --user is-enabled --quiet book-check.timer || systemctl --user enable --now book-check.timer
else
  warn "no systemd user session; run: systemctl --user enable --now book-check.timer"
fi

mkdir -p "$HOME/Repositories" "$HOME/Playground" "$HOME/Books" "$HOME/Vault"
