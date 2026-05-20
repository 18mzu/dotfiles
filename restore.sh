#!/usr/bin/env sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

link_config() {
  src="$repo_dir/$1"
  dest="$HOME/.config/$1"

  [ -e "$src" ] || return 0
  mkdir -p "$(dirname -- "$dest")"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    printf 'skip existing %s\n' "$dest"
  else
    ln -s "$src" "$dest"
    printf 'linked %s -> %s\n' "$dest" "$src"
  fi
}

link_home_file() {
  src="$repo_dir/home/$1"
  dest="$HOME/$1"

  [ -e "$src" ] || return 0
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    printf 'skip existing %s\n' "$dest"
  else
    ln -s "$src" "$dest"
    printf 'linked %s -> %s\n' "$dest" "$src"
  fi
}

for name in \
  DankMaterialShell \
  alacritty \
  btop \
  cava \
  dunst \
  environment.d \
  fcitx5 \
  fish \
  gtk-3.0 \
  gtk-4.0 \
  hypr \
  kitty \
  niri \
  nvim \
  opencode \
  rofi \
  systemd \
  waybar \
  yazi
do
  link_config "$name"
done

for file in .bash_profile .bashrc .gitconfig; do
  link_home_file "$file"
done

for file in mimeapps.list user-dirs.dirs user-dirs.locale starship.toml; do
  src="$repo_dir/$file"
  dest="$HOME/.config/$file"
  [ -e "$src" ] || continue
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    printf 'skip existing %s\n' "$dest"
  else
    ln -s "$src" "$dest"
    printf 'linked %s -> %s\n' "$dest" "$src"
  fi
done

if [ -d "$repo_dir/local/share/color-schemes" ]; then
  mkdir -p "$HOME/.local/share"
  dest="$HOME/.local/share/color-schemes"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    printf 'skip existing %s\n' "$dest"
  else
    ln -s "$repo_dir/local/share/color-schemes" "$dest"
    printf 'linked %s -> %s\n' "$dest" "$repo_dir/local/share/color-schemes"
  fi
fi

if [ -f "$repo_dir/packages/pacman-explicit.txt" ]; then
  printf '\nNative packages:\n'
  printf 'sudo pacman -S --needed - < %s\n' "$repo_dir/packages/pacman-explicit.txt"
fi

if [ -s "$repo_dir/packages/aur-explicit.txt" ]; then
  printf '\nAUR packages:\n'
  printf 'paru -S --needed - < %s\n' "$repo_dir/packages/aur-explicit.txt"
fi
