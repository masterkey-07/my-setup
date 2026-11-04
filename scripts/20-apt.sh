#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=scripts/lib.sh
source "$SETUP_DIR/scripts/lib.sh"

# Install packages/core.txt plus every optional group not passed to --skip.

while read -r list; do
  info "packages/$list.txt"
  mapfile -t pkgs < <(read_list "$PACKAGES/$list.txt")
  apt_install "${pkgs[@]}"
done < <(wanted_lists)

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
if has_nvidia_gpu && ! has nvidia-smi; then
  if has ubuntu-drivers; then
    info "NVIDIA driver (reboot afterwards)"
    sudo ubuntu-drivers install || warn "ubuntu-drivers install failed; run it by hand"
  else
    warn "NVIDIA GPU found but ubuntu-drivers is missing; install a driver by hand"
  fi
fi

# install_nvidia_module <kernel>: install Ubuntu's prebuilt module for the
# kernel, or say how to get one when no enabled apt source has it
install_nvidia_module() {
  local kernel="$1" flavor pkg
  flavor="$(nvidia_driver_flavor)"
  if [[ -z "$flavor" ]]; then
    warn "no NVIDIA module for kernel $kernel and no ${NVIDIA_DRIVER_PREFIX}* package to match one to; run: sudo ubuntu-drivers install"
    return
  fi
  pkg="$(nvidia_module_package "$kernel")"
  if has_apt_candidate "$pkg"; then
    info "NVIDIA module for kernel $kernel (reboot afterwards)"
    apt_install "$pkg" || warn "could not install $pkg; run: sudo apt install $pkg"
    return
  fi
  warn "no NVIDIA module for kernel $kernel, and no $pkg in the enabled apt sources"
  if is_kernel_from_proposed "$kernel"; then
    warn "  kernel $kernel came from $(proposed_suite), whose modules are in 'restricted': add it to that entry's Components in /etc/apt/sources.list.d/ubuntu.sources, then: sudo apt update && sudo apt install -t $(proposed_suite) $pkg"
  fi
  warn "  or build the module for every kernel: sudo apt install nvidia-dkms-$flavor"
  warn "  or boot a kernel that has one until Ubuntu publishes $pkg"
}

# is_kernel_from_proposed <kernel>: true when only -proposed offers its image,
# i.e. it was installed ahead of the regular updates
is_kernel_from_proposed() {
  local suites
  suites="$(apt-cache policy "linux-image-$1" 2>/dev/null | awk '$2 ~ /^https?:/ { print $3 }')"
  [[ -n "$suites" ]] && ! grep -qv -- '-proposed/' <<<"$suites"
}

proposed_suite() { printf '%s-proposed\n' "$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release)"; }

# An installed driver still needs a module for each kernel, and Ubuntu can
# ship a kernel before its module (see NVIDIA_MODULE in lib.sh). Check the
# running kernel and the one the next boot picks, so an upgrade doesn't
# surface as a dead GPU (and external monitor) after the reboot.
if has_nvidia_gpu && has nvidia-smi; then
  mapfile -t nvidia_kernels < <(printf '%s\n' "$(uname -r)" "$(default_boot_kernel)" | sed '/^$/d' | sort -u)
  for kernel in "${nvidia_kernels[@]}"; do
    has_nvidia_module "$kernel" || install_nvidia_module "$kernel"
  done
fi

# Chrome as the default browser (writes ~/.config/mimeapps.list)
CHROME_DESKTOP=google-chrome.desktop
if has google-chrome-stable && [[ "$(xdg-settings get default-web-browser 2>/dev/null)" != "$CHROME_DESKTOP" ]]; then
  info "default browser -> Chrome"
  xdg-settings set default-web-browser "$CHROME_DESKTOP" || warn "could not set Chrome as the default browser"
fi

# brightnessctl's udev rule makes the backlight writable by the video group;
# without it the brightness keys and the waybar backlight scroll fail.
# Takes effect on the next login.
if ! id -nG "$USER" | grep -qw video; then
  info "adding $USER to the video group (log out and back in)"
  sudo usermod -aG video "$USER"
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
# module is loaded unless it gets --unsupported-gpu. Login screens only read system
# session files, so it can't be linked from the repo.
SWAY_SESSION="$DOTFILES/sway/sway-hybrid.desktop"
SWAY_SESSION_DIR=/usr/share/wayland-sessions
# The script the session file runs; system-wide, as the session file is
SWAY_SESSION_SCRIPT="$DOTFILES/sway/sway-hybrid-session"
SWAY_SESSION_SCRIPT_BIN=/usr/local/bin/sway-hybrid-session
if has sway && ! cmp -s "$SWAY_SESSION_SCRIPT" "$SWAY_SESSION_SCRIPT_BIN"; then
  info "login session script: $SWAY_SESSION_SCRIPT_BIN"
  sudo install -m 755 "$SWAY_SESSION_SCRIPT" "$SWAY_SESSION_SCRIPT_BIN"
fi
if has sway && ! cmp -s "$SWAY_SESSION" "$SWAY_SESSION_DIR/sway-hybrid.desktop"; then
  info "login session: Sway (hybrid GPU)"
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
