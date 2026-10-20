#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# zsh + oh-my-zsh + plugins, starship prompt, Nerd Font, default shell.

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  info "oh-my-zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for plugin in zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting mrjohannchang/zsh-interactive-cd; do
  dir="$ZSH_CUSTOM/plugins/${plugin#*/}"
  [[ -d "$dir" ]] || git clone --depth 1 "https://github.com/$plugin.git" "$dir"
done

if ! has starship; then
  info "starship"
  curl -fsSL https://starship.rs/install.sh | sh -s -- -y
fi

if ! fc-list | grep -qi "CaskaydiaCove"; then
  info "Caskaydia Cove Nerd Font"
  url="$(gh_asset ryanoasis/nerd-fonts 'CascadiaCode\.zip$')"
  curl -fsSL -o "$TMP_DIR/font.zip" "$url"
  mkdir -p "$HOME/.local/share/fonts/CaskaydiaCove"
  unzip -oq "$TMP_DIR/font.zip" '*.ttf' -d "$HOME/.local/share/fonts/CaskaydiaCove"
  fc-cache -f >/dev/null
fi

zsh_path="$(command -v zsh)"
if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
  info "default shell -> zsh"
  sudo chsh -s "$zsh_path" "$USER"
fi
