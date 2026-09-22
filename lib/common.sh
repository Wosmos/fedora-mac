#!/usr/bin/env bash
# Shared guards and helpers. Sourced by every script.
# shellcheck shell=bash

c_ok(){   printf '  \033[32m✓\033[0m %s\n' "$*"; }
c_no(){   printf '  \033[31m✗\033[0m %s\n' "$*"; }
c_warn(){ printf '  \033[33m!\033[0m %s\n' "$*"; }
c_head(){ printf '\n\033[1m== %s ==\033[0m\n' "$*"; }
die(){ printf '\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

have(){ command -v "$1" >/dev/null 2>&1; }

require_root(){ [ "$EUID" -eq 0 ] || die "run this with sudo"; }
require_user(){ [ "$EUID" -ne 0 ] || die "run this as your NORMAL user, not sudo"; }

# The invoking human, even under sudo.
real_user(){ echo "${SUDO_USER:-${USER:-$(id -un)}}"; }
real_home(){ getent passwd "$(real_user)" | cut -d: -f6; }

# Run a command as the real user (works whether or not we are root).
as_user(){
  if [ "$EUID" -eq 0 ]; then sudo -u "$(real_user)" "$@"
  else "$@"; fi
}

require_fedora(){
  [ -r /etc/os-release ] || die "cannot read /etc/os-release"
  . /etc/os-release
  [ "${ID:-}" = "fedora" ] || die "this targets Fedora; found '${ID:-unknown}'"
}

require_gnome(){
  have gnome-shell || die "GNOME Shell not found"
}

warn_not_wayland(){
  [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || \
    c_warn "session is '${XDG_SESSION_TYPE:-unknown}', not wayland - some steps may differ"
}

gnome_major(){ gnome-shell --version 2>/dev/null | grep -oE '[0-9]+' | head -1; }

require_net(){
  curl -sSf --max-time 10 -o /dev/null https://api.github.com 2>/dev/null \
    || die "no network (or GitHub unreachable) - this script downloads things"
}

require_cmds(){
  local missing=()
  for c in "$@"; do have "$c" || missing+=("$c"); done
  [ ${#missing[@]} -eq 0 ] || die "missing required command(s): ${missing[*]}"
}

# --- hardware / layout detection -------------------------------------------
has_battery(){ compgen -G "/sys/class/power_supply/BAT*" >/dev/null 2>&1; }
battery_path(){ ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1; }
cpu_vendor(){ awk -F': ' '/vendor_id/{print $2; exit}' /proc/cpuinfo; }
is_intel_pstate(){ [ -d /sys/devices/system/cpu/intel_pstate ]; }
root_is_btrfs(){ [ "$(findmnt -no FSTYPE / 2>/dev/null)" = "btrfs" ]; }
has_zram(){ [ -e /dev/zram0 ]; }

# Which GNOME terminal is installed? Used for clipboard keybindings.
detect_terminal(){
  if   have ptyxis;        then echo "ptyxis"
  elif have kgx;           then echo "console"
  elif have gnome-terminal;then echo "gnome-terminal"
  else echo "unknown"; fi
}

# Set the terminal's copy/paste shortcuts, whichever terminal is present.
set_terminal_clipboard(){
  local copy="$1" paste="$2"
  case "$(detect_terminal)" in
    ptyxis)
      as_user gsettings set org.gnome.Ptyxis.Shortcuts copy-clipboard  "$copy"  2>/dev/null
      as_user gsettings set org.gnome.Ptyxis.Shortcuts paste-clipboard "$paste" 2>/dev/null
      c_ok "Ptyxis clipboard -> $copy / $paste" ;;
    *)
      c_warn "terminal is '$(detect_terminal)' - set its copy/paste shortcuts yourself" ;;
  esac
}

# gsettings against an extension's private schema dir.
ext_set(){
  local uuid="$1" schema="$2" key="$3" val="$4"
  local dir; dir="$(real_home)/.local/share/gnome-shell/extensions/$uuid/schemas"
  [ -d "$dir" ] || return 0
  as_user gsettings --schemadir "$dir" set "$schema" "$key" "$val" 2>/dev/null
}

# Only set a gsettings key if the schema/key actually exists.
safe_set(){
  local schema="$1" key="$2" val="$3"
  gsettings writable "$schema" "$key" >/dev/null 2>&1 || { c_warn "skip $schema $key (not present)"; return 0; }
  gsettings set "$schema" "$key" "$val" 2>/dev/null
}
