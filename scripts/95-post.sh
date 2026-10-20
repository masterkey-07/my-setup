#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Things that need you: GitHub login and personal repos.

if has gh; then
  if ! gh auth status >/dev/null 2>&1; then
    log "GitHub login"
    gh auth login || warn "gh login skipped; run 'gh auth login' later"
  fi
  if gh auth status >/dev/null 2>&1 && [[ ! -d "$HOME/Knowledge" ]]; then
    info "cloning Knowledge vault"
    gh repo clone masterkey-07/Obsidian-Knowlodge "$HOME/Knowledge"
  fi
fi

log "next steps"
info "- log out and pick the i3 session at the login screen"
info "- NVIDIA GPU? run: sudo ubuntu-drivers autoinstall"
info "- open a new terminal so zsh, starship and the font take effect"
