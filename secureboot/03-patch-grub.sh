#!/usr/bin/env bash
#
# Step 3 - Make GRUB ignore Secure Boot, then re-sign it.
#
# GRUB asks for signature verification whenever it reads the firmware variable
# "SecureBoot". This binary-patches that single string to "SecureB00t" in the
# GRUB EFI binaries so GRUB no longer requests verification, then re-signs them.
#
# Run this if GRUB fails under Secure Boot with:
#   error: verification requested but nobody cares
#
# Usage:  sudo bash 03-patch-grub.sh
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$HERE/common.sh"

require_root

LOG=/root/secureboot-03.log
exec > >(tee -a "$LOG") 2>&1

ESP="$(detect_esp)"
GRUB_EFI="$(detect_grub_efi "$ESP")"
FALLBOOT="$ESP/EFI/BOOT/BOOTX64.EFI"

mkdir -p "$BACKUP_DIR"

log "Detected environment"
echo "  ESP         : $ESP"
echo "  GRUB binary : $GRUB_EFI"

log "0/4  Backing up current GRUB binaries to $BACKUP_DIR"
for f in "$GRUB_EFI" "$FALLBOOT"; do
  if [[ -f "$f" ]]; then cp -a "$f" "$BACKUP_DIR/$(basename "$f").bak"; fi
done
ls -l "$BACKUP_DIR" || true

patch_one() {
  local f="$1"
  if [[ ! -f "$f" ]]; then
    warn "$f not found -- skipping"
    return 0
  fi

  log "Patching $f"
  sed -i 's/SecureBoot/SecureB00t/' "$f"

  local n_new n_old
  n_new=$(strings "$f" | grep -c 'SecureB00t' || true)
  n_old=$(strings "$f" | grep -c 'SecureBoot' || true)
  echo "    SecureB00t: $n_new (want 1)    SecureBoot: $n_old (want 0)"
  if [[ "$n_new" -ne 1 || "$n_old" -ne 0 ]]; then
    die "patch check failed for $f -- stopping before touching Secure Boot"
  fi

  log "Re-signing $f"
  sbattach --remove "$f" || warn "sbattach --remove reported a problem (continuing)"
  sbctl sign -s "$f"
}

log "1/4  Patching and re-signing the GRUB binaries"
patch_one "$GRUB_EFI"
patch_one "$FALLBOOT"

log "2/4  Verifying signatures"
for f in "$GRUB_EFI" "$FALLBOOT"; do
  [[ -f "$f" ]] || continue
  echo "-- $f"
  sbverify --list "$f" 2>&1 | head -n 4
done

log "3/4  sbctl verify"
sbctl verify || true

log "4/4  sbctl status"
sbctl status || true

cat <<'DONE'

=====================================================================
 Step 3 finished.

 NEXT:
   Turn Secure Boot back ON in firmware, then boot Arch and confirm
   'sbctl status' shows Secure Boot: enabled.

 If Arch does not boot: set Secure Boot Support = Disabled, boot Arch,
 and re-run nothing -- the backups are in /root/secureboot-backup/.

 Log: /root/secureboot-03.log
=====================================================================
DONE
