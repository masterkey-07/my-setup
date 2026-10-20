# Shared helpers, sourced by install.sh and every step script.
# shellcheck shell=bash

: "${SETUP_DIR:?SETUP_DIR must be set}"
# shellcheck disable=SC2034  # used by the step scripts
DOTFILES="$SETUP_DIR/dotfiles"
# shellcheck disable=SC2034
PACKAGES="$SETUP_DIR/packages"

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

# gh_asset <owner/repo> <regex> [tag]: download URL of a release asset (latest by default)
gh_asset() {
  local repo="$1" pattern="$2" tag="${3:-}" api
  if [[ -n "$tag" ]]; then api="https://api.github.com/repos/$repo/releases/tags/$tag"
  else api="https://api.github.com/repos/$repo/releases/latest"; fi
  curl -fsSL "$api" | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 | grep -E "$pattern" | head -1
}

# install_deb_url <url>: download a .deb and install it with its dependencies
install_deb_url() {
  local deb
  deb="$TMP_DIR/$(date +%s%N).deb"
  curl -fsSL -o "$deb" "$1"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$deb"
}

# link <source-in-repo> <target>: symlink, backing up whatever real file was there
link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
    info "ok      $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    local bak
    bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$bak"
    info "backup  $dst -> $bak"
  fi
  ln -s "$src" "$dst"
  info "linked  $dst -> $src"
}
