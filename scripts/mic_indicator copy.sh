#!/usr/bin/env bash
set -euo pipefail

SRC='@DEFAULT_AUDIO_SOURCE@'

is_muted() {
  # 1) PipeWire: "Volume: 0.90 [MUTED]" (case-insensitive)
  if command -v wpctl >/dev/null 2>&1; then
    out="$(wpctl get-volume "$SRC" 2>/dev/null || true)"
    if printf '%s' "$out" | grep -Eqi '\[ *muted *\]'; then
      return 0
    fi
  fi

  # 2) PulseAudio compat: "Mute: yes"
  if command -v pactl >/dev/null 2>&1; then
    out="$(pactl get-source-mute "$SRC" 2>/dev/null || true)"
    if printf '%s' "$out" | grep -Eqi '^(mute:|mute ) *yes'; then
      return 0
    fi
  fi

  return 1
}

is_in_use() {
  # quante app stanno catturando il mic
  n="$(pactl list source-outputs short 2>/dev/null | wc -l | tr -d ' ')"
  [ "${n:-0}" -gt 0 ]
}

if is_muted; then
  echo '{"text":"●","class":"muted"}'
elif is_in_use; then
  echo '{"text":"●","class":"active"}'
else
  echo '{"text":"","class":"inactive"}'
fi
