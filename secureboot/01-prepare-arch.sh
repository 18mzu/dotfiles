#!/usr/bin/env bash
#
# Step 1 - Prepare Arch for Secure Boot with your own keys.
#
#   * backs up the current boot files
#   * installs sbctl (+ sbsigntools/efitools) and creates your keys
#   * regenerates the Unified Kernel Image (UKI)
#   * reinstalls GRUB for use with your own keys (no shim)
#   * adds a GRUB entry that chainloads the signed UKI (made the default)
#   * signs GRUB, the fallback loader and the UKI
#
# Secure Boot stays OFF in firmware afterwards -- that is the next steps' job.
#
# Usage:  sudo bash 01-prepare-arch.sh
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$HERE/common.sh"

require_root
require_uefi

LOG=/root/secureboot-01.log
exec > >(tee -a "$LOG") 2>&1

ESP="$(detect_esp)"
ESP_UUID="$(esp_uuid "$ESP")"
UKI="$(detect_uki "$ESP")"
GRUB_EFI="$(detect_grub_efi "$ESP")"
FALLBACK_EFI="$ESP/EFI/BOOT/BOOTX64.EFI"
UKI_REL="${UKI#"$ESP"}"

mountpoint -q "$ESP" || die "$ESP (the EFI system partition) is not mounted."
[[ -n "$ESP_UUID" ]] || die "Could not determine the ESP filesystem UUID."

log "Detected environment"
echo "  ESP         : $ESP  (uuid $ESP_UUID)"
echo "  UKI         : $UKI"
echo "  GRUB binary : $GRUB_EFI"

log "0/6  Backing up current boot files to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
tar -C "$ESP" -cf "$BACKUP_DIR/boot-backup-$(date +%Y%m%d-%H%M%S).tar" \
    EFI/GRUB EFI/BOOT EFI/Linux grub 2>/dev/null || true
ls -lh "$BACKUP_DIR" | tail -n 5

log "1/6  Installing sbctl, sbsigntools, efitools"
pacman -S --needed --noconfirm sbctl sbsigntools efitools

log "2/6  Creating your Secure Boot keys"
if [[ -f /var/lib/sbctl/keys/PK/PK.key ]]; then
  warn "Keys already exist -- keeping them."
else
  sbctl create-keys
fi
sbctl status || true

log "3/6  Regenerating the Unified Kernel Image"
rm -f "$UKI"
df -h "$ESP"
mkinitcpio -P
if [[ -f "$UKI" ]]; then
  ls -lh "$UKI"
  sbverify --list "$UKI" 2>&1 | head -n 5 || true
else
  die "UKI was not generated at $UKI (check /etc/mkinitcpio.d/linux.preset)"
fi

log "4/6  Reinstalling GRUB for use with your own keys (no shim)"
grub-install --target=x86_64-efi --efi-directory="$ESP" \
             --bootloader-id=GRUB --disable-shim-lock

log "5/6  Adding a GRUB entry that chainloads the signed UKI (as default)"
cat > /etc/grub.d/09_secureboot_uki <<EOF
#!/bin/sh
exec tail -n +3 \$0
if [ "\${grub_platform}" = "efi" ]; then
  menuentry 'Arch Linux (main)' --id 'arch-secureboot' --class arch --class gnu-linux --class os {
    insmod fat
    insmod chain
    search --no-floppy --set=root --fs-uuid ${ESP_UUID}
    chainloader ${UKI_REL}
  }
fi
EOF
chmod 755 /etc/grub.d/09_secureboot_uki

if grep -qE '^GRUB_DEFAULT=' /etc/default/grub; then
  sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=0/' /etc/default/grub
else
  echo 'GRUB_DEFAULT=0' >> /etc/default/grub
fi

grub-mkconfig -o /boot/grub/grub.cfg
echo "Menu entries now:"
grep -nE "menuentry '|submenu '" /boot/grub/grub.cfg

log "6/6  Signing the boot chain"
if [[ -f "$GRUB_EFI" ]]; then sbctl sign -s "$GRUB_EFI"; fi
if [[ -f "$FALLBACK_EFI" ]]; then sbctl sign -s "$FALLBACK_EFI"; fi
if [[ -f "$UKI" ]]; then sbctl sign -s "$UKI"; fi
echo
sbctl verify || true
echo
sbctl status || true

cat <<'DONE'

=====================================================================
 Step 1 finished.

  >>> Secure Boot is STILL DISABLED in firmware -- that is intended. <<<

 NEXT, in order:
   1. Reboot and confirm "Arch Linux (main)" boots Arch.
   2. Save your BitLocker recovery key, then disable/suspend BitLocker.
   3. In firmware: set Secure Boot Mode = Custom, Support = Disabled.
   4. Run 02-enroll-keys.sh

 Log: /root/secureboot-01.log
=====================================================================
DONE
