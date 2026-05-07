#!/usr/bin/env bash
set -eu

target="${1:-1.1.1.1}"
out=$(ping -n -c 1 -w 1 "$target" 2>/dev/null || true)

if grep -q "time=" <<<"$out"; then
  ms=$(sed -n 's/.*time=\([0-9.]\+\) ms.*/\1/p' <<<"$out")
  ms_int=${ms%.*}
  cls="good"; [[ $ms_int -ge 60 ]] && cls="ok"; [[ $ms_int -ge 120 ]] && cls="bad"
  printf '{"text":"󰤨 %sms","tooltip":"Ping %s: %sms","class":"%s"}' "$ms" "$target" "$ms" "$cls"
else
  printf '{"text":" down","tooltip":"No reply from %s","class":"down"}' "$target"
fi
