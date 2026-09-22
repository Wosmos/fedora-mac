#!/usr/bin/env bash
# 00 - PREFLIGHT: capture the machine's state BEFORE changing anything.
# Run as your normal user: bash 00-preflight.sh
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
OUT="$HOME/.config/fedora-macos-setup-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

echo "== Backing up current settings to $OUT =="
dconf dump /org/gnome/ > "$OUT/dconf-gnome.ini"
cp "$HOME/.config/monitors.xml" "$OUT/" 2>/dev/null
gnome-extensions list --enabled > "$OUT/extensions-enabled.txt" 2>/dev/null
cp /etc/dnf/dnf.conf "$OUT/" 2>/dev/null
echo "  done - restore GNOME settings with: dconf load /org/gnome/ < $OUT/dconf-gnome.ini"

echo
echo "== System =="
. /etc/os-release; echo "  $PRETTY_NAME / GNOME $(gnome-shell --version 2>/dev/null | grep -oE '[0-9.]+')"
echo "  session : ${XDG_SESSION_TYPE:-unknown}"
echo "  cpu     : $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
echo "  gpu     : $(lspci | grep -iE 'vga|3d' | cut -d: -f3- | xargs)"
echo "  mem     : $(free -h | awk '/Mem:/{print $2}')"
echo "  root fs : $(findmnt -no FSTYPE /)"

echo
echo "== THERMAL BASELINE (re-check after 01-performance.sh) =="
echo "  governor : $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
echo "  EPP      : $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)"
up=$(awk '{print int($1)}' /proc/uptime)
ms=$(cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_total_time_ms 2>/dev/null || echo 0)
echo "  throttled: $((ms/1000))s of ${up}s = $((up>0 ? ms/10/up : 0))% of wall clock"
echo "  temp     : $(sensors 2>/dev/null | awk '/Package id 0/{print $4}')"
echo
echo "  A high throttle % here is the thing to fix FIRST. Spot temperature"
echo "  readings can look fine while the CPU throttles thousands of times a"
echo "  second - trust the cumulative counter, not the thermometer."

echo
echo "== Firmware =="
echo "  BIOS: $(cat /sys/class/dmi/id/bios_version 2>/dev/null) ($(cat /sys/class/dmi/id/bios_date 2>/dev/null))"
echo "  check for updates:  fwupdmgr refresh && fwupdmgr get-updates"
echo
echo "== Battery health =="
upower -i "$(upower -e | grep -m1 BAT)" 2>/dev/null | grep -E "energy-full:|energy-full-design:|capacity:" | sed 's/^/ /'
