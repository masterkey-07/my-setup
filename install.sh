#!/usr/bin/env bash
# One-command setup for a fresh Ubuntu 24.04 machine.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/masterkey-07/setup/main/install.sh)
#
# Run ./install.sh --help for options.
set -euo pipefail

REPO_URL="https://github.com/masterkey-07/setup.git"
SETUP_DIR="${SETUP_DIR:-$HOME/Repositories/setup}"
STEPS=(repos apt shell tools apps vscode link post)
GROUPS_OPTIONAL=(gaming comm office media)

usage() {
  cat <<EOF
Usage: install.sh [options]

  --only <step>   run only this step (repeatable)
  --skip <name>   skip a step or an optional group (repeatable)
  --link-only     same as --only link
  --list          list steps and groups
  -h, --help      show this help

Steps:  ${STEPS[*]}
Groups: ${GROUPS_OPTIONAL[*]}
EOF
}

ONLY="" SKIP=""
while (($#)); do
  case "$1" in
    --only) ONLY+=" ${2:?--only needs a step}"; shift 2 ;;
    --skip) SKIP+=" ${2:?--skip needs a name}"; shift 2 ;;
    --link-only) ONLY+=" link"; shift ;;
    --list) printf 'steps:  %s\ngroups: %s\n' "${STEPS[*]}" "${GROUPS_OPTIONAL[*]}"; exit 0 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done
export SKIP

[[ $EUID -ne 0 ]] || { echo "Run as your normal user, not root (sudo is used when needed)." >&2; exit 1; }

# Bootstrap: when piped from curl there is no repo next to this script yet
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || HERE=""
if [[ ! -f "$HERE/scripts/lib.sh" ]]; then
  if ! command -v git >/dev/null || ! command -v curl >/dev/null; then
    sudo apt-get update && sudo apt-get install -y git curl
  fi
  if [[ -d "$SETUP_DIR/.git" ]]; then
    git -C "$SETUP_DIR" pull --ff-only || true
  else
    mkdir -p "$(dirname "$SETUP_DIR")"
    git clone "$REPO_URL" "$SETUP_DIR"
  fi
  args=()
  for s in $ONLY; do args+=(--only "$s"); done
  for s in $SKIP; do args+=(--skip "$s"); done
  exec bash "$SETUP_DIR/install.sh" "${args[@]}"
fi

export SETUP_DIR="$HERE"
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Ask for the sudo password once and keep it alive while we run
sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &

for step in "${STEPS[@]}"; do
  if [[ -n "$ONLY" && " $ONLY " != *" $step "* ]]; then continue; fi
  want "$step" || { log "skip $step"; continue; }
  script=("$SETUP_DIR"/scripts/[0-9][0-9]-"$step".sh)
  log "step: $step"
  bash "${script[0]}"
done

log "done"
