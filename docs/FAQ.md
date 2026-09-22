# FAQ

### Do I need to reinstall Fedora for any of this?

No. Nothing here requires a fresh install. The original machine had a healthy
Fedora underneath a pile of bad configuration.

### Will this work on Ubuntu / Arch / KDE?

Not as written. The scripts check for Fedora and GNOME and refuse otherwise —
deliberately, because half-applying a desktop setup is worse than not applying it.
The *ideas* port fine, and forks are welcome.

### Is it safe to run twice?

Yes. Every script is idempotent by design.

### How do I undo it?

`00-preflight.sh` dumps your entire dconf before anything changes:

```bash
dconf load /org/gnome/ < ~/.config/fedora-macos-setup-backup-*/dconf-gnome.ini
```

Per-component reversals are listed in the README and TROUBLESHOOTING.

### Do I have to install keyd?

No, and you should consider not to. Script 05 gives you the whole macOS shortcut
layer using GNOME settings alone. keyd adds `Super+C`-style shortcuts *inside*
applications, which nothing else can do — at the cost of a root daemon that sees
every keystroke.

### Will `Ctrl+C` still interrupt in my terminal?

Yes. That constraint drove the entire design. keyd emits `XF86Copy` media keys and
never transmits `Ctrl+C` at all.

### Is my clipboard history stored in plain text?

Yes, on disk, like every clipboard manager. Password managers are excluded by
default — check the list suits the ones you use:

```bash
gsettings --schemadir ~/.local/share/gnome-shell/extensions/clipboard-indicator@tudmotu.com/schemas \
  get org.gnome.shell.extensions.clipboard-indicator excluded-apps
```

There is also a private-mode toggle that pauses capture entirely.

### Are these Apple's real voices and sounds?

No. Siri's voices are proprietary and cannot be redistributed. The voice is
**Piper**, a neural TTS engine in a similar quality class. The sound theme is a
community project that samples macOS — for personal desktop use that is the usual
grey area; decide for yourself.

### Why is my GNOME extension not doing anything?

Almost certainly it is `OUT OF DATE` and never loaded, despite appearing in the
enabled list:

```bash
gnome-extensions info <uuid> | grep State
```

This is the single most common confusion in the whole project.

### Will more RAM help?

Check before buying:

```bash
cat /proc/pressure/memory
```

If `some avg300=0.00` and swap is unused, the system has never waited on memory and
more will change nothing. On the reference machine it was `total=7` — seven
microseconds of stall since boot, with 16 GB.

### My laptop is still hot after the fix

Software can only do so much on old hardware. Dust and dried thermal paste usually
matter more than any setting on a machine over a few years old. Also check firmware:
the reference machine's BIOS was three and a half years out of date.

### What is furnizsh and do I need it?

[furnizsh](https://github.com/Wosmos/furnizsh) is the terminal half of the same
setup — Ghostty, zsh and Starship installed and themed together. This repo assumes
a terminal exists but does not require furnizsh specifically.

### Can I use only part of this?

Yes. Every script stands alone. If you only want the thermal fix, run
`01-performance.sh` and nothing else — it is the one with the biggest effect anyway.
