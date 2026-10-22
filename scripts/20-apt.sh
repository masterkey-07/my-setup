#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Install packages/core.txt plus every optional group not passed to --skip.

lists=(core)
for group in gaming comm office media; do
  want "$group" && lists+=("$group")
done

for list in "${lists[@]}"; do
  info "packages/$list.txt"
  mapfile -t pkgs < <(read_list "$PACKAGES/$list.txt")
  apt_install "${pkgs[@]}"
done

# System-wide default cursor, for apps that can't read ~/.icons (snaps such
# as Firefox can't see hidden home folders). GNOME sets its own via gsettings.
CURSOR_THEME=/usr/share/icons/Bibata-Modern-Ice/cursor.theme
if [[ -f "$CURSOR_THEME" ]]; then
  sudo update-alternatives --set x-cursor-theme "$CURSOR_THEME"
else
  warn "Bibata cursor theme not installed; default cursor left unchanged"
fi
