#!/usr/bin/env python3
"""
Re-add the --class option to GRUB's generated menu entries:

  * "Advanced options for <distro>"  submenu  -> --class advanced
  * "UEFI Firmware Settings"         menuentry -> --class firmware

so the grubshin-bootpact theme can show icons/advanced.png and firmware.png.

GRUB regenerates these entries from /etc/grub.d/{10_linux,30_uefi-firmware},
so this patches those generators.  It is idempotent and backs up each file it
changes to /root/secureboot-backup/.

Used by the installer and by /etc/pacman.d/hooks/97-grub-theme-icons.hook.
"""

import datetime
import os
import shutil
import sys

BACKUP_DIR = "/root/secureboot-backup"

PATCHES = [
    (
        "/etc/grub.d/10_linux",
        "| grub_quote)' \\$menuentry_id_option 'gnulinux-advanced-",
        "| grub_quote)' --class advanced \\$menuentry_id_option 'gnulinux-advanced-",
    ),
    (
        "/etc/grub.d/30_uefi-firmware",
        "menuentry '$LABEL' \\$menuentry_id_option 'uefi-firmware' {",
        "menuentry '$LABEL' --class firmware \\$menuentry_id_option 'uefi-firmware' {",
    ),
    # Rename the top-level (raw-kernel) entry only:
    #   Arch Linux  ->  Arch Linux (debug)
    # (the class is untouched, so the Arch logo stays.)
    (
        "/etc/grub.d/10_linux",
        '$(echo "$os" | grub_quote)',
        '$(echo "$os (debug)" | grub_quote)',
    ),
]


def main():
    for path, old, new in PATCHES:
        if not os.path.isfile(path):
            print(f"skip (missing): {path}")
            continue

        with open(path, "r", encoding="utf-8", errors="surrogateescape") as fh:
            text = fh.read()

        if new in text:
            print(f"already patched: {path}")
            continue

        if old not in text:
            print(f"WARNING: expected text not found in {path} -- skipped")
            continue

        os.makedirs(BACKUP_DIR, exist_ok=True)
        stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        shutil.copy2(path, os.path.join(BACKUP_DIR, f"{os.path.basename(path)}.{stamp}"))

        with open(path, "w", encoding="utf-8", errors="surrogateescape") as fh:
            fh.write(text.replace(old, new))
        os.chmod(path, 0o755)
        print(f"patched: {path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
