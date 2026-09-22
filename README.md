# Fedora → macOS-like Setup

Reproducible setup for a Fedora GNOME/Wayland workstation: macOS look and feel,
natural text-to-speech, macOS-style keyboard shortcuts, and — most importantly — a
set of performance fixes that make an older laptop stop thermal-throttling.

Built and verified on a **Dell Latitude 5400** (i7-8665U, UHD 620, 16 GB, btrfs-on-LUKS)
running **Fedora 44 / GNOME Shell 50.1 / Wayland**.

---

## The headline result

The biggest win here has nothing to do with theming. The reference machine was
being throttled by its own CPU governor:

| | Before | After |
|---|---|---|
| Idle CPU clock | 400 MHz **or** 4.2–4.8 GHz, nothing between | 400–1100 MHz, proper intermediate steps |
| Idle package temp | 82–89 °C | **51–61 °C** |
| Time spent thermally throttled | **26–27% of wall clock** | **0%** |
| Fan at idle | 3500 RPM | 0 RPM |

Cause: a `performance` CPU governor plus `energy_performance_preference=performance`
on a 15 W laptop chip. It sprinted to maximum turbo for trivial work, exceeded its
thermal headroom in milliseconds, got cut by PROCHOT, and repeated — thousands of
times per second.

**If your machine feels laggy, run `00-preflight.sh` and look at the throttle
percentage before you blame anything else.**

---

## Quick start

```bash
git clone <this-repo> ~/fedora-macos-setup
cd ~/fedora-macos-setup/scripts
bash install.sh            # everything except the Cmd-key layer
bash install.sh --keyd     # include it
```

Run as your **normal user** — it calls `sudo` where needed. Then log out and back in.

Every script is idempotent and safe to re-run. To check the result at any point:

```bash
bash scripts/09-verify.sh
```

### Portability

`lib/common.sh` holds shared guards. The scripts refuse to run on a non-Fedora or
non-GNOME system, warn on X11, check for required commands and network before
downloading, and adapt to the machine rather than assuming the reference hardware:

- no battery (desktop) → charge-limit step is skipped
- no zram → swappiness is left alone, because 150 is only correct for compressed swap
- no btrfs → snapshot script exits cleanly
- AMD instead of Intel → warns, then applies the governor settings anyway
- a terminal other than Ptyxis → says so instead of silently doing nothing

No usernames or absolute home paths are baked in; everything resolves the invoking
user even under `sudo`.

---

## What each script does

| Script | Privilege | What it does |
|---|---|---|
| `00-preflight.sh` | user | Backs up all GNOME settings, prints a hardware and **thermal baseline**. Run this first. |
| `01-performance.sh` | **sudo** | The important one. Removes forced-performance tuning, restores `power-profiles-daemon`, sets a sane governor/EPP, zram swappiness, 80% battery limit. |
| `02-packages.sh` | **sudo** | dnf speed config, RPM Fusion, full ffmpeg, hardware video decode, desktop tools, backup software. |
| `03-theme.sh` | user | WhiteSur GTK/shell/icons/cursors, Inter + JetBrains Mono fonts, wallpaper, macOS system sounds. |
| `04-extensions.sh` | user | Installs and configures 12 GNOME extensions straight from extensions.gnome.org. |
| `05-shortcuts.sh` | user | macOS-style GNOME keybindings. No keyd required. |
| `06-keyd.sh` | **sudo** | Optional. Super-as-Cmd across every application. Most invasive step. |
| `07-voice-sounds.sh` | user | Replaces robotic espeak-ng with Piper neural TTS. |
| `08-snapshots.sh` | **sudo** | btrfs snapshot safety net via snapper, with dnf integration. |
| `09-verify.sh` | user | Read-only. Checks every change actually took. Run it any time. |

---

## Shortcut reference

Set by `05-shortcuts.sh`, no keyd needed:

| Key | Action |
|---|---|
| `Shift+Super+3` | Screenshot, full screen |
| `Shift+Super+4` / `5` | Screenshot, select region |
| `Shift+Super+6` | Screenshot, window |
| `Ctrl+Shift+Super+5` | Screen recording |
| `Ctrl+Up` | Mission Control |
| `Super+Space` | Spotlight |
| `Shift+Super+Space` | Launchpad |
| `Ctrl+Left` / `Right` | Switch Spaces |
| `Ctrl+Shift+Left` / `Right` | Move window to Space |
| `Ctrl+Super+arrows` | Tile / maximize |
| `Super+Tab` | App switcher |
| **`Ctrl+Alt+V`** | **Clipboard history** |
| `Super+L` | Lock screen |

