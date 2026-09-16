# Secure Boot on Arch Linux + Windows (dual boot)

A small, reusable toolkit that sets up **UEFI Secure Boot with your own keys**
on an Arch system that dual-boots Windows — keeping a **GRUB** menu, booting a
**signed Unified Kernel Image (UKI)**, and adding a few theme icons.

Everything machine-specific (ESP path, ESP UUID, UKI path, theme directory) is
**detected at runtime**, so these scripts are not tied to any particular
machine. Secure Boot is not touched until you enable it yourself in firmware.

> Built and tested on an Arch + Windows 11 UEFI setup. Works with **Secure Boot
> permanently ON** — no more toggling it on/off to boot Linux.

## What it does

- Creates your own Secure Boot keys (`sbctl`) and enrolls them **together with
  Microsoft's certificates**, so Windows and signed Option ROMs keep working.
- Regenerates a **UKI** and uses it as the primary boot target.
- Keeps **GRUB** as the boot menu, patched to coexist with Secure Boot.
- Adds **Windows** to the GRUB menu and makes **GRUB first** in the boot order.
- Adds **theme icons** (Windows, plus the Advanced-options and UEFI entries) and
  a **pacman hook** so the customisations survive updates.

## Requirements

- Arch Linux booted in **UEFI mode** (`/sys/firmware/efi` exists).
- A GRUB install and a working **mkinitcpio UKI** (`default_uki=` in
  `/etc/mkinitcpio.d/linux.preset`).
- `sudo` access. Internet for `pacman -S`.
- Optional: a GRUB theme with an `icons/` directory (see theming below).

## The scripts

| Script | What it does |
|---|---|
| `01-prepare-arch.sh` | Back up, install `sbctl`, create keys, regenerate the UKI, reinstall GRUB (no shim), add the UKI chainload entry, sign everything. **Does not touch firmware.** |
| `02-enroll-keys.sh` | Enroll your keys **+ Microsoft's** into firmware (needs Setup Mode). |
| `03-patch-grub.sh` | Patch `SecureBoot`→`SecureB00t` in the GRUB EFI binaries and re-sign (fixes `verification requested but nobody cares`). |
| `04-windows-entry.sh` | Add Windows to the GRUB menu and move GRUB first in the boot order. |
| `05-windows-icon.sh` | Install the Windows icon into the theme. |
| `06-theme-icons.sh` | Icons for the *Advanced options* submenu and *UEFI Firmware Settings*, plus the durability hook. |
| `07-rename-entries.sh` | Finalise names: `Arch Linux (main)`, `Arch Linux (debug)`, `Windows 11`. |

Shared helpers live in `common.sh`; the patcher is `grub-theme-icons.py` and its
pacman hook is `grub-theme-icons.hook`. Icon sources are in `assets/`.

## Order of operations

1. `sudo bash 01-prepare-arch.sh`
2. Reboot; confirm the first GRUB entry boots Arch.
3. In **Windows**: save your BitLocker recovery key, then disable/suspend
   BitLocker.
4. In **firmware**: set **Secure Boot Mode = Custom**, **Secure Boot Support =
   Disabled**. Save & exit.
5. `sudo bash 02-enroll-keys.sh`
6. In **firmware**: set **Secure Boot Support = Enabled**. Save & exit.
7. If GRUB then fails with `verification requested but nobody cares`, boot with
   Secure Boot temporarily off and run `sudo bash 03-patch-grub.sh`.
8. (Optional, cosmetic) `sudo bash 04-windows-entry.sh`,
   `sudo bash 05-windows-icon.sh`, `sudo bash 06-theme-icons.sh`,
   `sudo bash 07-rename-entries.sh`.

Every script is **idempotent** and **backs up** what it changes to
`/root/secureboot-backup/`.

## Firmware notes

- Use **Custom** key mode. Do **not** pick "Standard" — it re-applies the
  factory keys and erases the ones you enroll.
- Keep **Microsoft's certificates** enrolled. Without them, Windows and signed
  GPU Option ROMs may fail to verify (a potential soft-brick).
- If the firmware locks Secure Boot settings behind a BIOS/Administrator
  password, set that password before enrolling.
- Windows likes to put its own boot entry first again. To make **GRUB first**
  stick: disable Windows **Fast Startup** and set the boot order once in
  firmware (Boot Option Priorities).

## Theming

`06`/`07` assume a GRUB theme declared via `GRUB_THEME=` in `/etc/default/grub`,
with an `icons/` directory, and 200×200 PNGs named after each entry's `--class`
(`windows.png`, `advanced.png`, `firmware.png`, …). The bundled icons are
monochrome (white-on-transparent).

## Maintenance & undo

- The pacman hook **re-applies** the `--class` additions and the `(debug)`
  rename after grub/kernel updates; `sbctl`'s hook re-signs the UKI.
- After a big update: `sbctl verify` and `sbctl status` to confirm.
- **Undo:** restore the files in `/root/secureboot-backup/`, then
  `grub-mkconfig -o /boot/grub/grub.cfg`.

## Do NOT commit

- `/var/lib/sbctl/` — your **private Secure Boot keys**.
- `/root/secureboot-backup/` and any `*.bak` files.
- Anything from `/boot/` or `/etc/` containing machine-specific data.

## Credits & licence

- Scripts: MIT (see `LICENSE`).
- The icon style is designed for the **grubshin-bootpact** GRUB theme
  (GPL-3.0) — see <https://github.com/max-ishere/grubshin-bootpact>. This repo
  ships only its own scripts and generated icons, not the theme.
- "Arch Linux" and the Arch logo are trademarks of their respective owners.
- "Windows" is a trademark of Microsoft Corporation.
