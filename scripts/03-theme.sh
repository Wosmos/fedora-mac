#!/usr/bin/env bash
# 03 - macOS LOOK (WhiteSur theme, icons, cursors, fonts, wallpaper, sounds)
# Run as your NORMAL USER: bash 03-theme.sh
set -uo pipefail
[ "$EUID" -eq 0 ] && { echo "run as your normal user, NOT sudo"; exit 1; }
SRC="$HOME/Downloads/whitesur"; mkdir -p "$SRC"

clone_or_update() {
  local url="$1" dir="$SRC/$2"
  if [ -d "$dir/.git" ]; then git -C "$dir" fetch --depth=50 -q origin && git -C "$dir" merge --ff-only -q origin/HEAD 2>/dev/null || git -C "$dir" merge --ff-only -q origin/master 2>/dev/null
  else git clone --depth=1 -q "$url" "$dir"; fi
}

echo "== Fetching WhiteSur sources =="
# CRITICAL: a stale clone silently produces a half-broken shell theme.
# The installer prints the GNOME version it detects - CHECK IT.
clone_or_update https://github.com/vinceliuice/WhiteSur-gtk-theme.git  WhiteSur-gtk-theme
clone_or_update https://github.com/vinceliuice/WhiteSur-icon-theme.git WhiteSur-icon-theme
clone_or_update https://github.com/vinceliuice/WhiteSur-cursors.git    WhiteSur-cursors

echo "== Installing GTK theme (dark + libadwaita/GTK4 support) =="
( cd "$SRC/WhiteSur-gtk-theme" && ./install.sh -c dark -l )

echo "== Icons + cursors =="
( cd "$SRC/WhiteSur-icon-theme" && ./install.sh -d "$HOME/.local/share/icons" )
( cd "$SRC/WhiteSur-cursors"    && ./install.sh 2>/dev/null )

echo "== Applying =="
gsettings set org.gnome.desktop.interface gtk-theme     'WhiteSur-Dark'
gsettings set org.gnome.desktop.interface icon-theme    'WhiteSur-dark'
gsettings set org.gnome.desktop.interface cursor-theme  'WhiteSur-cursors'
gsettings set org.gnome.desktop.interface color-scheme  'prefer-dark'
# Shell theme lives in the user-theme extension's own schema, so use dconf.
dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-Dark'"

echo "== Fonts (Inter is the closest free match to SF Pro) =="
gsettings set org.gnome.desktop.interface font-name            'Inter 11'
gsettings set org.gnome.desktop.interface document-font-name   'Inter 11'
gsettings set org.gnome.desktop.interface monospace-font-name  'JetBrainsMono Nerd Font Mono 11'
gsettings set org.gnome.desktop.wm.preferences titlebar-font   'Inter Semi-Bold 11'
gsettings set org.gnome.desktop.interface font-hinting          'slight'
gsettings set org.gnome.desktop.interface font-antialiasing     'rgba'
# macOS puts window buttons on the left
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

echo "== Wallpaper =="
mkdir -p "$HOME/.local/share/backgrounds"
cp "$SRC/WhiteSur-gtk-theme/other/gdm/theme/background.png" \
   "$HOME/.local/share/backgrounds/whitesur-bigsur.png" 2>/dev/null
W="file://$HOME/.local/share/backgrounds/whitesur-bigsur.png"
gsettings set org.gnome.desktop.background picture-uri      "$W"
gsettings set org.gnome.desktop.background picture-uri-dark "$W"
gsettings set org.gnome.desktop.background picture-options  'zoom'

echo "== macOS system sounds =="
S="$SRC/macos-sounds"
[ -d "$S/.git" ] || git clone --depth=1 -q https://github.com/gxanshu/macos-bigsur-sound-theme-linux.git "$S"
mkdir -p "$HOME/.local/share/sounds"
rm -rf "$HOME/.local/share/sounds/bigsur"
cp -r "$S/theme/bigsur" "$HOME/.local/share/sounds/"
gsettings set org.gnome.desktop.sound theme-name 'bigsur'
gsettings set org.gnome.desktop.sound event-sounds true

echo
echo "== Display: 100% scale + larger text beats fractional scaling =="
echo "   Fractional scaling makes the GPU render large then downscale every"
echo "   frame. On weak integrated graphics prefer 100% + text scaling:"
gsettings set org.gnome.desktop.interface text-scaling-factor 1.15
echo "   Then set Display scale to 100% in Settings > Displays."
echo
echo "OPTIONAL - themed login screen (needs sudo, reversible with -r):"
echo "   sudo $SRC/WhiteSur-gtk-theme/tweaks.sh -g"
echo "OPTIONAL - Safari-like Firefox (close Firefox first):"
echo "   $SRC/WhiteSur-gtk-theme/tweaks.sh -f monterey"
