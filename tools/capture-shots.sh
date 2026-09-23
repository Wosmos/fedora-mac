#!/usr/bin/env bash
# Guided capture of the before/after screenshots used on the landing page.
#
# GNOME 47+ blocks programmatic screenshots (org.gnome.Shell.Screenshot returns
# AccessDenied to non-portal callers), so this walks you through taking them
# yourself and files them with the right names.
#
#   bash tools/capture-shots.sh
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
require_user

OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/site/assets/shots"
SHOTS="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
mkdir -p "$OUT"

c_head "How this works"
cat <<'TXT'
  For each shot: press the key shown, capture, then press Enter here.
  The newest file in your Screenshots folder gets moved and renamed.

  Screenshot keys (set by 05-shortcuts.sh):
    Shift+Super+3   whole screen
    Shift+Super+4   select a region
TXT

grab() {
  local name="$1" desc="$2" key="${3:-Shift+Super+4}"
  echo
  printf '\033[1m%s\033[0m\n' "$desc"
  printf '  press \033[36m%s\033[0m, capture, then Enter here (or s to skip): ' "$key"
  read -r ans
  [ "$ans" = "s" ] && { c_warn "skipped $name"; return; }
  local latest
  latest=$(ls -t "$SHOTS"/*.png 2>/dev/null | head -1)
  if [ -z "$latest" ]; then c_no "no screenshot found in $SHOTS"; return; fi
  cp "$latest" "$OUT/$name.png"
  # keep the page light - cap width and strip metadata
  if have magick; then
    magick "$OUT/$name.png" -resize '1600>' -strip -quality 88 "$OUT/$name.png" 2>/dev/null
  fi
  c_ok "$name.png  ($(du -h "$OUT/$name.png" | cut -f1))"
}

c_head "AFTER shots - your desktop as it is now"
grab after-desktop  "Desktop with the dock visible and a window open" "Shift+Super+3"
grab after-overview "Activities overview (press Ctrl+Up first)"       "Shift+Super+3"
grab after-files    "Files window"                                     "Shift+Super+4"
grab after-terminal "Terminal with the blur showing"                   "Shift+Super+4"
grab after-settings "Settings window"                                  "Shift+Super+4"

c_head "BEFORE shots - stock GTK, no session changes"
cat <<'TXT'
  These launch apps with Fedora's default theming while leaving your
  session completely alone. Run each command, screenshot the window,
  then close it.
TXT
echo
echo "    GTK_THEME=Adwaita:dark nautilus"
echo "    GTK_THEME=Adwaita:dark gnome-text-editor"
echo
grab before-files    "Nautilus launched with GTK_THEME=Adwaita:dark"    "Shift+Super+4"
grab before-editor   "Text editor launched with GTK_THEME=Adwaita:dark" "Shift+Super+4"

c_head "Done"
ls -la "$OUT" 2>/dev/null | tail -n +2 | awk '{printf "  %-28s %s\n", $NF, $5}'
cat <<'TXT'

  A true "stock Fedora desktop" shot needs a machine in that state - a VM or
  live ISO. The GTK_THEME trick above gives genuine stock app windows without
  touching your session, which is the honest half of the comparison.

  Commit whatever you captured; the page shows only the pairs that exist.
TXT
