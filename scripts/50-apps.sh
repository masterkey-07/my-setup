#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Desktop apps distributed as .debs instead of apt repos.

if ! has obsidian; then
  info "Obsidian"
  install_deb_url "$(gh_asset obsidianmd/obsidian-releases '_amd64\.deb$')"
fi

# Ebook reader; scripts/90-link.sh points its library at ~/Books
if want office && ! has readest; then
  info "Readest"
  install_deb_url "$(gh_asset readest/readest '_amd64\.deb$')"
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

# GNOME Pomodoro, renamed Focus Timer: no longer in apt, Flathub is upstream's only build
FOCUS_TIMER_ID=io.github.focustimerhq.FocusTimer
if want office && has flatpak && ! flatpak info "$FOCUS_TIMER_ID" >/dev/null 2>&1; then
  info "Focus Timer (GNOME Pomodoro)"
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  sudo flatpak install -y --noninteractive flathub "$FOCUS_TIMER_ID"
fi
