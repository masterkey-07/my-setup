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

# Ebook reader for ~/Books (scripts/90-link.sh creates the folder; bin/readest-books opens from it)
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

# Login screen: GDM, Ubuntu's own. The sway lock screen is gtklock
# (dotfiles/gtklock), so nothing here builds a greeter. Re-asserted because
# another display manager's package can take the display-manager.service
# alias; the switch takes effect at the next boot
# gdm.service, not its gdm3 alias: systemctl refuses to enable an alias
GDM_SERVICE=gdm.service
if has gdm3 && [[ "$(readlink -f /etc/systemd/system/display-manager.service)" != */gdm*.service ]]; then
  info "login screen: back to GDM (after a reboot)"
  sudo systemctl enable --force "$GDM_SERVICE"
  # Debian's record of the chosen display manager, which its scripts read
  command -v gdm3 | sudo tee /etc/X11/default-display-manager >/dev/null
fi
