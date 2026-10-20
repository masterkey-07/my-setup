#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Desktop apps distributed as .debs instead of apt repos.

if ! has obsidian; then
  info "Obsidian"
  install_deb_url "$(gh_asset obsidianmd/obsidian-releases '_amd64\.deb$')"
fi

if want comm && ! has discord; then
  info "Discord"
  install_deb_url "https://discord.com/api/download?platform=linux&format=deb"
fi

# steam-launcher adds Valve's own apt repo for updates
if want gaming && ! has steam; then
  info "Steam"
  install_deb_url https://repo.steampowered.com/steam/archive/stable/steam_latest.deb
fi
