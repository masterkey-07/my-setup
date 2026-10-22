#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Symlink the configs in dotfiles/ into $HOME. Edit them in place and commit.

link "$DOTFILES/zsh/.zshrc"            "$HOME/.zshrc"
link "$DOTFILES/git/.gitconfig"        "$HOME/.gitconfig"
link "$DOTFILES/kitty/kitty.conf"      "$HOME/.config/kitty/kitty.conf"
link "$DOTFILES/i3"                    "$HOME/.config/i3"
link "$DOTFILES/autorandr/postswitch"  "$HOME/.config/autorandr/postswitch"
link "$DOTFILES/picom/picom.conf"      "$HOME/.config/picom/picom.conf"
link "$DOTFILES/rofi/config.rasi"      "$HOME/.config/rofi/config.rasi"
link "$DOTFILES/nvim"                  "$HOME/.config/nvim"
link "$DOTFILES/vscode/settings.json"  "$HOME/.config/Code/User/settings.json"
link "$DOTFILES/x11/.Xresources"       "$HOME/.Xresources"
link "$DOTFILES/icons/default"        "$HOME/.icons/default"
link "$DOTFILES/gtk-3.0/settings.ini"  "$HOME/.config/gtk-3.0/settings.ini"

# Claude Code: link only the config, never ~/.claude itself (it holds
# credentials, history and sessions). Skills are linked one by one so skills
# installed by other tools or synced from claude.ai stay untouched.
link "$DOTFILES/claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/settings.json"  "$HOME/.claude/settings.json"
for skill in "$DOTFILES"/claude/skills/*/; do
  link "${skill%/}" "$HOME/.claude/skills/$(basename "$skill")"
done

for bin in "$DOTFILES"/bin/*; do
  link "$bin" "$HOME/.local/bin/$(basename "$bin")"
done

# Rofi launcher entries (e.g. web UIs opened as Chrome app windows).
for app in "$DOTFILES"/applications/*.desktop; do
  link "$app" "$HOME/.local/share/applications/$(basename "$app")"
done

mkdir -p "$HOME/Repositories" "$HOME/Playground" "$HOME/Books"

