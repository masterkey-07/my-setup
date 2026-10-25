#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Install packages/core.txt plus every optional group not passed to --skip.

lists=(core)
for group in "${GROUPS_OPTIONAL[@]}"; do
  want "$group" && lists+=("$group")
done

for list in "${lists[@]}"; do
  info "packages/$list.txt"
  mapfile -t pkgs < <(read_list "$PACKAGES/$list.txt")
  apt_install "${pkgs[@]}"
done

# System-wide default cursor, for apps that can't read ~/.icons (snaps such
# as Firefox can't see hidden home folders). GNOME sets its own via gsettings.
CURSOR_THEME=/usr/share/icons/Bibata-Modern-Ice/cursor.theme
if [[ -f "$CURSOR_THEME" ]]; then
  sudo update-alternatives --set x-cursor-theme "$CURSOR_THEME"
else
  warn "Bibata cursor theme not installed; default cursor left unchanged"
fi

# NVIDIA GPU: let ubuntu-drivers pick the recommended driver (nvidia-smi ships
# with every driver, so its presence means one is already installed).
# Takes effect after a reboot.
if lspci 2>/dev/null | grep -qi 'vga.*nvidia\|3d.*nvidia' && ! has nvidia-smi; then
  if has ubuntu-drivers; then
    info "NVIDIA driver (reboot afterwards)"
    sudo ubuntu-drivers install || warn "ubuntu-drivers install failed; run it by hand"
  else
    warn "NVIDIA GPU found but ubuntu-drivers is missing; install a driver by hand"
  fi
fi

# Chrome as the default browser (writes ~/.config/mimeapps.list)
CHROME_DESKTOP=google-chrome.desktop
if has google-chrome-stable && [[ "$(xdg-settings get default-web-browser 2>/dev/null)" != "$CHROME_DESKTOP" ]]; then
  info "default browser -> Chrome"
  xdg-settings set default-web-browser "$CHROME_DESKTOP" || warn "could not set Chrome as the default browser"
fi

# Run docker without sudo (the group is root-equivalent; fine on a personal machine).
# Takes effect on the next login.
if want dev && getent group docker >/dev/null && ! id -nG "$USER" | grep -qw docker; then
  info "adding $USER to the docker group (log out and back in)"
  sudo usermod -aG docker "$USER"
fi

# Chrome policy: no built-in password saving (KeePassXC does it) and the
# KeePassXC-Browser extension force-installed from the Chrome Web Store
CHROME_POLICY_DIR=/etc/opt/chrome/policies/managed
CHROME_POLICY="$DOTFILES/chrome/policies/keepassxc.json"
if has google-chrome-stable && ! cmp -s "$CHROME_POLICY" "$CHROME_POLICY_DIR/keepassxc.json"; then
  info "chrome policy: KeePassXC instead of the built-in password manager"
  sudo install -D -m 644 "$CHROME_POLICY" "$CHROME_POLICY_DIR/keepassxc.json"
fi

# Sway session for the hybrid GPU: Sway refuses to start while the NVIDIA
# module is loaded unless it gets --unsupported-gpu. GDM only reads system
# session files, so it can't be linked from the repo.
SWAY_SESSION="$DOTFILES/sway/sway-hybrid.desktop"
SWAY_SESSION_DIR=/usr/share/wayland-sessions
if has sway && ! cmp -s "$SWAY_SESSION" "$SWAY_SESSION_DIR/sway-hybrid.desktop"; then
  info "GDM session: Sway (hybrid GPU)"
  sudo install -m 644 "$SWAY_SESSION" "$SWAY_SESSION_DIR/sway-hybrid.desktop"
fi

# DDC access for hdmi-watch: the NVIDIA driver can't tell when HDMI is
# unplugged, so the watcher asks the monitor over I2C. udev rules must be
# system files too.
DDC_RULE="$DOTFILES/udev/70-nvidia-ddc.rules"
UDEV_RULES_DIR=/etc/udev/rules.d
if ! cmp -s "$DDC_RULE" "$UDEV_RULES_DIR/70-nvidia-ddc.rules"; then
  info "udev: NVIDIA DDC access for hdmi-watch"
  sudo install -m 644 "$DDC_RULE" "$UDEV_RULES_DIR/70-nvidia-ddc.rules"
  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=i2c-dev
fi
