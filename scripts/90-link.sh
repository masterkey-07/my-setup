#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Symlink the configs in dotfiles/ into $HOME. Edit them in place and commit.

link "$DOTFILES/zsh/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/git/.gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/kitty/kitty.conf"      "$HOME/.config/kitty/kitty.conf"
link "$DOTFILES/i3"                    "$HOME/.config/i3"
link "$DOTFILES/vscode/settings.json"  "$HOME/.config/Code/User/settings.json"

for bin in "$DOTFILES"/bin/*; do
  link "$bin" "$HOME/.local/bin/$(basename "$bin")"
done

mkdir -p "$HOME/Repositories" "$HOME/Playground"
