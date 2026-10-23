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
    gh repo clone masterkey-07/Obsidian-Knowledge "$HOME/Knowledge"
  fi
fi

CHROME_PREFS="$HOME/.config/google-chrome/Default/Preferences"
CHROME_SIGNIN_URL="https://accounts.google.com/signin/chrome/sync"

# Chrome records signed-in accounts under account_info in the profile's Preferences
chrome_signed_in() {
  [[ -f "$CHROME_PREFS" ]] && python3 -c '
import json, sys
sys.exit(0 if json.load(open(sys.argv[1])).get("account_info") else 1)' "$CHROME_PREFS"
}

if has google-chrome-stable && ! chrome_signed_in; then
  log "Google login in Chrome"
  if [[ -n "${DISPLAY:-}" && -t 0 ]]; then
    google-chrome-stable "$CHROME_SIGNIN_URL" >/dev/null 2>&1 &
    read -rp "    sign in (and turn on sync) in Chrome, then press Enter "
    chrome_signed_in || warn "Chrome still not signed in; sign in later from its profile menu"
  else
    warn "no graphical session; sign in to Chrome after logging into i3"
  fi
fi

log "next steps"
info "- log out and pick the i3 session at the login screen"
info "- reboot if an NVIDIA driver was just installed"
info "- open a new terminal so zsh, starship and the font take effect"
