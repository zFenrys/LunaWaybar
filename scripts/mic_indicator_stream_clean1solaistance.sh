#!/usr/bin/env bash
set -euo pipefail

SRC='@DEFAULT_AUDIO_SOURCE@'

is_muted() {
  if command -v wpctl >/dev/null 2>&1; then
    out="$(wpctl get-volume "$SRC" 2>/dev/null || true)"
    printf '%s' "$out" | grep -Eqi '\[\s*muted\s*\]'
    return $?
  fi
  if command -v pactl >/dev/null 2>&1; then
    out="$(pactl get-source-mute "$SRC" 2>/dev/null || true)"
    printf '%s' "$out" | grep -Eqi '^(mute:|mute )\s*yes'
    return $?
  fi
  return 1
}

is_in_use() {
  command -v pactl >/dev/null 2>&1 || return 1
  n="$(pactl list source-outputs short 2>/dev/null | wc -l | tr -d ' ')"
  [ "${n:-0}" -gt 0 ]
}

print_state() {
  if is_muted; then
    printf '{"text":"●","class":"muted"}\n'
  elif is_in_use; then
    printf '{"text":"●","class":"active"}\n'
  else
    printf '{"text":"","class":"inactive"}\n'
  fi
}

# stato iniziale
print_state

# aggiorna su eventi (source / source-output)
if command -v pactl >/dev/null 2>&1; then
  pactl subscribe 2>/dev/null \
  | stdbuf -oL grep --line-buffered -Ei 'source|source-output|server' \
  | while IFS= read -r _; do
      print_state
    done
else
  # fallback a polling leggero se manca pactl
  while sleep 0.5; do print_state; done
fi
