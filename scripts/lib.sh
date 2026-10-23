# Shared helpers, sourced by install.sh and every step script.
# shellcheck shell=bash

: "${SETUP_DIR:?SETUP_DIR must be set}"
# shellcheck disable=SC2034  # used by the step scripts
DOTFILES="$SETUP_DIR/dotfiles"
# shellcheck disable=SC2034
PACKAGES="$SETUP_DIR/packages"

# install.sh runs the steps in this order; each optional group is a
# packages/<group>.txt list (plus extras in the step scripts) that --skip turns off
# shellcheck disable=SC2034
STEPS=(repos apt shell tools apps vscode link post)
# shellcheck disable=SC2034
GROUPS_OPTIONAL=(gaming comm office media dev)

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m[warn] %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31m[error] %s\033[0m\n' "$*" >&2; exit 1; }

has() { command -v "$1" >/dev/null 2>&1; }

# want <group>: false when the group was passed to --skip
want() { [[ " ${SKIP:-} " != *" $1 "* ]]; }

# Scratch dir for downloads, removed on exit
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# apt_install <pkg>...: install whatever is available, warn about the rest
apt_install() {
  local pkg available=() missing=()
  for pkg in "$@"; do
    if apt-cache policy "$pkg" 2>/dev/null | sed -n 's/ *Candidate: //p' | grep -qv '(none)'; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done
  ((${#missing[@]})) && warn "not found in apt, skipped: ${missing[*]}"
  ((${#available[@]})) || return 0
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${available[@]}"
}

# read_list <file>: package names from a list, ignoring comments and blanks
read_list() { sed 's/#.*//' "$1" | tr -s ' \t' '\n' | sed '/^$/d'; }

# add_apt_repo <name> <key-url> <keyring-path> <deb822 body without Signed-By>
# Uses the same file names the vendors' own packages write, so they don't conflict.
add_apt_repo() {
  local name="$1" key_url="$2" keyring="$3" body="$4"
  local sources="/etc/apt/sources.list.d/$name.sources"
  if [[ ! -s "$keyring" ]]; then
    info "keyring for $name"
    if [[ "$keyring" == *.gpg ]]; then
      curl -fsSL "$key_url" | gpg --dearmor | sudo tee "$keyring" >/dev/null
    else
      curl -fsSL "$key_url" | sudo tee "$keyring" >/dev/null
    fi
    sudo chmod 644 "$keyring"
  fi
  if [[ ! -f "$sources" && ! -f "/etc/apt/sources.list.d/$name.list" ]]; then
    info "apt source $name"
    printf '%s\nSigned-By: %s\n' "$body" "$keyring" | sudo tee "$sources" >/dev/null
  fi
}

# gh_asset <owner/repo> <regex> [tag]: download URL of a release asset (latest by default).
# Assign it (url="$(gh_asset ...)") rather than passing "$(gh_asset ...)" as an
# argument: set -e only sees a failed command substitution in an assignment.
gh_asset() {
  local repo="$1" pattern="$2" tag="${3:-}" api release url
  if [[ -n "$tag" ]]; then api="https://api.github.com/repos/$repo/releases/tags/$tag"
  else api="https://api.github.com/repos/$repo/releases/latest"; fi
  release="$(curl -fsSL "$api")" \
    || die "GitHub API request failed for $repo (rate limit? 60 requests/hour without a token)"
  url="$(grep -oE '"browser_download_url": *"[^"]+"' <<<"$release" | cut -d'"' -f4 | grep -E "$pattern" | head -1)" \
    || die "no release asset matching '$pattern' in $repo"
  printf '%s\n' "$url"
}

# gh_latest_tag <owner/repo>: tag name of the latest release
gh_latest_tag() {
  local release tag
  release="$(curl -fsSL "https://api.github.com/repos/$1/releases/latest")" \
    || die "GitHub API request failed for $1 (rate limit? 60 requests/hour without a token)"
  tag="$(grep -oE '"tag_name": *"[^"]+"' <<<"$release" | cut -d'"' -f4)" \
    || die "no latest release tag for $1"
  printf '%s\n' "$tag"
}

# has_rust_analyzer: rustup puts a rust-analyzer proxy on PATH even when the
# component isn't installed, so `has rust-analyzer` alone is always true
has_rust_analyzer() { rust-analyzer --version >/dev/null 2>&1; }

# install_deb_url <url>: download a .deb and install it with its dependencies
install_deb_url() {
  local deb
  deb="$TMP_DIR/$(date +%s%N).deb"
  curl -fsSL -o "$deb" "$1"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$deb"
}

# link <source-in-repo> <target>: symlink, backing up the target only when it
# holds content that isn't already in the repo
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    info "ok      $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]] || same_content "$src" "$dst"; then
    rm -rf "$dst"
  elif [[ -e "$dst" ]]; then
    local bak
    bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"
    warn "backup  $dst -> $bak (it differed from the repo; merge it back)"
  fi
  ln -s "$src" "$dst"
  info "linked  $dst -> $src"
}

# same_content <a> <b>: true when both exist and match (files or whole dirs)
same_content() {
  [[ -e "$2" ]] && diff -rq "$1" "$2" >/dev/null 2>&1
}

# link_configs <fn>: call <fn> <source-in-repo> <target> for every config the
# link step manages (90-link.sh passes link, healthcheck.sh a checker)
link_configs() {
  local fn="$1" skill bin app
  "$fn" "$DOTFILES/zsh/.zshrc"            "$HOME/.zshrc"
  "$fn" "$DOTFILES/git/.gitconfig"        "$HOME/.gitconfig"
  "$fn" "$DOTFILES/kitty/kitty.conf"      "$HOME/.config/kitty/kitty.conf"
  "$fn" "$DOTFILES/i3"                    "$HOME/.config/i3"
  "$fn" "$DOTFILES/autorandr/postswitch"  "$HOME/.config/autorandr/postswitch"
  "$fn" "$DOTFILES/picom/picom.conf"      "$HOME/.config/picom/picom.conf"
  "$fn" "$DOTFILES/rofi/config.rasi"      "$HOME/.config/rofi/config.rasi"
  "$fn" "$DOTFILES/nvim"                  "$HOME/.config/nvim"
  "$fn" "$DOTFILES/vscode/settings.json"  "$HOME/.config/Code/User/settings.json"
  "$fn" "$DOTFILES/x11/.Xresources"       "$HOME/.Xresources"
  "$fn" "$DOTFILES/icons/default"         "$HOME/.icons/default"
  "$fn" "$DOTFILES/gtk-3.0/settings.ini"  "$HOME/.config/gtk-3.0/settings.ini"
  "$fn" "$DOTFILES/uair/uair.toml"        "$HOME/.config/uair/uair.toml"

  # Claude Code: link only the config, never ~/.claude itself (it holds
  # credentials, history and sessions). Skills are linked one by one so skills
  # installed by other tools or synced from claude.ai stay untouched.
  "$fn" "$DOTFILES/claude/CLAUDE.md"      "$HOME/.claude/CLAUDE.md"
  "$fn" "$DOTFILES/claude/settings.json"  "$HOME/.claude/settings.json"
  for skill in "$DOTFILES"/claude/skills/*/; do
    "$fn" "${skill%/}" "$HOME/.claude/skills/$(basename "$skill")"
  done

  # Files only: running the Python scripts leaves a __pycache__ dir here
  for bin in "$DOTFILES"/bin/*; do
    [[ -f "$bin" ]] || continue
    "$fn" "$bin" "$HOME/.local/bin/$(basename "$bin")"
  done

  # Rofi launcher entries (e.g. web UIs opened as Chrome app windows).
  for app in "$DOTFILES"/applications/*.desktop; do
    "$fn" "$app" "$HOME/.local/share/applications/$(basename "$app")"
  done
}
