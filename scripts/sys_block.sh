#!/usr/bin/env bash
set -euo pipefail

# --- icons (Nerd Font) ---
ICON_CPU=""     # alt: 
ICON_MEM=""     # alt: 
ICON_DISK=""

# --- CPU usage % (campionamento breve) ---
cpu_pct() {
  # lettura 1
  read -r _ a b c d _ < /proc/stat
  local idle1=$d total1=$((a+b+c+d))
  sleep 0.4
  # lettura 2
  read -r _ a b c d _ < /proc/stat
  local idle2=$d total2=$((a+b+c+d))
  local idle_delta=$((idle2-idle1))
  local total_delta=$((total2-total1))
  local used=$((total_delta-idle_delta))
  printf "%d" $(( 100 * used / total_delta ))
}

# --- MEM usage % + GB ---
mem_info() {
  local total_kb avail_kb used_kb pc
  total_kb=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
  avail_kb=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)
  used_kb=$(( total_kb - avail_kb ))
  pc=$(( 100 * used_kb / total_kb ))
  # GB con 1 decimale
  local used_gb total_gb
  used_gb=$(awk -v k="$used_kb" 'BEGIN{printf "%.1f", k/1024/1024}')
  total_gb=$(awk -v k="$total_kb" 'BEGIN{printf "%.1f", k/1024/1024}')
  printf "%d;%s;%s\n" "$pc" "$used_gb" "$total_gb"
}

# --- DISK usage % + GB (root /) ---
disk_info() {
  # usa df -P per formato stabile
  # size/used in GB con 1 decimale
  local line
  line=$(df -P -B1 / | awk 'NR==2')
  local size used pcent
  size=$(awk '{print $2}' <<<"$line")
  used=$(awk '{print $3}' <<<"$line")
  pcent=$(awk '{print $5}' <<<"$line" | tr -d '%')
  local used_gb size_gb
  used_gb=$(awk -v b="$used" 'BEGIN{printf "%.1f", b/1024/1024/1024}')
  size_gb=$(awk -v b="$size" 'BEGIN{printf "%.1f", b/1024/1024/1024}')
  printf "%d;%s;%s\n" "$pcent" "$used_gb" "$size_gb"
}

CPU=$(cpu_pct)
IFS=';' read -r MEM MEM_USED_GB MEM_TOTAL_GB <<<"$(mem_info)"
IFS=';' read -r DISK DISK_USED_GB DISK_TOTAL_GB <<<"$(disk_info)"

# --- classi in base a soglie aggregate (coerenti e facili da stilare) ---
# idle <40 / busy 40–69 / warning 70–84 / critical >=85 o disco>=95
CLASS="idle"
if   [ "$CPU" -ge 85 ] || [ "$MEM" -ge 90 ] || [ "$DISK" -ge 95 ]; then
  CLASS="critical"
elif [ "$CPU" -ge 70 ] || [ "$MEM" -ge 80 ] || [ "$DISK" -ge 90 ]; then
  CLASS="warning"
elif [ "$CPU" -ge 40 ] || [ "$MEM" -ge 60 ] || [ "$DISK" -ge 80 ]; then
  CLASS="busy"
fi

# --- testo e tooltip ---
TEXT="$ICON_CPU ${CPU}%  $ICON_MEM ${MEM}%  $ICON_DISK ${DISK}%"
TOOLTIP="CPU: ${CPU}%\
\nRAM: ${MEM}%  (${MEM_USED_GB} / ${MEM_TOTAL_GB} GiB)\
\nDISK: ${DISK}%  (${DISK_USED_GB} / ${DISK_TOTAL_GB} GiB)"

printf '{"text":"%s","tooltip":"%s","class":"%s"}' "$TEXT" "$TOOLTIP" "$CLASS"
