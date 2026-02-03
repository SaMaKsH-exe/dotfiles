#!/bin/sh

# This script uses swayidle to manage screen locking and power management.

# Ensure any old instances are gone first.
killall swayidle

# Start swayidle in the background.
swayidle -w \
  timeout 300 'brightnessctl set 10%' \
  timeout 600 'hyprlock' \
  timeout 600 'swaymsg "output * dpms off"' \
  resume 'swaymsg "output * dpms on"' \
  before-sleep 'hyprlock' &
