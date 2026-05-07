#!/usr/bin/env bash
set -euo pipefail

if ! command -v nvidia-smi >/dev/null 2>&1; then
  printf '{"text":"GPU?","tooltip":"nvidia-smi non trovato","class":"nogpu"}'
  exit 0
fi

# temp, util, watt (o N/A), sm_mhz
line=$(nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw,clocks.sm \
  --format=csv,noheader,nounits 2>/dev/null | head -n1)

if [[ -z "${line}" ]]; then
  printf '{"text":"GPU?","tooltip":"nvidia-smi senza dati","class":"nogpu"}'
  exit 0
fi

IFS=',' read -r t u w sm <<<"$line"
t="${t//[[:space:]]/}"
u="${u//[[:space:]]/}"
w="${w//[[:space:]]/}"
sm="${sm//[[:space:]]/}"

# Classi colore per temperatura
cls="cool"
if   (( t >= 80 )); then cls="hot"
elif (( t >= 65 )); then cls="warm"
fi

# Se power.draw è N/A, usa solo MHz nel testo
if [[ "$w" == "N/A" || -z "$w" ]]; then
  text=" ${t}°C    ${u}%   ${sm}MHz"
  tip="GPU Temp: ${t}°C\nUtil: ${u}%\nCore: ${sm} MHz"
else
  # arrotonda watt a 1 decimale
  printf -v w1 "%.1f" "$w"
  text=" ${t}°C   ${u}%   ${w1}W"
  tip="GPU Temp: ${t}°C\nUtil: ${u}%\nPotenza: ${w1} W\nCore: ${sm} MHz"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}' "$text" "$tip" "$cls"
