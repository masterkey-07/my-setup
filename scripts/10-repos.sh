#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Third-party apt sources (Chrome, Brave, VS Code, ...). Steam, Discord and Obsidian come as .debs in the apps step.

sudo apt-get update
apt_install ca-certificates curl gnupg software-properties-common wget

# Ubuntu multiverse (Steam/codecs) and 32-bit libs (Steam/Wine)
if ! grep -rqs multiverse /etc/apt/sources.list.d/ubuntu.sources /etc/apt/sources.list; then
  sudo add-apt-repository -y multiverse
fi
dpkg --print-foreign-architectures | grep -qx i386 || sudo dpkg --add-architecture i386

add_apt_repo google-chrome https://dl.google.com/linux/linux_signing_key.pub \
  /usr/share/keyrings/google-chrome.gpg \
  'Types: deb
URIs: https://dl.google.com/linux/chrome-stable/deb/
Suites: stable
Components: main
Architectures: amd64'

# The key is already binary; gpg --dearmor passes it through unchanged
add_apt_repo brave-browser https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
  /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  'Types: deb
URIs: https://brave-browser-apt-release.s3.brave.com
Suites: stable
Components: main
Architectures: amd64'

add_apt_repo vscode https://packages.microsoft.com/keys/microsoft.asc \
  /usr/share/keyrings/microsoft.gpg \
  'Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64'

if want dev; then
  # Dart SDK: Google's own repo, which keeps up with releases (Ubuntu doesn't package it)
  add_apt_repo dart https://dl-ssl.google.com/linux/linux_signing_key.pub \
    /usr/share/keyrings/dart.gpg \
    'Types: deb
URIs: https://storage.googleapis.com/download.dartlang.org/linux/debian
Suites: stable
Components: main
Architectures: amd64'
fi

if want comm; then
  add_apt_repo claude-desktop https://downloads.claude.ai/claude-desktop/key.asc \
    /usr/share/keyrings/claude-desktop-archive-keyring.asc \
    'Types: deb
URIs: https://downloads.claude.ai/claude-desktop/apt/stable
Suites: stable
Components: main
Architectures: amd64'

  add_apt_repo anydesk https://keys.anydesk.com/repos/DEB-GPG-KEY \
    /usr/share/keyrings/anydesk.gpg \
    'Types: deb
URIs: https://deb.anydesk.com/
Suites: all
Components: main
Architectures: amd64'
fi

sudo apt-get update
