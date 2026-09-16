#!/usr/bin/env bash
#
# Step 2 - Enroll your Secure Boot keys into the firmware.
#
# Requires the firmware to be in "Setup Mode" (no Platform Key enrolled).
#
# Usage:  sudo bash 02-enroll-keys.sh
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$HERE/common.sh"

require_root
require_uefi

LOG=/root/secureboot-02.log
exec > >(tee -a "$LOG") 2>&1

SETUPMODE=$(od --address-radix=n --format=u1 \
  /sys/firmware/efi/efivars/SetupMode-8be4df61-93ca-11d2-aa0d-00e098032b8c 2>/dev/null \
  | awk '{print $NF}')

log "Firmware SetupMode = ${SETUPMODE:-unknown}  (1 = Setup Mode = ready)"
if [[ "$SETUPMODE" != "1" ]]; then
  warn "Not in Setup Mode. In firmware, clear the Secure Boot keys (enter Setup Mode) first."
fi

log "Before -- sbctl status"
sbctl status || true

log "Signing status (files should already be signed):"
sbctl verify || true

log "Enrolling keys (yours + Microsoft's, plus firmware built-in certs if supported)"
ARGS=(-m)
if sbctl enroll-keys --help 2>&1 | grep -q -- '--firmware-builtin'; then
  ARGS+=(-f)
fi
echo "Running: sbctl enroll-keys ${ARGS[*]}"
sbctl enroll-keys "${ARGS[@]}"

log "After -- sbctl status"
sbctl status || true
bootctl status | sed -n '1,12p'

cat <<'DONE'

=====================================================================
 Step 2 finished (if there were no errors above).

 NEXT:
   1. Reboot into firmware setup and set Secure Boot Support = Enabled
      (leave Secure Boot Mode = Custom).
   2. Boot Arch and confirm:   sbctl status   ->  Secure Boot: enabled
   3. Then run 03-patch-grub.sh if GRUB fails to boot with
      "verification requested but nobody cares".

 Log: /root/secureboot-02.log
=====================================================================
DONE
