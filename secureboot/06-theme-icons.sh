#!/usr/bin/env bash
#
# Step 6 - Icons for the "Advanced options" submenu and the
# "UEFI Firmware Settings" entry, and a pacman hook so they survive updates.
#
#   * backs up the configs it touches
#   * installs advanced.png + firmware.png into the theme
#   * patches the GRUB generators to add --class advanced / --class firmware
#   * installs a pacman hook that re-applies the patch after grub/kernel updates
#
# Usage:  sudo bash 06-theme-icons.sh
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$HERE/common.sh"

require_root

LOG=/root/secureboot-06.log
exec > >(tee -a "$LOG") 2>&1

THEME_DIR="$(detect_theme_dir)" || die "No GRUB theme is set (GRUB_THEME) in /etc/default/grub."
ICONS="$THEME_DIR/icons"

[[ -d "$ICONS" ]] || die "Theme icons directory not found: $ICONS"
for a in advanced.png firmware.png; do
  [[ -f "$ASSETS_DIR/$a" ]] || die "Missing icon: $ASSETS_DIR/$a"
done

log "Detected environment"
echo "  theme dir : $THEME_DIR"

log "0/5  Backing up configs to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
tar -C / -cf "$BACKUP_DIR/configs-$(date +%Y%m%d-%H%M%S).tar" \
    etc/grub.d etc/default/grub etc/pacman.d/hooks boot/grub/grub.cfg 2>/dev/null || true
ls -lh "$BACKUP_DIR" | tail -n 5

log "1/5  Installing the icons into the theme"
install -m644 "$ASSETS_DIR/advanced.png" "$ICONS/advanced.png"
install -m644 "$ASSETS_DIR/firmware.png" "$ICONS/firmware.png"
ls -l "$ICONS/advanced.png" "$ICONS/firmware.png"

log "2/5  Installing the patcher -> /usr/local/bin/grub-theme-icons.py"
install -m755 "$SECUREBOOT_DIR/grub-theme-icons.py" /usr/local/bin/grub-theme-icons.py

log "3/5  Installing the pacman hook (97- runs before the system's 98- grub hook)"
install -d -m755 /etc/pacman.d/hooks
install -m644 "$SECUREBOOT_DIR/grub-theme-icons.hook" /etc/pacman.d/hooks/97-grub-theme-icons.hook
ls -l /etc/pacman.d/hooks/97-grub-theme-icons.hook

log "4/5  Patching the GRUB generators"
/usr/local/bin/grub-theme-icons.py

log "5/5  Regenerating and validating /boot/grub/grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg
grub-script-check /boot/grub/grub.cfg && echo "grub.cfg syntax: OK"
echo
echo "Relevant entries now:"
grep -nE "submenu 'Advanced options|menuentry 'UEFI Firmware Settings" /boot/grub/grub.cfg

cat <<'DONE'

=====================================================================
 Step 6 finished.

 NEXT:
   Reboot. "Advanced options" should show the Arch+gear icon and
   "UEFI Firmware Settings" the chip icon.

 The classes are re-applied automatically after grub/kernel updates
 by /etc/pacman.d/hooks/97-grub-theme-icons.hook.

 Log: /root/secureboot-06.log
=====================================================================
DONE
