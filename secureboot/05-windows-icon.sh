#!/usr/bin/env bash
#
# Step 5 - Install a Windows icon into the GRUB theme.
#
# The theme shows a 200x200 monochrome PNG per menu entry, chosen by the
# entry's --class. There is usually no windows.png, so the Windows entry
# renders blank; this installs one.
#
# No grub-mkconfig needed -- GRUB reads theme icons from disk at boot.
#
# Usage:  sudo bash 05-windows-icon.sh
#
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
. "$HERE/common.sh"

require_root

LOG=/root/secureboot-05.log
exec > >(tee -a "$LOG") 2>&1

THEME_DIR="$(detect_theme_dir)" || die "No GRUB theme is set (GRUB_THEME) in /etc/default/grub."
ICONS="$THEME_DIR/icons"
SRC="$ASSETS_DIR/windows.png"

[[ -d "$ICONS" ]] || die "Theme icons directory not found: $ICONS"
[[ -f "$SRC" ]] || die "Missing icon: $SRC"

log "Installing the Windows icon"
echo "  $SRC -> $ICONS/windows.png"
install -m644 "$SRC" "$ICONS/windows.png"

log "Result"
ls -l "$ICONS/windows.png"
if command -v identify >/dev/null; then
  identify -format '  size=%wx%h channels=%[channels]\n' "$ICONS/windows.png"
fi

cat <<'DONE'

=====================================================================
 Step 5 finished.  No grub-mkconfig required.

 NEXT:
   Reboot. The Windows entry should show the white 4-pane logo.

 Log: /root/secureboot-05.log
=====================================================================
DONE
