#!/usr/bin/env bash
# Orchestrator. Runs the scripts in the right order with the right privileges.
#   bash install.sh          - everything except keyd
#   bash install.sh --keyd   - include the Cmd-key layer
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
[ "$EUID" -eq 0 ] && { echo "Run as your NORMAL user. It will sudo when needed."; exit 1; }

run_user() { echo; echo "### $1"; bash "$D/$1"; }
run_root() { echo; echo "### $1 (sudo)"; sudo bash "$D/$1"; }

run_user 00-preflight.sh
run_root 01-performance.sh
run_root 02-packages.sh
run_user 03-theme.sh
run_user 04-extensions.sh
run_user 05-shortcuts.sh
run_user 07-voice-sounds.sh
run_root 08-snapshots.sh
[ "${1:-}" = "--keyd" ] && run_root 06-keyd.sh

cat <<'MSG'

=============================================================
 LOG OUT AND BACK IN NOW.
 Wayland cannot load new extensions into a running shell.

 Then run 04-extensions.sh a second time to enable them, and
 verify nothing is silently dead:

   for e in $(gnome-extensions list); do
     echo "$e $(gnome-extensions info $e | awk -F': ' '/State/{print $2}')"
   done

 Anything OUT OF DATE is not running, no matter what the
 enabled list says.
=============================================================
MSG
