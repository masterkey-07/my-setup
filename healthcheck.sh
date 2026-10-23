#!/usr/bin/env bash
# Check that this machine matches what install.sh sets up: packages, tools,
# shell, apps, configs and logins. Read-only: it never installs or links.
#
#   ./healthcheck.sh                 # check everything
#   ./healthcheck.sh --skip gaming   # ignore an optional group (repeatable)
#
# Exits 1 when any check fails; fix with ./install.sh (or --only <step>).
set -uo pipefail

SKIP=""
while (($#)); do
  case "$1" in
    --skip) SKIP+=" ${2:?--skip needs a group}"; shift 2 ;;
    -h|--help) sed -n '2,8s/^# \{0,1\}//p' "$0"; exit 0 ;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
done
export SKIP

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

OK="$(printf '\033[1;32mok\033[0m')"
FAIL="$(printf '\033[1;31mFAIL\033[0m')"
PASSED=0 FAILED=0

main() {
  tool_paths
  check_packages
  check_shell
  check_tools
  check_apps
  check_vscode
  check_links
  check_configs
  check_logins
  summary
}

pass() { info "$OK    $*"; PASSED=$((PASSED + 1)); }
fail() { info "$FAIL  $*"; FAILED=$((FAILED + 1)); }

# check <label> <command...>: pass when the command succeeds
check() {
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi
}

# The installers put these on PATH only through ~/.zshrc, which a bash script doesn't read
tool_paths() {
  local node_dir
  node_dir="$(compgen -G "$HOME/.nvm/versions/node/v*" | sort -V | tail -1)"
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:$HOME/.ghcup/bin:${node_dir:+$node_dir/bin:}$PATH"
  local candidate
  for candidate in "$HOME"/.sdkman/candidates/*/current/bin; do
    [[ -d "$candidate" ]] && PATH="$candidate:$PATH"
  done
}

is_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }

# Only missing packages are listed, one summary line per list keeps the output short
check_packages() {
  log "apt packages"
  local lists=(core) list pkg
  for list in "${GROUPS_OPTIONAL[@]}"; do want "$list" && lists+=("$list"); done
  for list in "${lists[@]}"; do
    local missing=() total=0
    while read -r pkg; do
      total=$((total + 1))
      is_installed "$pkg" || missing+=("$pkg")
    done < <(read_list "$PACKAGES/$list.txt")
    if ((${#missing[@]})); then
      fail "packages/$list.txt: missing ${missing[*]}"
    else
      pass "packages/$list.txt ($total)"
    fi
  done
}

check_shell() {
  log "shell"
  check "oh-my-zsh" test -d "$HOME/.oh-my-zsh"
  local plugin
  for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-interactive-cd; do
    check "zsh plugin $plugin" test -d "$HOME/.oh-my-zsh/custom/plugins/$plugin"
  done
  check "starship" has starship
  check "Caskaydia Cove Nerd Font" bash -c 'fc-list | grep -qi CaskaydiaCove'
  check "default shell is zsh" test "$(getent passwd "$USER" | cut -d: -f7)" = "$(command -v zsh)"
}

check_tools() {
  log "tools"
  local cmd
  for cmd in btm procs tokei tree-sitter bat uv node npm claude rustup; do
    check "$cmd" has "$cmd"
  done
  check "nvim (upstream build in ~/.local/opt)" test -x "$HOME/.local/opt/nvim/bin/nvim"
  check "uair" has uair
  check "uair running (i3bar pomodoro)" pgrep -x uair
  if want dev; then
    for cmd in go gopls ghcup ghc cabal haskell-language-server-wrapper \
      java mvn gradle kotlin clj; do
      check "$cmd" has "$cmd"
    done
    check "rust-analyzer (rustup component)" has_rust_analyzer
    check "docker" has docker
    check "docker compose" docker compose version
    check "docker buildx" docker buildx version
    check "in docker group (no sudo needed)" bash -c "id -nG '$USER' | grep -qw docker"
    check "docker daemon reachable" docker info
  fi
}

check_apps() {
  log "apps"
  check "obsidian" has obsidian
  check "Chrome is the default browser" test "$(xdg-settings get default-web-browser 2>/dev/null)" = google-chrome.desktop
  if lspci 2>/dev/null | grep -qi 'vga.*nvidia\|3d.*nvidia'; then
    check "NVIDIA driver loaded" nvidia-smi
  fi
  check "syncthing service running" systemctl is-active "syncthing@$USER.service"
  check "syncthing shares ~/Books" bash -c 'syncthing cli config folders list | grep -qix my-books'
  want office && check "readest" has readest
  want comm && check "discord" has discord
  want gaming && check "steam" has steam
}

check_vscode() {
  log "vscode extensions"
  if ! has code; then fail "code not installed"; return; fi
  local installed ext missing=()
  installed="$(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  while read -r ext; do
    grep -qx "${ext,,}" <<<"$installed" || missing+=("$ext")
  done < <(read_list "$DOTFILES/vscode/extensions.txt")
  if ((${#missing[@]})); then fail "missing ${missing[*]}"; else pass "all extensions installed"; fi
}

check_links() {
  log "config symlinks"
  link_configs check_link
}

# check_link <source-in-repo> <target>: the same condition link() treats as done
check_link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    pass "$dst"
  elif [[ -L "$dst" ]]; then
    fail "$dst points to $(readlink "$dst"), not the repo"
  elif [[ -e "$dst" ]]; then
    fail "$dst is a regular file, not a symlink"
  else
    fail "$dst missing"
  fi
}

# Syntax-check the linked configs, so a bad edit shows up before the next login
check_configs() {
  log "config syntax"
  check "zshrc parses" zsh -n "$HOME/.zshrc"
  has i3 && check "i3 config valid" i3 -C -c "$HOME/.config/i3/config"
  has nvim && check "nvim starts cleanly" nvim_starts_cleanly
}

# nvim exits 0 even when the config errors, so look for errors in what it printed
# (plain progress messages, like treesitter downloading parsers, are fine)
nvim_starts_cleanly() {
  ! nvim --headless '+qa' 2>&1 | grep -qE 'E[0-9]+:|[Ee]rror|stack traceback'
}

check_logins() {
  log "logins and repos"
  check "gh logged in" gh auth status
  check "$HOME/Knowledge vault cloned" test -d "$HOME/Knowledge/.git"
}

summary() {
  log "$PASSED passed, $FAILED failed"
  ((FAILED == 0))
}

main
