# Changelog

All notable changes to this project are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed
- Landing page redesigned for a documentation tone: left-aligned hero, hairline
  rules instead of cards, measured values presented as tables, and the
  27% -> 0% throttling figure as the page's focal point
- Removed gradients, glow, pill badges, hover-lift and scroll-reveal animation

### Added
- Landing page under `site/`, published with GitHub Pages
- Two hand-authored SVG schematics of the desktop, stock against themed, with
  six numbered callouts keyed to the exact gsettings/dconf key that produces
  each difference

### Removed
- Screenshot comparison sliders and `tools/capture-shots.sh`. Honest before/after
  screenshots are not obtainable: GNOME 47+ denies programmatic desktop capture,
  and GTK4/libadwaita applications ignore `GTK_THEME`, so a stock-versus-themed
  comparison of Files or the desktop cannot be produced at all
- `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, issue and PR templates
- `docs/ARCHITECTURE.md` with diagrams of the run order and the clipboard key path
- `docs/SHORTCUTS.md` — the full keyboard reference
- `docs/FAQ.md`

## [0.1.0] — 2026-09-23

First working version, extracted from a live setup on a Dell Latitude 5400
(i7-8665U, UHD 620, Fedora 44, GNOME 50.1, Wayland).

### Added
- `00-preflight.sh` — dconf backup plus hardware and thermal baseline
- `01-performance.sh` — the thermal fix: throttling 27% → 0%, 89 °C → 61 °C
- `02-packages.sh` — dnf tuning, RPM Fusion, codecs, hardware video decode, backup tooling
- `03-theme.sh` — WhiteSur theme, icons, cursors, fonts, wallpaper, macOS sound theme
- `04-extensions.sh` — 12 GNOME extensions, configured for a weak iGPU
- `05-shortcuts.sh` — macOS-style keybindings using GNOME settings alone
- `06-keyd.sh` — optional Super-as-Cmd layer via XF86 media keys
- `07-voice-sounds.sh` — Piper neural TTS replacing espeak-ng
- `08-snapshots.sh` — btrfs snapshots via snapper, wired into dnf
- `09-verify.sh` — read-only end-to-end verification
- `lib/common.sh` — shared guards and hardware detection
- `docs/TROUBLESHOOTING.md` — every non-obvious failure hit during the build

### Notes
- Verified on one machine only. The portability guards are written carefully but
  have not been exercised on other hardware.
