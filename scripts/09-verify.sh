#!/usr/bin/env bash
# 09 - VERIFY. Read-only. Run any time to see what is and is not in place.
#   bash 09-verify.sh
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
FAIL=0
chk(){ if eval "$2" >/dev/null 2>&1; then c_ok "$1"; else c_no "$1"; FAIL=$((FAIL+1)); fi; }

c_head "System"
. /etc/os-release 2>/dev/null
echo "  $PRETTY_NAME | GNOME $(gnome_major) | ${XDG_SESSION_TYPE:-?} | $(cpu_vendor)"
echo "  root fs: $(findmnt -no FSTYPE / 2>/dev/null) | zram: $(has_zram && echo yes || echo no) | battery: $(has_battery && echo yes || echo no)"

c_head "Performance (the part that matters)"
gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
epp=$(cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference 2>/dev/null)
chk "governor is powersave (not 'performance')"     "[ '$gov' = powersave ]"
chk "EPP is balance_performance"                    "[ '$epp' = balance_performance ]"
chk "no cpu-tune udev rule"                         "[ ! -f /etc/udev/rules.d/99-cpu-tune.rules ]"
chk "no cpu-tune service"                           "[ ! -f /etc/systemd/system/cpu-tune.service ]"
chk "power-profiles-daemon active"                  "systemctl is-active --quiet power-profiles-daemon"
chk "tuned NOT fighting it"                         "! systemctl is-active --quiet tuned"
chk "no failed systemd units"                       "[ \$(systemctl --failed --no-legend | wc -l) -eq 0 ]"

up=$(awk '{print int($1)}' /proc/uptime)
ms=$(cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_total_time_ms 2>/dev/null || echo 0)
pct=$(( up > 0 ? ms/10/up : 0 ))
echo "  throttled ${pct}% of wall clock | $(sensors 2>/dev/null | awk '/Package id 0/{print $4}') | fan $(sensors 2>/dev/null | awk '/fan1/{print $2}') RPM"
[ "$pct" -le 5 ] && c_ok "throttling under control" || { c_no "THROTTLING ${pct}% - see docs/TROUBLESHOOTING.md"; FAIL=$((FAIL+1)); }

c_head "Look"
chk "GTK theme is WhiteSur"      "gsettings get org.gnome.desktop.interface gtk-theme | grep -qi whitesur"
chk "shell theme is WhiteSur"    "dconf read /org/gnome/shell/extensions/user-theme/name | grep -qi whitesur"
chk "Inter UI font"              "gsettings get org.gnome.desktop.interface font-name | grep -qi inter"
chk "animations on"              "[ \$(gsettings get org.gnome.desktop.interface enable-animations) = true ]"
chk "macOS sound theme"          "gsettings get org.gnome.desktop.sound theme-name | grep -qi bigsur"
chk "window buttons on the left" "gsettings get org.gnome.desktop.wm.preferences button-layout | grep -q '^.close'"

c_head "Extensions (State, not the enabled list)"
dead=0
enabled=$(gnome-extensions list --enabled 2>/dev/null)
for e in $(gnome-extensions list 2>/dev/null); do
  st=$(gnome-extensions info "$e" 2>/dev/null | awk -F': *' '/State/{print $2}')
  if [ "$st" = "OUT OF DATE" ]; then
    if echo "$enabled" | grep -qx "$e"; then
      c_no "$e is ENABLED but OUT OF DATE - it will never run"; dead=$((dead+1))
    else
      c_warn "$e is out of date but disabled (harmless)"
    fi
  fi
done
[ "$dead" -eq 0 ] && c_ok "nothing enabled-but-dead"

c_head "Shortcuts"
chk "screenshot on Shift+Super+3" "gsettings get org.gnome.shell.keybindings screenshot | grep -q 'Shift><Super>3'"
chk "Mission Control on Ctrl+Up"  "gsettings get org.gnome.shell.keybindings toggle-overview | grep -q 'Control>Up'"
CISCHEMA="$(real_home)/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/schemas"
chk "clipboard history bound"     "gsettings --schemadir '$CISCHEMA' get org.gnome.shell.extensions.clipboard-indicator toggle-menu | grep -q 'Control><Alt>v'"

c_head "Voice"
PIPERBIN="$(real_home)/.local/share/piper-venv/bin/piper"
chk "piper engine present"   "[ -x '$PIPERBIN' ]"
VOICEDIR="$(real_home)/.local/share/piper-voices"
chk "voice models present"   "ls '$VOICEDIR'/*.onnx"
chk "piper is the default TTS" "spd-say -O 2>/dev/null | grep -q piper"

c_head "Safety net"
chk "snapper configured" "[ -f /etc/snapper/configs/root ]"
chk "snapshot timer on"  "systemctl is-enabled --quiet snapper-timeline.timer"
chk "a real backup tool" "rpm -q pika-backup"
chk "hw video decode verifiable" "rpm -q libva-utils"
chk "dnf tuned for speed" "grep -q max_parallel /etc/dnf/dnf.conf"

c_head "Optional"
have keyd && c_ok "keyd $(keyd --version 2>/dev/null | head -1) - $(systemctl is-active keyd)" || c_warn "keyd not installed (Super-as-Cmd unavailable)"

echo
if [ "$FAIL" -eq 0 ]; then printf '\033[32mAll checks passed.\033[0m\n'
else printf '\033[31m%s check(s) failed.\033[0m See docs/TROUBLESHOOTING.md\n' "$FAIL"; fi
