#!/usr/bin/env bash
# 06 - macOS Cmd-KEY LAYER via keyd  (OPTIONAL, most invasive step)
#
#  !!! SAFETY: if the keyboard misbehaves, press BACKSPACE+ESCAPE+ENTER
#  !!! together - that kills keyd instantly.
#  !!! Remove entirely: sudo systemctl disable --now keyd
#
# Run with: sudo bash 06-keyd.sh
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
require_root
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null)}"

echo "== Installing keyd =="
# keyd is NOT in Fedora's repos. The COPRs for it are unreliable (dead
# repodata / empty / wrong Fedora release), so build from source - it is a
# small C program with no real dependencies.
if ! command -v keyd >/dev/null; then
  dnf install -y gcc make git
  tmp=$(mktemp -d); git clone --depth=1 https://github.com/rvaiya/keyd.git "$tmp/keyd"
  ( cd "$tmp/keyd" && make && make install )
  rm -rf "$tmp"
fi
keyd --version

echo "== Writing the macOS key layer =="
mkdir -p /etc/keyd
[ -f /etc/keyd/default.conf ] && cp /etc/keyd/default.conf /etc/keyd/default.conf.bak
cp "$(dirname "$0")/../conf/keyd-default.conf" /etc/keyd/default.conf

echo "== Validating BEFORE starting =="
# Use the EXIT CODE. Do NOT grep for "error" - that matches keyd's own
# success message, "No errors found."
if ! keyd check; then echo "CONFIG INVALID - not starting"; exit 1; fi

systemctl enable --now keyd
systemctl restart keyd
sleep 1
echo "keyd: $(systemctl is-active keyd)"

echo "== GNOME overlay-key must be disabled =="
# keyd's own macos.conf warns: Meta emitted by keyd gets swallowed by the
# tap-Super-for-Activities behaviour.
as_user gsettings set org.gnome.mutter overlay-key '' 2>/dev/null

echo "== Point the terminal at the clipboard media keys =="
# ONLY once keyd is confirmed running. Doing this earlier removes
# Ctrl+Shift+C/V with nothing to replace them = no copy/paste at all.
if systemctl is-active --quiet keyd; then
  set_terminal_clipboard 'XF86Copy' 'XF86Paste'
  echo "  Ctrl+C is untouched and still interrupts."
else
  c_warn "keyd not running - leaving Ctrl+Shift+C/V alone so you always have copy/paste"
fi

cat <<'MSG'

DONE. Super now acts as Cmd.
  Super+C/V/X  copy/paste/cut (via XF86 media keys, so Ctrl+C stays SIGINT)
  Super+L      still locks the screen (deliberately not remapped)
  PANIC KEY    Backspace + Escape + Enter

If you ever remove keyd, restore the terminal bindings or you will have none:
  gsettings set org.gnome.Ptyxis.Shortcuts copy-clipboard '<Control><Shift>c'
  gsettings set org.gnome.Ptyxis.Shortcuts paste-clipboard '<Control><Shift>v'
MSG
