#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# CLI tools that aren't in Ubuntu's apt, plus language toolchains.

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# bottom (btm): .deb on GitHub
if ! has btm; then
  info "bottom"
  install_deb_url "$(gh_asset ClementTsang/bottom '/bottom_[0-9.]+-[0-9]+_amd64\.deb$')"
fi

# procs: single binary in a zip
if ! has procs; then
  info "procs"
  curl -fsSL -o "$TMP_DIR/procs.zip" "$(gh_asset dalance/procs 'x86_64-linux\.zip$')"
  unzip -oq "$TMP_DIR/procs.zip" procs -d "$HOME/.local/bin"
fi

# tokei: newest releases ship no Linux binaries, so pin the last stable one that does
if ! has tokei; then
  info "tokei"
  curl -fsSL "$(gh_asset XAMPPRocky/tokei 'x86_64-unknown-linux-gnu\.tar\.gz$' v12.1.2)" \
    | tar -xz -C "$HOME/.local/bin" tokei
fi

# Ubuntu names these batcat/fdfind; the zshrc aliases use fdfind and bat
if ! has bat && has batcat; then ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"; fi

if ! has uv; then
  info "uv"
  curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
fi

export NVM_DIR="$HOME/.nvm"
if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  info "nvm"
  tag="$(curl -fsSL https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -oE '"tag_name": *"[^"]+"' | cut -d'"' -f4)"
  # PROFILE=/dev/null: the zshrc already lazy-loads nvm, don't let the installer append to it
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$tag/install.sh" | PROFILE=/dev/null bash
fi
if ! compgen -G "$NVM_DIR/versions/node/v*" >/dev/null; then
  info "node LTS"
  # nvm.sh isn't written for set -u
  set +u
  # shellcheck source=/dev/null
  source "$NVM_DIR/nvm.sh"
  nvm install --lts
  nvm alias default 'lts/*'
  set -u
fi

if ! has claude; then
  info "Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi
