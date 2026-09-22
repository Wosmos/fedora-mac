# Troubleshooting

Every entry here is a real failure that happened during the original build, with the
diagnosis that actually resolved it.

---

## The machine feels laggy

**Check the throttle counters first.** Not the temperature — the counters.

```bash
cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_count
cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_total_time_ms
awk '{print int($1)}' /proc/uptime
```

If `total_time_ms / 10 / uptime_seconds` is more than a few percent, the CPU is being
throttled and nothing else you tune will matter.

```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
```

On a laptop these should be `powersave` and `balance_performance`. If either says
`performance`, that is the problem. `powersave` on `intel_pstate` is **not** a slow
mode — the chip still reaches full turbo on demand.

Look for things that force it back:

```bash
ls /etc/udev/rules.d/ | grep -i cpu
systemctl list-units --all | grep -i cpu-tune
systemctl is-active tuned power-profiles-daemon
powerprofilesctl get
```

`power-profiles-daemon` can come back on `performance` after a reboot and silently
undo the fix. `05-shortcuts.sh` installs an autostart entry that pins it to balanced.

### Why spot temperatures mislead

Sampling `sensors` every 2 seconds showed a comfortable 61–68 °C while the CPU was
throttled 27% of the time. Throttle events last milliseconds; a 2-second sample lands
in the valleys between them and never sees the spikes. The cumulative counter cannot
be fooled this way.

---

## A GNOME extension's shortcut does nothing

**`gnome-extensions list --enabled` is not proof it is running.** It lists what you
switched on. An extension whose `metadata.json` `shell-version` predates your shell
reports `OUT OF DATE` and never loads — no error, no data files, no keybinding.

```bash
for e in $(gnome-extensions list); do
  echo "$e  $(gnome-extensions info "$e" | awk -F': ' '/State/{print $2}')"
done
```

- `ACTIVE` — running
- `INITIALIZED` — loaded but disabled
- `OUT OF DATE` — will never run on this shell version

This is how Pano appeared to be providing clipboard history for an entire session
while being completely dead. Its newest published build still caps at GNOME 45.

Before debugging keybindings, check whether a build exists for your shell at all:

```bash
curl -s "https://extensions.gnome.org/extension-info/?pk=<PK>&shell_version=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)"
```

---

## A shortcut works in some apps but not others, or not at all (keyd)

### Test with a non-Super combination first

If `Ctrl+Alt+V` works but `Shift+Super+V` does not, the extension is fine and keyd is
the problem. That one test saves a lot of time.

### Compound layers inherit

This is the big one. Given:

```
[meta]
v = paste

[meta+shift]
# v not listed
```

Pressing `Shift+Super+V` does **not** reach the compositor as `Shift+Super+V`. keyd
finds no `v` in `[meta+shift]`, falls back to `[meta]`, and emits `XF86Paste`.
Omission means *inherit*, not *pass through*.

To genuinely pass it on, re-emit it:

```
[meta+shift]
v = M-S-v
```

Modifier letters, from `man keyd`: `C`=Control, `M`=Meta/Super, `A`=Alt, `S`=Shift,
`G`=AltGr.

### GNOME's overlay-key eats synthetic Meta

keyd's own `/usr/local/share/doc/keyd/examples/macos.conf` warns about this. If keyd
emits a Meta press, GNOME can swallow it as the tap-Super-for-Activities trigger:

```bash
gsettings set org.gnome.mutter overlay-key ''
```

### Keep a keyd-proof fallback

GNOME keybinding settings are arrays (`type as`), so bind two shortcuts — one that
routes through keyd and one that cannot:

```bash
gsettings --schemadir <schemas> set <schema> toggle-menu \
  "['<Shift><Super>v', '<Control><Alt>v']"
```

keyd only defines the layers you write. Any combination without Super bypasses it.

### Never grep keyd's output for "error"

```bash
keyd check          # success message is literally "No errors found."
```

A `grep -i error` matches that. Use the exit code:

```bash
if ! keyd check; then echo "invalid"; exit 1; fi
```

### Panic key

`Backspace + Escape + Enter` together terminates keyd. Memorise it before installing.

---

