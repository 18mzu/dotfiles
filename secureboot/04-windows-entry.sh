#!/usr/bin/env bash
#
# Step 4 - Add Windows to the GRUB menu and put GRUB first in the boot order.
#
# Works with Secure Boot on: GRUB chainloads bootmgfw.efi, which the firmware
# verifies against the enrolled Microsoft certificates.
#
# Usage:  sudo bash 04-windows-entry.sh
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$HERE/common.sh"

require_root

LOG=/root/secureboot-04.log
exec > >(tee -a "$LOG") 2>&1

ESP="$(detect_esp)"
ESP_UUID="$(esp_uuid "$ESP")"
WIN_EFI="$ESP/EFI/Microsoft/Boot/bootmgfw.efi"

mountpoint -q "$ESP" || die "$ESP (the EFI system partition) is not mounted."
[[ -n "$ESP_UUID" ]] || die "Could not determine the ESP filesystem UUID."
[[ -f "$WIN_EFI" ]] || warn "Windows boot manager not found at $WIN_EFI (adding the entry anyway)"

log "Detected environment"
echo "  ESP : $ESP  (uuid $ESP_UUID)"

log "1/3  Adding the Windows entry to /etc/grub.d/40_custom"
if grep -q 'bootmgfw.efi' /etc/grub.d/40_custom; then
  warn "A Windows entry is already present -- leaving 40_custom as is."
else
  cat >> /etc/grub.d/40_custom <<EOF

menuentry 'Windows 11' --class windows --class os {
    insmod fat
    insmod chain
    search --no-floppy --set=root --fs-uuid ${ESP_UUID}
    chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
EOF
  echo "Appended."
fi

log "2/3  Regenerating /boot/grub/grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg
echo
echo "Menu entries now:"
grep -nE "menuentry '|submenu '" /boot/grub/grub.cfg

log "3/3  Reordering UEFI boot entries (GRUB first)"
echo "Before:"
efibootmgr | grep -E '^BootOrder|^Boot[0-9A-Fa-f]{4}'
GRUB_NUM=$(efibootmgr | grep -E '^Boot[0-9A-Fa-f]{4}\*? GRUB([[:space:]]|$)' | head -n1 | cut -c5-8)
[[ -n "$GRUB_NUM" ]] || die "Could not find the GRUB UEFI boot entry."
CUR_ORDER=$(efibootmgr | sed -n 's/^BootOrder: //p')
[[ -n "$CUR_ORDER" ]] || die "Could not read the current BootOrder."
NEW_ORDER="${GRUB_NUM},$(printf '%s\n' "$CUR_ORDER" | tr ',' '\n' | grep -vx "$GRUB_NUM" | paste -sd, -)"
echo "GRUB entry = $GRUB_NUM ; new order = $NEW_ORDER"
efibootmgr -o "$NEW_ORDER"
echo
echo "After:"
efibootmgr | grep -E '^BootOrder|^Boot[0-9A-Fa-f]{4}'

cat <<'DONE'

=====================================================================
 Step 4 finished.

 NOTES:
   - Some firmware (and Windows) reset the boot order to put Windows
     first. To make it stick: disable Windows "Fast Startup", and set
     the boot order once in firmware setup (Boot Option Priorities).
   - If it keeps reverting, you can deactivate the Windows firmware
     entry (efibootmgr -A -b <num>) and boot Windows from GRUB instead.

 Log: /root/secureboot-04.log
=====================================================================
DONE
