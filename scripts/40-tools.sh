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
  url="$(gh_asset ClementTsang/bottom '/bottom_[0-9.]+-[0-9]+_amd64\.deb$')"
  install_deb_url "$url"
fi

# procs: single binary in a zip
if ! has procs; then
  info "procs"
  url="$(gh_asset dalance/procs 'x86_64-linux\.zip$')"
  curl -fsSL -o "$TMP_DIR/procs.zip" "$url"
  unzip -oq "$TMP_DIR/procs.zip" procs -d "$HOME/.local/bin"
fi

# tokei: newest releases ship no Linux binaries, so pin the last stable one that does
if ! has tokei; then
  info "tokei"
  url="$(gh_asset XAMPPRocky/tokei 'x86_64-unknown-linux-gnu\.tar\.gz$' v12.1.2)"
  curl -fsSL "$url" | tar -xz -C "$HOME/.local/bin" tokei
fi

# Neovim: Ubuntu's apt build lags behind; nvim-treesitter needs the latest stable
# release, so this also upgrades an existing install when a new one is out
NVIM_DIR="$HOME/.local/opt/nvim"
nvim_latest="$(gh_latest_tag neovim/neovim)"
nvim_installed="$("$NVIM_DIR/bin/nvim" --version 2>/dev/null | head -1 | awk '{print $2}')" || nvim_installed=""
if [[ "$nvim_installed" != "$nvim_latest" ]]; then
  info "neovim ${nvim_installed:-(none)} -> $nvim_latest"
  url="$(gh_asset neovim/neovim 'nvim-linux-x86_64\.tar\.gz$' "$nvim_latest")"
  # Fresh dir, so files dropped from the new release don't linger
  rm -rf "$NVIM_DIR" && mkdir -p "$NVIM_DIR"
  curl -fsSL "$url" | tar -xz -C "$NVIM_DIR" --strip-components=1
  ln -sf "$NVIM_DIR/bin/nvim" "$HOME/.local/bin/nvim"
fi

# tree-sitter CLI: nvim-treesitter compiles parsers with it (the npm package is unsupported)
if ! has tree-sitter; then
  info "tree-sitter"
  url="$(gh_asset tree-sitter/tree-sitter '/tree-sitter-linux-x64\.gz$')"
  curl -fsSL "$url" | gunzip > "$HOME/.local/bin/tree-sitter"
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
  tag="$(gh_latest_tag nvm-sh/nvm)"
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

# Rust: outside the dev group because uair below is built with cargo
export PATH="$HOME/.cargo/bin:$PATH"
if ! has rustup; then
  info "rustup"
  curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
fi

# uair: pomodoro timer for swaybar; it ships no release binaries, so build it.
# --root ~/.local puts uair and uairctl on the PATH sway already uses
if ! has uair; then
  info "uair"
  cargo install --locked --root "$HOME/.local" uair
fi

# Microsoft Edit: built from source with its size-optimized release config,
# which needs nightly features (RUSTC_BOOTSTRAP unlocks them on stable) and
# rust-src for build-std. Pinned to the latest release: main doesn't always
# compile on stable. Rebuilt when a new release is out
EDIT_SRC="$HOME/.local/src/edit"
edit_latest="$(gh_latest_tag microsoft/edit)"
# `edit --version` prints "edit version X.Y.Z"; release tags are "vX.Y.Z"
edit_installed="$(edit --version 2>/dev/null | awk '{print "v" $NF}')" || edit_installed=""
if [[ "$edit_installed" != "$edit_latest" ]]; then
  info "Microsoft Edit ${edit_installed:-(none)} -> $edit_latest"
  rustup component add rust-src
  rm -rf "$EDIT_SRC"
  git clone --depth 1 --branch "$edit_latest" https://github.com/microsoft/edit.git "$EDIT_SRC"
  (cd "$EDIT_SRC" && RUSTC_BOOTSTRAP=1 cargo build --locked --release --config .cargo/release.toml)
  install -m 755 "$EDIT_SRC/target/release/edit" "$HOME/.local/bin/edit"
fi

# Everything below is the dev group's language toolchains
want dev || exit 0

# rust-analyzer matching the toolchain (Neovim's LSP uses it)
if ! has_rust_analyzer; then
  info "rust-analyzer"
  rustup component add rust-analyzer
fi

# Go language server; go itself comes from apt (packages/dev.txt)
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

# Java: SDKMAN! installs the JDK plus the JVM build tools and Kotlin
# (rcupdate=false: the zshrc already sources sdkman-init.sh)
export SDKMAN_DIR="$HOME/.sdkman"
if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  info "SDKMAN!"
  curl -fsSL "https://get.sdkman.io?rcupdate=false" | bash
fi
# sdkman-init.sh and sdk aren't written for set -eu
set +eu
# shellcheck source=/dev/null
source "$SDKMAN_DIR/bin/sdkman-init.sh"
# Only for this run, so sdk doesn't prompt; the interactive config is left alone
# shellcheck disable=SC2034  # read by the sdk function
sdkman_auto_answer=true
for candidate in java maven gradle kotlin; do
  if [[ ! -d "$SDKMAN_DIR/candidates/$candidate/current" ]]; then
    info "$candidate (SDKMAN!)"
    sdk install "$candidate" || warn "sdk install $candidate failed"
  fi
done
set -eu

# Clojure CLI (clj/clojure, deps.edn); the apt clojure package is only the bare jar launcher
if ! has clj; then
  info "Clojure CLI"
  # The installer downloads into the current directory
  (cd "$TMP_DIR" && curl -fsSL https://github.com/clojure/brew-install/releases/latest/download/linux-install.sh \
    | bash -s -- --prefix "$HOME/.local")
fi
