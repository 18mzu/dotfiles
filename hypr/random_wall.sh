#!/bin/bash
set -euo pipefail

DIR="$HOME/Pictures/wallpapers"

# start daemon nếu chưa có
if ! swww query >/dev/null 2>&1; then
  swww init
  # đợi daemon sẵn sàng
  until swww query >/dev/null 2>&1; do
    sleep 0.2
  done
fi

last=""
while true; do
  # chọn ngẫu nhiên 1 ảnh (lọc phần mở rộng)
  pic="$(find "$DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) |
    shuf -n1)"

  # tránh lặp lại ảnh ngay trước đó
  if [[ -n "$last" && "$pic" == "$last" ]]; then
    continue
  fi
  last="$pic"

  swww img "$pic" \
    --transition-type fade \
    --transition-duration 2

  # đổi mỗi 10 phút (đổi số giây tùy thích)
  sleep 120
done
