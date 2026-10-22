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

# Neovim: Ubuntu's apt build lags behind; nvim-treesitter needs the latest stable release
if [[ ! -x "$HOME/.local/opt/nvim/bin/nvim" ]]; then
  info "neovim"
  mkdir -p "$HOME/.local/opt/nvim"
  curl -fsSL "$(gh_asset neovim/neovim 'nvim-linux-x86_64\.tar\.gz$')" \
    | tar -xz -C "$HOME/.local/opt/nvim" --strip-components=1
  ln -sf "$HOME/.local/opt/nvim/bin/nvim" "$HOME/.local/bin/nvim"
fi

# tree-sitter CLI: nvim-treesitter compiles parsers with it (the npm package is unsupported)
if ! has tree-sitter; then
  info "tree-sitter"
  curl -fsSL "$(gh_asset tree-sitter/tree-sitter '/tree-sitter-linux-x64\.gz$')" \
    | gunzip > "$HOME/.local/bin/tree-sitter"
  chmod +x "$HOME/.local/bin/tree-sitter"
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

# Rust: rustup, plus the rust-analyzer that matches the toolchain (Neovim's LSP uses it)
export PATH="$HOME/.cargo/bin:$PATH"
if ! has rustup; then
  info "rustup"
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi
if ! has rust-analyzer; then
  info "rust-analyzer"
  rustup component add rust-analyzer
fi

# Go language server; go itself comes from apt (packages/core.txt)
export PATH="$HOME/go/bin:$PATH"
if has go && ! has gopls; then
  info "gopls"
  go install golang.org/x/tools/gopls@latest
fi

# Haskell: ghcup installs GHC, cabal and the matching haskell-language-server
export PATH="$HOME/.ghcup/bin:$PATH"
if ! has ghcup; then
  info "ghcup"
  curl --proto '=https' --tlsv1.2 -fsSL https://get-ghcup.haskell.org \
    | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_INSTALL_HLS=1 BOOTSTRAP_HASKELL_ADJUST_BASHRC=0 sh
fi

if ! has claude; then
  info "Claude Code"
  curl -fsSL https://claude.ai/install.sh | bash
fi
