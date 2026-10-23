#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Syncthing service and the folders it shares with the other devices.

has syncthing || { warn "syncthing not installed, skipping sync"; exit 0; }

# A system service for $USER: it starts at boot, before login, so the phone
# can sync any time. Config and keys live in ~/.local/state/syncthing.
SYNCTHING_SERVICE="syncthing@$USER.service"
SYNCTHING_CONFIG_WAIT_SECONDS=30
# Same folder IDs as on the other devices so they match once paired
SYNCTHING_BOOKS_ID=my-books
SYNCTHING_VAULT_ID=my-vault
VAULT_VERSIONING=staggered

# syncthing_folder <id> <label> <path>: add the folder unless it's there;
# true when the folder exists afterwards
syncthing_folder() {
  local id="$1" label="$2" path="$3"
  syncthing cli config folders list 2>/dev/null | grep -qix "$id" && return 0
  info "syncthing folder $path"
  mkdir -p "$path"
  syncthing cli config folders add --id "$id" --label "$label" --path "$path" && return 0
  warn "could not add $path to syncthing; add it in the web UI"
  return 1
}

systemctl is-enabled --quiet "$SYNCTHING_SERVICE" || sudo systemctl enable --now "$SYNCTHING_SERVICE"

# The service writes its config (with a fresh device ID) on first start
for ((second = 0; second < SYNCTHING_CONFIG_WAIT_SECONDS; second++)); do
  syncthing cli config folders list >/dev/null 2>&1 && break
  sleep 1
done

# Sharing with devices is done in the web UI (rofi: Syncthing)
syncthing_folder "$SYNCTHING_BOOKS_ID" Books "$HOME/Books" || true

# The password vault. Sync alone would spread a corrupted or deleted vault to
# every device, so keep old versions of it (staggered: thinned out over a year)
if syncthing_folder "$SYNCTHING_VAULT_ID" Vault "$HOME/Vault" &&
  [[ "$(syncthing cli config folders "$SYNCTHING_VAULT_ID" versioning type get)" != "$VAULT_VERSIONING" ]]; then
  info "syncthing versioning ~/Vault -> $VAULT_VERSIONING"
  syncthing cli config folders "$SYNCTHING_VAULT_ID" versioning type set "$VAULT_VERSIONING" \
    || warn "could not turn on versioning for ~/Vault; set it in the web UI"
fi
