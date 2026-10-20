#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# VS Code extensions from dotfiles/vscode/extensions.txt.

has code || { warn "code not installed, skipping extensions"; exit 0; }

installed="$(code --list-extensions | tr '[:upper:]' '[:lower:]')"
while read -r ext; do
  grep -qx "${ext,,}" <<<"$installed" && continue
  info "$ext"
  code --install-extension "$ext" --force >/dev/null
done < <(read_list "$DOTFILES/vscode/extensions.txt")
