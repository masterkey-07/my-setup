#!/usr/bin/env bash
# Check that this machine matches what install.sh sets up: packages, tools,
# shell, apps, configs and logins. Read-only: it never installs or links.
#
#   ./healthcheck.sh                 # check everything
#   ./healthcheck.sh --skip gaming   # ignore an optional group (repeatable)
#
# Exits 1 when any check fails; fix with ./install.sh (or --only <step>).
set -uo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

SKIP=""
while (($#)); do
  case "$1" in
    --skip)
      is_one_of "${2:?--skip needs a group}" "${GROUPS_OPTIONAL[@]}" \
        || die "unknown group: $2 (groups: ${GROUPS_OPTIONAL[*]})"
      SKIP+=" $2"; shift 2 ;;
    -h|--help) sed -n '2,8s/^# \{0,1\}//p' "$0"; exit 0 ;;
    *) echo "unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
done
export SKIP

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
  check_sync
  check_links
  check_configs
  check_password_safe
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
  local list pkg
  while read -r list; do
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
  done < <(wanted_lists)
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
  check "in video group (brightness without sudo)" bash -c "id -nG '$USER' | grep -qw video"
}

check_tools() {
  log "tools"
  local cmd
  for cmd in procs tokei tree-sitter bat uv node npm claude rustup edit; do
    check "$cmd" has "$cmd"
  done
  check "nvim (upstream build in ~/.local/opt)" test -x "$HOME/.local/opt/nvim/bin/nvim"
  check "uair" has uair
  check "uair running (waybar pomodoro)" pgrep -x uair
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
  check_login_screen
  if has_nvidia_gpu; then
    check_nvidia
  fi
  want office && check "readest" has readest
  want office && check "clamscan (book-check)" has clamscan
  want comm && check "discord" has discord
  want gaming && check "steam" has steam
}

# GDM login screen and the gtklock lock screen (scripts/50-apps.sh, sway/config)
check_login_screen() {
  check "GDM is the display manager" bash -c \
    '[[ "$(readlink -f /etc/systemd/system/display-manager.service)" == */gdm*.service ]]'
  check "gtklock" has gtklock
  check "blurred lock screen wallpaper" test -s "${XDG_CACHE_HOME:-$HOME/.cache}/lock-wallpaper.jpg"
}

# check_nvidia: nvidia-smi alone can't say why it can't reach the driver, and
# each cause has its own fix: a missing module needs a package, an unloaded
# one usually a reboot
check_nvidia() {
  local label="NVIDIA driver loaded" kernel boot_kernel smi_output
  kernel="$(uname -r)"
  if ! has nvidia-smi; then
    fail "$label (no driver installed; run ./install.sh --only apt)"
  elif ! has_nvidia_module "$kernel"; then
    fail "$label (no nvidia module for the running kernel $kernel; ./install.sh --only apt installs it or prints the fix)"
  elif ! is_nvidia_module_loaded; then
    fail "$label (module installed but not loaded; reboot, or see: sudo dmesg | grep -i nvidia)"
  elif ! smi_output="$(nvidia-smi 2>&1)"; then
    fail "$label (module loaded but nvidia-smi failed: $(head -1 <<<"$smi_output"))"
  else
    pass "$label"
  fi

  boot_kernel="$(default_boot_kernel)"
  if [[ -n "$boot_kernel" && "$boot_kernel" != "$kernel" ]]; then
    check "NVIDIA module for the next boot's kernel $boot_kernel" has_nvidia_module "$boot_kernel"
  fi
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

check_sync() {
  log "syncthing"
  check "syncthing service running" systemctl is-active "syncthing@$USER.service"
  check "syncthing shares ~/Books" bash -c 'syncthing cli config folders list | grep -qix my-books'
  check "syncthing shares ~/Vault" bash -c 'syncthing cli config folders list | grep -qix my-vault'
  # shellcheck disable=SC2088  # a label, not a path
  check "~/Vault keeps old versions" bash -c \
    '[[ "$(syncthing cli config folders my-vault versioning type get)" == staggered ]]'
  check "weekly book-check of ~/Books" systemctl --user is-enabled book-check.timer
  # A stale key leaves the tray icon up but stuck on "disconnected"
  # shellcheck disable=SC2016  # expanded by the inner bash
  check "syncthingtray has the current API key" bash -c \
    'grep -qF "@ByteArray($(syncthing cli config gui apikey get))" ~/.config/syncthingtray.ini'
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
  has sway && check "sway config valid" sway -C -c "$HOME/.config/sway/config"
  has nvim && check "nvim starts cleanly" nvim_starts_cleanly
  has shellcheck && check "repo shell scripts pass shellcheck" shell_scripts_pass_shellcheck
}

# Every shell script in the repo: the entry points, the step scripts, the
# shell ones in dotfiles/bin (others are Python) and the sourced helpers.
# -x -P SCRIPTDIR follows the `source` lines the way each script resolves them
shell_scripts_pass_shellcheck() {
  local scripts
  mapfile -t scripts < <(
    find "$SETUP_DIR"/install.sh "$SETUP_DIR"/healthcheck.sh "$SETUP_DIR"/scripts "$DOTFILES"/bin \
      -maxdepth 1 -type f -exec grep -lE '^#!.*\b(bash|sh)$' {} +)
  scripts+=("$SETUP_DIR/scripts/lib.sh" "$DOTFILES/waybar/blocks.sh")
  (cd "$SETUP_DIR" && shellcheck -x -P SCRIPTDIR -S warning "${scripts[@]}")
}

# nvim exits 0 even when the config errors, so look for errors in what it printed
# (plain progress messages, like treesitter downloading parsers, are fine)
nvim_starts_cleanly() {
  ! nvim --headless '+qa' 2>&1 | grep -qE 'E[0-9]+:|[Ee]rror|stack traceback'
}

check_password_safe() {
  log "password safe"
  seed_configs check_seeded
  check "a vault exists in ~/Vault" bash -c 'compgen -G "$HOME/Vault/*.kdbx"'
  check "Chrome policy installed" test -f /etc/opt/chrome/policies/managed/keepassxc.json
  check "keepassxc running" pgrep -x keepassxc
}

# check_seeded <source-in-repo> <target>: seeded files only need to exist
check_seeded() { check "$2" test -e "$2"; }

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
