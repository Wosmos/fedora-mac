#!/usr/bin/env bash
# 01 - PERFORMANCE / THERMALS
# The single highest-impact script. On the reference machine this took idle
# temps from 89C to 61C and CPU throttling from 27% of wall-clock to 0%.
#
# Run with: sudo bash 01-performance.sh
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
require_fedora
require_root

echo "== Removing any forced-performance CPU tuning =="
# A 'performance' governor on a 15W laptop CPU is actively harmful: it boosts
# to max turbo for trivial work, overheats, and the hardware throttles it.
rm -f /etc/udev/rules.d/99-cpu-tune.rules
rm -f /usr/local/bin/cpu-tune.sh
systemctl disable --now cpu-tune.service 2>/dev/null
rm -f /etc/systemd/system/cpu-tune.service
systemctl daemon-reload; systemctl reset-failed 2>/dev/null
udevadm control --reload-rules

echo "== Handing power management back to GNOME =="
systemctl unmask power-profiles-daemon.service
systemctl enable --now power-profiles-daemon.service
# tuned fights ppd over the same knobs - pick one.
systemctl disable --now tuned.service 2>/dev/null

echo "== Sane CPU energy policy =="
# Valid on both intel_pstate and amd-pstate. Anything unsupported is skipped.
is_intel_pstate || c_warn "intel_pstate not in use (vendor: $(cpu_vendor)) - applying anyway"
# 'powersave' is the CORRECT intel_pstate governor on a laptop. It still
# reaches full turbo on demand; it just doesn't sprint there to run `ls`.
for c in /sys/devices/system/cpu/cpu*/cpufreq; do
  echo powersave           > "$c/scaling_governor"              2>/dev/null
  echo balance_performance > "$c/energy_performance_preference"  2>/dev/null
done

echo "== zram-correct swappiness =="
# 150 is right for COMPRESSED swap (zram). On a plain disk swap partition it
# would be far too aggressive, so only apply it when zram is actually present.
if has_zram; then
  echo 'vm.swappiness=150' > /etc/sysctl.d/99-zram-swappiness.conf
  sysctl -w vm.swappiness=150 >/dev/null
  c_ok "swappiness 150 (zram)"
else
  c_warn "no zram - leaving swappiness alone"
fi

echo "== Battery charge limit 80% =="
# Desktops have no battery; many laptops do not expose a threshold at all.
BAT="$(battery_path)"
if [ -n "$BAT" ] && [ -w "$BAT/charge_control_end_threshold" ]; then
  echo 80 > "$BAT/charge_control_end_threshold"
  cat > /etc/systemd/system/battery-charge-limit.service <<UNIT
[Unit]
Description=Limit battery charge to 80%
After=multi-user.target
[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 80 > $BAT/charge_control_end_threshold'
[Install]
WantedBy=multi-user.target
UNIT
  systemctl enable battery-charge-limit.service 2>/dev/null
  c_ok "charge limit 80% on $(basename "$BAT")"
elif [ -z "$BAT" ]; then
  c_warn "no battery detected (desktop?) - skipping charge limit"
else
  c_warn "this machine exposes no charge threshold - skipping"
fi

echo
echo "governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "EPP     : $(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference)"
echo "profile : $(powerprofilesctl get 2>/dev/null)"
echo
echo "IMPORTANT: power-profiles-daemon may come up on 'performance' after a"
echo "reboot, which undoes the EPP above. Pin it with the user autostart entry"
echo "installed by 05-shortcuts.sh, or run: powerprofilesctl set balanced"