## No copy/paste in the terminal at all

Almost always a half-applied clipboard change. The Ptyxis shortcut is a **single
string**, not a list — setting `XF86Copy` *replaces* `Ctrl+Shift+C` rather than adding
to it. If keyd is not running to emit that media key, nothing works.

```bash
gsettings get org.gnome.Ptyxis.Shortcuts copy-clipboard
systemctl is-active keyd
```

- keyd running → `XF86Copy` is correct
- keyd not running → restore `<Control><Shift>c` / `<Control><Shift>v`

Change both halves together, or not at all.

---

## The voice is robotic

That is `espeak-ng`, a formant synthesiser. Replace it with Piper (`07-voice-sounds.sh`).

```bash
spd-say -O    # output modules; should list piper-generic
spd-say -L    # voices; should list only the neural ones
```

**The `piper` RPM in Fedora's repos is a gaming-mouse configuration tool.** Installing
it does nothing for speech. Piper TTS is not packaged for Fedora at all.

**Never run `pkill -f speech-dispatcher`** — the pattern matches the calling shell's
own command line and kills your session. Use `systemctl --user`.

---

## The theme looks half-broken

Almost certainly a stale WhiteSur clone. GNOME 50 support landed in July 2026; a clone
from before that produces a shell theme with no error and visible breakage.

```bash
cd ~/Downloads/whitesur/WhiteSur-gtk-theme
git log -1 --format='%h %ad' --date=short
git fetch --depth=50 origin && git merge --ff-only origin/master
./install.sh -c dark -l
```

**The installer prints the GNOME version it detected.** Check that line says your
actual version.

Also note: GNOME's own apps use libadwaita, which does not support custom themes. The
`-l` flag installs a workaround its author calls imperfect. Settings and parts of Files
will never fully match.

---

## The login screen is broken

```bash
sudo ~/Downloads/whitesur/WhiteSur-gtk-theme/tweaks.sh -r
sudo dnf reinstall -y gnome-shell      # if that fails
```

`Ctrl+Alt+F3` gets you a text console if you cannot reach a desktop.

To check whether the theme is applied:

```bash
rpm -V gnome-shell | grep gresource    # output = modified = theme applied
ls -la /usr/share/gnome-shell/gnome-shell-theme.gresource.bak
```

---

## The spinning cursor gets stuck

Known upstream bug on GNOME 50 / Wayland — not a theme problem.
<https://bugzilla.redhat.com/show_bug.cgi?id=2458185>

The global `CLUTTER_CURSOR_WAIT` state overrides the cursor shape the focused client
requests, so it never gets restored after startup notification completes. Fix is
mutter MR !5023, awaiting backport.

**Workaround:** move the pointer over a window edge. That forces a shape change and
clears it.

If the cursor is stuck *and* not animating at all, that is a different issue — Intel
hardware cursor planes not updating per frame. Test with:

```
MUTTER_DEBUG_DISABLE_HW_CURSORS=1
```

in `~/.config/environment.d/`. Costs a little GPU; revert if it does not help.

---

## Desktop feels sluggish on integrated graphics

Two usual suspects:

**Fractional scaling.** Renders to a larger framebuffer and downscales every frame.
Use 100% plus `text-scaling-factor` instead.

```bash
gsettings set org.gnome.desktop.interface text-scaling-factor 1.15
```

**Live blur.** Gaussian blur at high sigma is one of the most expensive things you can
ask an old iGPU to do.

```bash
dconf write /org/gnome/shell/extensions/blur-my-shell/panel/static-blur true
dconf write /org/gnome/shell/extensions/blur-my-shell/panel/sigma 10
dconf write /org/gnome/shell/extensions/blur-my-shell/window-list/blur false
```

Also check for animation extensions that are loaded while animations are globally
disabled — they cost memory and startup time and do nothing.

---

## Is more RAM worth it?

Check pressure, not usage. Linux deliberately uses free memory for cache; "only 2 GB
free" is normal and healthy.

```bash
cat /proc/pressure/memory
free -h
zramctl
```

If `some avg300=0.00` and swap is unused, the system has never once waited on memory.
More RAM will change nothing.
