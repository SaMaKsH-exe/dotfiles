#!/usr/bin/env bash

set -euo pipefail

log()  { printf "\e[1;34m[INFO]\e[0m %s\n" "$*"; }
warn() { printf "\e[1;33m[WARN]\e[0m %s\n" "$*"; }
err()  { printf "\e[1;31m[ERR ]\e[0m %s\n" "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: ./install-arch.sh [options]

This script assumes you are already inside your Arch + Hyprland desktop,
with this dotfiles repository cloned. It will install packages, configure
services, and symlink dotfiles using stow.

Options:
  --no-aur        Skip installing AUR packages via yay
  --dry-run       Show what would be done without executing commands
  -h, --help      Show this help message
EOF
}

DRY_RUN=0
INSTALL_AUR=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-aur) INSTALL_AUR=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) err "Unknown option: $1"; usage; exit 1 ;;
  esac
done

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf "[DRY] %s\n" "$*"
  else
    eval "$@"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "Missing dependency: $1"; exit 1; }
}

require_cmd stow
require_cmd sudo

if [[ $INSTALL_AUR -eq 1 ]]; then
  require_cmd yay
fi

REPO_ROOT=$(cd -- "$(dirname "$0")" && pwd)
PACKAGES_DIR="$REPO_ROOT/packages"

PACMAN_LIST="$PACKAGES_DIR/pacman.txt"
AUR_LIST="$PACKAGES_DIR/aur.txt"

[[ -f $PACMAN_LIST ]] || { err "Missing $PACMAN_LIST"; exit 1; }
[[ -f $AUR_LIST ]] || { warn "Missing $AUR_LIST"; INSTALL_AUR=0; }

mapfile -t PACMAN_PACKAGES < "$PACMAN_LIST"
mapfile -t AUR_PACKAGES < "$AUR_LIST"

log "Refreshing package databases"
run sudo pacman -Syu --noconfirm

if ((${#PACMAN_PACKAGES[@]})); then
  log "Installing repo packages"
  run sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"
fi

if [[ $INSTALL_AUR -eq 1 && ${#AUR_PACKAGES[@]} -gt 0 ]]; then
  log "Installing AUR packages"
  run yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
else
  warn "Skipping AUR packages"
fi

log "Enabling essential services"
run sudo systemctl enable --now NetworkManager
run sudo systemctl enable --now bluetooth.service
run sudo systemctl enable --now sddm.service
run sudo systemctl enable --now power-profiles-daemon
run sudo systemctl enable --now mullvad-daemon.service || warn "Mullvad daemon not present"

log "Linking dotfiles with stow"
STOW_PACKAGES=(alacritty bin btop fish git gtk hypr nvim rofi wallpapers waybar)
for pkg in "${STOW_PACKAGES[@]}"; do
  if [[ -d $REPO_ROOT/$pkg ]]; then
    log "Stowing $pkg"
    run stow -d "$REPO_ROOT" -R "$pkg"
  else
    warn "Missing directory $pkg, skipping"
  fi
done

log "Hyprland setup complete. You may need to relog or reboot for all changes to take effect."