Added by `06-keyd.sh`:

| Key | Action |
|---|---|
| `Super+C` / `V` / `X` | Copy / paste / cut — **everywhere, including terminals** |
| `Super+` A Z S F O P N T W R B I U G K J D E Y | The Ctrl equivalents |
| `Super+Left` / `Right` | Start / end of line |
| `Super+Up` / `Down` | Top / bottom of document |
| **`Backspace+Escape+Enter`** | **Panic key — kills keyd instantly** |

---

## The one genuinely clever trick

Making `Cmd+C` work on Linux normally breaks terminals, because remappers send
`Ctrl+C`, which is SIGINT. You lose either copy or interrupt.

keyd instead emits the **`XF86Copy` / `XF86Paste` / `XF86Cut` media keys**. GTK and
Qt handle those natively as clipboard actions, and since `Ctrl+C` is never
transmitted at all, interrupt keeps working untouched. The terminal is then pointed
at those same media keys:

```bash
gsettings set org.gnome.Ptyxis.Shortcuts copy-clipboard  'XF86Copy'
gsettings set org.gnome.Ptyxis.Shortcuts paste-clipboard 'XF86Paste'
```

No compromise on either side.

---

## Hard-won gotchas

Each of these cost real debugging time. They are documented in full in
[`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

1. **"Enabled" is not "running."** `gnome-extensions list --enabled` shows what you
   switched on, not what loaded. An extension whose `shell-version` predates your
   shell reports `State: OUT OF DATE` and silently does nothing. Always check `State`.

2. **keyd compound layers inherit, they do not pass through.** With `[meta] v = paste`
   defined, omitting `v` from `[meta+shift]` does **not** let `Shift+Super+V` through —
   it falls back to `[meta]` and emits `XF86Paste`. Re-emit explicitly: `v = M-S-v`.

3. **Never grep keyd's output for the word "error."** Its success message is
   *"No errors found."* Use the exit code.

4. **Spot temperatures lie.** Sampling `sensors` every 2 s showed a comfortable 61–68 °C
   while the CPU was throttling 27% of the time — the samples landed in the valleys
   between millisecond spikes. Trust `/sys/devices/system/cpu/cpu0/thermal_throttle/`.

5. **The `piper` RPM in Fedora's repos is a gaming-mouse tool**, not the TTS engine.
   Piper TTS is not packaged for Fedora at all.

6. **Never run `pkill -f speech-dispatcher`.** The pattern matches the calling shell's
   own command line and kills your session.

7. **A stale WhiteSur clone silently half-breaks the shell theme.** Its installer
   prints the GNOME version it detected — check that line.

8. **Fractional scaling is expensive on integrated graphics.** 100% scale plus a text
   scaling factor looks the same and costs nothing per frame.

9. **keyd's COPRs are unreliable** (dead repodata, empty repos, wrong Fedora release).
   Build from source.

---

## What this deliberately does not do

- **TPM2 LUKS auto-unlock.** Would cut ~18 s off boot, but a mistake locks you out of
  your own disk. Do it manually, with your passphrase written down first.
- **Ship Apple's assets.** Siri voices and macOS system sounds are proprietary. This
  uses Piper neural voices and a community sound theme instead.

---

## Reverting

```bash
# GNOME settings (from 00-preflight.sh)
dconf load /org/gnome/ < ~/.config/fedora-macos-setup-backup-*/dconf-gnome.ini

# Login screen theme
sudo ~/Downloads/whitesur/WhiteSur-gtk-theme/tweaks.sh -r
sudo dnf reinstall -y gnome-shell          # nuclear option

# keyd
sudo systemctl disable --now keyd
gsettings set org.gnome.Ptyxis.Shortcuts copy-clipboard  '<Control><Shift>c'
gsettings set org.gnome.Ptyxis.Shortcuts paste-clipboard '<Control><Shift>v'

# Voice
rm -rf ~/.config/speech-dispatcher
```

If the login screen ever breaks, `Ctrl+Alt+F3` gets you a text console.

---

## Hardware notes

Software can only go so far on an older laptop:

- **Thermal paste and dust.** On a machine more than a few years old this is usually
  worth more than any software tuning.
- **Battery health.** Check `capacity:` in `upower -i $(upower -e | grep BAT)`. Below
  ~50% of design, replace it.
- **Firmware.** `fwupdmgr get-updates`. The reference machine was 3.5 years behind.
- **RAM.** Check `/proc/pressure/memory` before buying any. If `avg300` is `0.00` and
  swap is unused, more RAM will do nothing at all.
