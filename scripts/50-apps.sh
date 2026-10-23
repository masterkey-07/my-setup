#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Desktop apps distributed as .debs instead of apt repos.

if ! has obsidian; then
  info "Obsidian"
  url="$(gh_asset obsidianmd/obsidian-releases '_amd64\.deb$')"
  install_deb_url "$url"
fi

# Ebook reader; scripts/90-link.sh points its library at ~/Books
if want office && ! has readest; then
  info "Readest"
  url="$(gh_asset readest/readest '_amd64\.deb$')"
  install_deb_url "$url"
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
