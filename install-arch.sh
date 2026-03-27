#!/usr/bin/env bash

set -euo pipefail

PACSTRAP_PACKAGES=(
  base
  base-devel
  linux
  linux-headers
  linux-firmware
  networkmanager
  git
  rsync
  fish
)

readarray -t PACMAN_PACKAGES < packages/pacman.txt

PACMAN_PACKAGES+=(grub efibootmgr sudo)

AUR_PACKAGES=(
  apple-fonts
  balena-etcher
  cursor-bin
  localsend-bin
  rofi-wayland
  mpvpaper
  spotify
  vscodium-bin
  yay
  zen-browser-bin
)

usage() {
...
