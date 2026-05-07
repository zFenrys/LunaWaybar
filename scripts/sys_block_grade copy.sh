#!/usr/bin/env bash
set -euo pipefail

# --- icons (Nerd Font) ---
ICON_TEMP=""    # termometro
ICON_CPU=""     # CPU
ICON_MEM=""     # RAM
# ICON_DISK=""    # Disco (disattivato)

# --- CPU temperature (°C) ---
cpu_temp() {
  for hw in /sys/class/hwmon/hwmon*; do
    if [ -r "$hw/temp1_input" ]; then
      local t; t=$(<"$hw/temp1_input")
      if [ "$t" -ge 1000 ] 2>/dev/null; then printf "%d" $((t/1000)); else printf "%d" "$t"; fi
      return 0
    fi
    for f in "$hw"/temp*_input; do
      [ -r "$f" ] || continue
      local t; t=$(<"$f")
      if [ "$t" -ge 1000 ] 2>/dev/null; then printf "%d" $((t/1000)); else printf "%d" "$t"; fi
      return 0
    done
  done

  for tz in /sys/class/thermal/thermal_zone*; do
    [ -r "$tz/temp" ] || continue
    local t; t=$(<"$tz/temp")
    if [ "$t" -ge 1000 ] 2>/dev/null; then printf "%d" $((t/1000)); else printf "%d" "$t"; fi
    return 0
  done

  if command -v sensors >/dev/null 2>&1; then
    local out
    out=$(sensors 2>/dev/null | sed -n 's/.*+\([0-9]\+\(\.[0-9]\+\)\?\)°C.*/\1/p' | head -n1)
    if [ -n "$out" ]; then printf "%d" "${out%.*}"; return 0; fi
  fi

  printf "N/A"
  return 1
}

# --- CPU usage % ---
cpu_pct() {
  read -r _ a b c d _ < /proc/stat
  local idle1=$d total1=$((a+b+c+d))
  sleep 0.4
  read -r _ a b c d _ < /proc/stat
  local idle2=$d total2=$((a+b+c+d))
  local idle_delta=$((idle2-idle1))
  local total_delta=$((total2-total1))
  local used=$((total_delta-idle_delta))
  if [ "$total_delta" -eq 0 ]; then printf "0"; else printf "%d" $((100 * used / total_delta)); fi
}

# --- MEM usage % + GB ---
mem_info() {
  local total_kb avail_kb used_kb pc
  total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
  avail_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
  used_kb=$(( total_kb - avail_kb ))
  pc=$(( 100 * used_kb / total_kb ))
  local used_gb total_gb
  used_gb=$(awk -v k="$used_kb" 'BEGIN{printf "%.1f", k/1024/1024}')
  total_gb=$(awk -v k="$total_kb" 'BEGIN{printf "%.1f", k/1024/1024}')
  printf "%d;%s;%s\n" "$pc" "$used_gb" "$total_gb"
}

# --- DISK usage % (DISATTIVATO) ---
# disk_info() {
#   local line
#   line=$(df -P -B1 / | awk 'NR==2')
#   local size used pcent
#   size=$(awk '{print $2}' <<<"$line")
#   used=$(awk '{print $3}' <<<"$line")
#   pcent=$(awk '{print $5}' <<<"$line" | tr -d '%')
#   local used_gb size_gb
#   used_gb=$(awk -v b="$used" 'BEGIN{printf "%.1f", b/1024/1024/1024}')
#   size_gb=$(awk -v b="$size" 'BEGIN{printf "%.1f", b/1024/1024/1024}')
#   printf "%d;%s;%s\n" "$pcent" "$used_gb" "$size_gb"
# }

# --- Raccolta dati ---
TEMP=$(cpu_temp) || true
CPU=$(cpu_pct)
IFS=';' read -r MEM MEM_USED_GB MEM_TOTAL_GB <<<"$(mem_info)"

# DISK disabilitato:
# IFS=';' read -r DISK DISK_USED_GB DISK_TOTAL_GB <<<"$(disk_info)"

# --- Classi senza DISK ---
CLASS="idle"
if   [ "$CPU" -ge 85 ] || [ "$MEM" -ge 90 ]; then
  CLASS="critical"
elif [ "$CPU" -ge 70 ] || [ "$MEM" -ge 80 ]; then
  CLASS="warning"
elif [ "$CPU" -ge 40 ] || [ "$MEM" -ge 60 ]; then
  CLASS="busy"
fi

# --- testo ---
if [ "$TEMP" = "N/A" ]; then
  TEMP_TEXT="${ICON_TEMP} N/A"
else
  TEMP_TEXT="${ICON_TEMP} ${TEMP}°C"
fi

TEXT="$TEMP_TEXT  $ICON_CPU ${CPU}%  $ICON_MEM ${MEM}%"
# Disco disattivato:
# TEXT="$TEMP_TEXT  $ICON_CPU ${CPU}%  $ICON_MEM ${MEM}%  $ICON_DISK ${DISK}%"

# --- tooltip ---
TOOLTIP="Temp: ${TEMP}°C\
\nCPU: ${CPU}%\
\nRAM: ${MEM}% (${MEM_USED_GB} / ${MEM_TOTAL_GB} GiB)"

# DISK disattivato:
# TOOLTIP="${TOOLTIP}\nDISK: ${DISK}% (${DISK_USED_GB} / ${DISK_TOTAL_GB} GiB)"

printf '{"text":"%s","tooltip":"%s","class":"%s"}' "$TEXT" "$TOOLTIP" "$CLASS"
