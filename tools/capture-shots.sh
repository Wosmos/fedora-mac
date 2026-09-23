#!/usr/bin/env bash
# Generate the before/after screenshots used on the landing page.
#
# Renders the SAME GTK3 application twice - once with Fedora's stock
# Adwaita theme, once with WhiteSur - and captures each window. Both halves
# are real, taken on the same machine at the same size.
#
# Why GTK3 only: GTK4/libadwaita applications hardcode their own stylesheet
# and ignore GTK_THEME, so they cannot show a stock-versus-themed difference.
# (Nautilus, Text Editor and Calculator are all GTK4 - they will not work here.)
#
# Why not just screenshot the desktop: GNOME 47+ denies
# org.gnome.Shell.Screenshot to non-portal callers, so a script cannot drive it.
# Capturing individual X windows through XWayland does work, which is what
# this does.
#
#   bash tools/capture-shots.sh
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
require_user
require_cmds xprop import magick

OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/site/assets/shots"
mkdir -p "$OUT"
[ -n "${DISPLAY:-}" ] || die "no DISPLAY - XWayland is required for window capture"

shoot() {                      # shoot <outfile> <theme> <app> [args...]
  local out="$1" theme="$2" app="$3"; shift 3
  have "$app" || { c_warn "$app not installed - skipping"; return 1; }

  env GDK_BACKEND=x11 GTK_THEME="$theme" "$app" "$@" >/dev/null 2>&1 &
  local pid=$! win="" id wpid
  for _ in $(seq 1 30); do
    sleep 1
    for id in $(xprop -root _NET_CLIENT_LIST 2>/dev/null | grep -oE '0x[0-9a-f]+'); do
      wpid=$(xprop -id "$id" _NET_WM_PID 2>/dev/null | grep -oE '[0-9]+$')
      [ -n "$wpid" ] || continue
      if [ "$wpid" = "$pid" ] || [ "$(ps -o ppid= -p "$wpid" 2>/dev/null | tr -d ' ')" = "$pid" ]; then
        win="$id"; break
      fi
    done
    [ -n "$win" ] && break
  done
  if [ -z "$win" ]; then c_no "no window appeared for $app"; kill "$pid" 2>/dev/null; return 1; fi

  sleep 3                       # let it finish drawing
  import -window "$win" "$out" 2>/dev/null
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  # trim the black the compositor leaves around the shadow, then shrink
  magick "$out" -bordercolor black -border 1 -fuzz 2% -trim +repage \
         -resize '1200>' -strip -define png:compression-level=9 "$out" 2>/dev/null
  c_ok "$(basename "$out")  $(identify -format '%wx%h' "$out" 2>/dev/null)"
}

# a comparison slider needs both halves at identical dimensions
normalise() {
  local b="$1" a="$2" w h
  [ -f "$b" ] && [ -f "$a" ] || return 0
  w=$(identify -format '%w' "$b"); h=$(identify -format '%h' "$b")
  magick "$a" -resize "${w}x${h}!" -strip "$a"
  c_ok "matched to ${w}x${h}"
}

c_head "Pair 1 — dconf Editor"
shoot "$OUT/before-app.png" "Adwaita:dark"  dconf-editor
shoot "$OUT/after-app.png"  "WhiteSur-Dark" dconf-editor
normalise "$OUT/before-app.png" "$OUT/after-app.png"

c_head "Pair 2 — Connections"
shoot "$OUT/before-window.png" "Adwaita:dark"  gnome-connections
shoot "$OUT/after-window.png"  "WhiteSur-Dark" gnome-connections
normalise "$OUT/before-window.png" "$OUT/after-window.png"

c_head "Result"
ls -la "$OUT" 2>/dev/null | tail -n +4 | awk '{printf "  %-22s %s bytes\n", $NF, $5}'
echo
echo "  Windows will flash on screen while this runs - that is expected."
echo "  Commit site/assets/shots/ to publish them."
