#!/usr/bin/env bash
#
# common.sh - shared helpers for the Secure Boot toolkit.
# Sourced by the numbered scripts; not meant to be run on its own.
#
# Everything machine-specific is detected at runtime, so nothing needs to be
# hard-coded here.

# Directory this toolkit lives in (works no matter where it is cloned).
SECUREBOOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SECUREBOOT_DIR/assets"
BACKUP_DIR="${BACKUP_DIR:-/root/secureboot-backup}"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33m!!  %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31mXX  %s\033[0m\n' "$*" >&2; exit 1; }

require_root() {
  [[ $EUID -eq 0 ]] || die "Run me with sudo:  sudo bash $0"
}

require_uefi() {
  [[ -d /sys/firmware/efi ]] || die "System is not booted in UEFI mode."
}

# Print the mountpoint of the EFI system partition.
detect_esp() {
  local esp
  esp="$(bootctl --print-esp-path 2>/dev/null || true)"
  if [[ -z "$esp" || ! -d "$esp" ]]; then
    esp=/boot
  fi
  printf '%s\n' "$esp"
}

# Print the filesystem UUID of the given ESP mountpoint.
esp_uuid() {
  findmnt -no UUID "$1"
}

# Print the path of the generated Unified Kernel Image (from the mkinitcpio
# preset, falling back to the conventional location).
detect_uki() {
  local esp="$1" uki
  uki="$(sed -n 's/^default_uki="\(.*\)"/\1/p' \
         /etc/mkinitcpio.d/linux.preset 2>/dev/null | head -n1)"
  [[ -n "$uki" ]] || uki="$esp/EFI/Linux/arch-linux.efi"
  printf '%s\n' "$uki"
}

# Print the GRUB EFI binary path inside the ESP (bootloader-id defaults to GRUB).
detect_grub_efi() {
  local esp="$1" id="${2:-GRUB}" extra="${3:-}"
  if [[ -n "$extra" ]]; then
    printf '%s/EFI/%s/%s\n' "$esp" "$id" "$extra"
  else
    printf '%s/EFI/%s/grubx64.efi\n' "$esp" "$id"
  fi
}

# Print the directory of the GRUB theme configured in /etc/default/grub.
# Returns non-zero if no theme is configured.
detect_theme_dir() {
  local tf
  tf="$(sed -n 's/^GRUB_THEME="\(.*\)"/\1/p' /etc/default/grub 2>/dev/null | head -n1)"
  [[ -n "$tf" ]] || return 1
  dirname "$tf"
}
