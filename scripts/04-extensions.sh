#!/usr/bin/env bash
# 04 - GNOME EXTENSIONS (installed straight from extensions.gnome.org)
# Run as your NORMAL USER: bash 04-extensions.sh
# Then LOG OUT AND BACK IN, and run it again to enable them.
set -uo pipefail
[ "$EUID" -eq 0 ] && { echo "run as your normal user, NOT sudo"; exit 1; }
SHELL_VER=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
echo "GNOME Shell $SHELL_VER"

# pk numbers from extensions.gnome.org
EXTS="
307:dash-to-dock
19:user-themes
615:appindicator
3193:blur-my-shell
9529:magnific-launcher
9668:rounded-window-corners
1460:vitals
7065:tiling-shell
517:caffeine
8912:text-extractor
779:clipboard-indicator
2236:night-theme-switcher
"

install_ext() {
  local pk="$1" label="$2"
  local info url uuid
  info=$(curl -s "https://extensions.gnome.org/extension-info/?pk=${pk}&shell_version=${SHELL_VER}")
  uuid=$(echo "$info" | python3 -c "import sys,json;print(json.load(sys.stdin).get('uuid',''))" 2>/dev/null)
  url=$(echo "$info"  | python3 -c "import sys,json;print(json.load(sys.stdin).get('download_url') or '')" 2>/dev/null)
  if [ -z "$url" ]; then echo "  SKIP $label - no build for GNOME $SHELL_VER"; return; fi
  local tmp; tmp=$(mktemp -d)
  curl -sL -o "$tmp/e.zip" "https://extensions.gnome.org${url}"
  gnome-extensions install --force "$tmp/e.zip" >/dev/null 2>&1 \
    && echo "  ok   $label ($uuid)" || echo "  FAIL $label"
  gnome-extensions enable "$uuid" 2>/dev/null
  rm -rf "$tmp"
}

echo "== Installing =="
for row in $EXTS; do install_ext "${row%%:*}" "${row##*:}"; done

echo
echo "== Configuring =="
CI="$HOME/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/schemas"
if [ -d "$CI" ]; then
  g() { gsettings --schemadir "$CI" set org.gnome.shell.extensions.clipboard-indicator "$@"; }
  # NOTE: Shift+Super+V is unreliable when keyd is running (see 06-keyd.sh).
  # Ctrl+Alt+V bypasses keyd entirely, so bind BOTH.
  g toggle-menu "['<Shift><Super>v', '<Control><Alt>v']"
  g history-size 50; g cache-size 20
  g move-item-first true; g open-at-cursor true; g show-search-bar true
  g excluded-apps "['Bitwarden','1Password','KeePassXC','org.keepassxc.KeePassXC','org.gnome.World.Secrets','Proton Pass']"
fi

BMS=/org/gnome/shell/extensions/blur-my-shell
# Live gaussian blur is expensive on integrated graphics. Static panel blur
# keeps the look for a fraction of the GPU cost.
dconf write $BMS/panel/static-blur true
dconf write $BMS/panel/sigma 10
dconf write $BMS/overview/sigma 10
dconf write $BMS/window-list/blur false
dconf write $BMS/appfolder/blur false
dconf write $BMS/applications/blur true
dconf write $BMS/applications/sigma 15
dconf write $BMS/applications/whitelist "['org.gnome.Ptyxis','com.mitchellh.ghostty','com.raggesilver.BlackBox','org.gnome.Nautilus']"

D2D=/org/gnome/shell/extensions/dash-to-dock
dconf write $D2D/dock-position "'BOTTOM'"
dconf write $D2D/dash-max-icon-size 48
dconf write $D2D/autohide true
dconf write $D2D/intellihide true
dconf write $D2D/running-indicator-style "'DOTS'"
dconf write $D2D/transparency-mode "'DYNAMIC'"
dconf write $D2D/show-trash false
dconf write $D2D/show-mounts false

echo
echo "IMPORTANT: 'enabled' is NOT 'running'. Verify with:"
echo "  for e in \$(gnome-extensions list); do echo \"\$e \$(gnome-extensions info \$e | awk -F': ' '/State/{print \$2}')\"; done"
echo "Anything showing OUT OF DATE will silently do nothing."
