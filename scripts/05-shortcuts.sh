#!/usr/bin/env bash
# 05 - macOS-STYLE GNOME SHORTCUTS (no keyd needed for these)
# Run as your NORMAL USER: bash 05-shortcuts.sh
set -uo pipefail
[ "$EUID" -eq 0 ] && { echo "run as your normal user, NOT sudo"; exit 1; }

echo "== Screenshots (macOS Cmd+Shift+3/4/5) =="
gsettings set org.gnome.shell.keybindings screenshot            "['<Shift><Super>3']"
gsettings set org.gnome.shell.keybindings show-screenshot-ui    "['<Shift><Super>4', '<Shift><Super>5']"
gsettings set org.gnome.shell.keybindings screenshot-window     "['<Shift><Super>6']"
gsettings set org.gnome.shell.keybindings show-screen-recording-ui "['<Shift><Control><Super>5']"

echo "== Mission Control / Spotlight / Launchpad =="
gsettings set org.gnome.shell.keybindings toggle-overview         "['<Control>Up', '<Super>space']"
gsettings set org.gnome.shell.keybindings toggle-application-view "['<Shift><Super>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source          "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"

echo "== Spaces (macOS Ctrl+Left/Right) =="
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left  "['<Control>Left']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Control>Right']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left    "['<Control><Shift>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right   "['<Control><Shift>Right']"

echo "== Window tiling on Ctrl+Super+arrows =="
# Super+arrows are reserved for macOS-style text navigation in 06-keyd.sh
gsettings set org.gnome.desktop.wm.keybindings maximize   "['<Control><Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Control><Super>Down']"
gsettings set org.gnome.mutter.keybindings toggle-tiled-left  "['<Control><Super>Left']"
gsettings set org.gnome.mutter.keybindings toggle-tiled-right "['<Control><Super>Right']"

echo "== Free Super+V for the clipboard manager =="
gsettings set org.gnome.shell.keybindings toggle-message-tray "['<Super>m']"

echo "== Night Light =="
gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true

echo "== Pin the balanced power profile across reboots =="
# power-profiles-daemon can come up on 'performance', which re-breaks thermals.
mkdir -p "$HOME/.config/autostart"
cat > "$HOME/.config/autostart/set-balanced-profile.desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=Set balanced power profile
Exec=powerprofilesctl set balanced
X-GNOME-Autostart-enabled=true
NoDisplay=true
DESK
powerprofilesctl set balanced 2>/dev/null
echo "done"
