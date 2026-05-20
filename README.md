# Dotfiles

Personal Arch Linux desktop configuration backup.

This repo stores user-facing customizations for the shell, terminal, editor,
Wayland compositors, launchers, status bars, input method, themes, and package
manifests. Runtime state, caches, browser profiles, histories, and credentials
are intentionally excluded.

## Restore

Run from the repo root:

```sh
./restore.sh
```

The script links tracked config directories into `~/.config` and selected home
dotfiles into `$HOME`. It also prints package restore commands instead of
installing packages automatically.

SDDM is intentionally not tracked here.
