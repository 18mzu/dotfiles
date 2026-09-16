#!/usr/bin/env bash
#
# Step 7 - Finalise the GRUB menu names:
#
#   Arch Linux (Secure Boot) -> Arch Linux (main)
#   Arch Linux               -> Arch Linux (debug)
#   Windows Boot Manager     -> Windows 11
#
# The "(debug)" rename comes from the package script 10_linux, so it is applied
# through the patcher + pacman hook (durable across grub/kernel updates).
#
# Usage:  sudo bash 07-rename-entries.sh
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$HERE/common.sh"

require_root

LOG=/root/secureboot-07.log
exec > >(tee -a "$LOG") 2>&1

log "1/4  Backing up configs to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
tar -C / -cf "$BACKUP_DIR/configs-$(date +%Y%m%d-%H%M%S).tar" \
    etc/grub.d boot/grub/grub.cfg 2>/dev/null || true
if [[ -f /boot/grub/grub.cfg ]]; then
  cp -a /boot/grub/grub.cfg "$BACKUP_DIR/grub.cfg.$(date +%Y%m%d-%H%M%S)"
fi

log "2/4  Renaming our own entries (09_secureboot_uki, 40_custom)"
if [[ -f /etc/grub.d/09_secureboot_uki ]]; then
  cp -a /etc/grub.d/09_secureboot_uki "$BACKUP_DIR/" 2>/dev/null || true
  sed -i "s|menuentry 'Arch Linux (Secure Boot)'|menuentry 'Arch Linux (main)'|" \
      /etc/grub.d/09_secureboot_uki || true
fi
if [[ -f /etc/grub.d/40_custom ]]; then
  cp -a /etc/grub.d/40_custom "$BACKUP_DIR/" 2>/dev/null || true
  sed -i "s|menuentry 'Windows Boot Manager'|menuentry 'Windows 11'|" \
      /etc/grub.d/40_custom || true
fi
grep -n "menuentry '" /etc/grub.d/09_secureboot_uki /etc/grub.d/40_custom 2>/dev/null || true

log "3/4  Installing the patcher (adds the 10_linux '(debug)' rename)"
install -m755 "$SECUREBOOT_DIR/grub-theme-icons.py" /usr/local/bin/grub-theme-icons.py
install -d -m755 /etc/pacman.d/hooks
install -m644 "$SECUREBOOT_DIR/grub-theme-icons.hook" /etc/pacman.d/hooks/97-grub-theme-icons.hook
/usr/local/bin/grub-theme-icons.py

log "4/4  Regenerating and validating /boot/grub/grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg
grub-script-check /boot/grub/grub.cfg && echo "grub.cfg syntax: OK"
echo
echo "Menu entries now:"
grep -nE "menuentry '|submenu '" /boot/grub/grub.cfg

cat <<'DONE'

=====================================================================
 Step 7 finished.  Expected menu:

   1. Arch Linux (main)
   2. Arch Linux (debug)
   3. Advanced options for Arch Linux
   4. UEFI Firmware Settings
   5. Windows 11

 The "(debug)" rename is re-applied automatically after grub/kernel
 updates by /etc/pacman.d/hooks/97-grub-theme-icons.hook.

 Log: /root/secureboot-07.log
=====================================================================
DONE
