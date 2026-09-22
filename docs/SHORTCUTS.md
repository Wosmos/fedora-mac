# Keyboard reference

Two independent layers. The GNOME layer needs nothing but settings. The keyd layer
is optional and remaps Super to behave like Cmd everywhere.

---

## GNOME layer — `05-shortcuts.sh`

No daemon, no root, fully reversible with `dconf load`.

### Screenshots and recording

| Key | Action | macOS equivalent |
|---|---|---|
| <kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>3</kbd> | Whole screen | `Cmd+Shift+3` |
| <kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>4</kbd> | Select region | `Cmd+Shift+4` |
| <kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>5</kbd> | Screenshot UI | `Cmd+Shift+5` |
| <kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>6</kbd> | Single window | — |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>5</kbd> | Screen recording | — |

### Navigation

| Key | Action | macOS equivalent |
|---|---|---|
| <kbd>Ctrl</kbd>+<kbd>↑</kbd> | Overview | Mission Control |
| <kbd>Super</kbd>+<kbd>Space</kbd> | Search | Spotlight |
| <kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>Space</kbd> | App grid | Launchpad |
| <kbd>Super</kbd>+<kbd>Tab</kbd> | Switch apps | `Cmd+Tab` |
| <kbd>Super</kbd>+<kbd>`</kbd> | Windows of same app | `Cmd+`` ` |
| <kbd>Ctrl</kbd>+<kbd>←</kbd> / <kbd>→</kbd> | Switch workspace | Switch Spaces |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>←</kbd> / <kbd>→</kbd> | Move window to workspace | — |

### Windows

| Key | Action |
|---|---|
| <kbd>Ctrl</kbd>+<kbd>Super</kbd>+<kbd>←</kbd> / <kbd>→</kbd> | Tile left / right |
| <kbd>Ctrl</kbd>+<kbd>Super</kbd>+<kbd>↑</kbd> / <kbd>↓</kbd> | Maximize / restore |

Tiling Shell adds drag-to-snap layouts on top, Windows-style.

> Window tiling lives on `Ctrl+Super` rather than plain `Super` because keyd claims
> `Super+arrows` for macOS text navigation. Without keyd you can move these back.

### Utilities

| Key | Action |
|---|---|
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>V</kbd> | **Clipboard history** (50 items, searchable) |
| <kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>V</kbd> | Same — but unreliable under keyd, see below |
| <kbd>Ctrl</kbd>+<kbd>F10</kbd> | Clear clipboard history |
| <kbd>Super</kbd>+<kbd>M</kbd> | Notifications |
| <kbd>Super</kbd>+<kbd>L</kbd> | Lock screen |
| <kbd>Space</kbd> | Quick Look in Files (via `sushi`) |

---

## keyd layer — `06-keyd.sh`, optional

Super becomes Cmd system-wide.

### Clipboard

| Key | Action |
|---|---|
| <kbd>Super</kbd>+<kbd>C</kbd> | Copy — **including in terminals** |
| <kbd>Super</kbd>+<kbd>V</kbd> | Paste |
| <kbd>Super</kbd>+<kbd>X</kbd> | Cut |
| <kbd>Ctrl</kbd>+<kbd>C</kbd> | **Still SIGINT.** Untouched. |

These emit `XF86Copy` / `XF86Paste` / `XF86Cut` rather than `Ctrl+C`, which is what
keeps interrupt working. See [ARCHITECTURE.md](ARCHITECTURE.md#the-clipboard-problem).

### Editing

`Super` + any of: <kbd>A</kbd> <kbd>Z</kbd> <kbd>S</kbd> <kbd>F</kbd> <kbd>O</kbd>
<kbd>P</kbd> <kbd>N</kbd> <kbd>T</kbd> <kbd>W</kbd> <kbd>R</kbd> <kbd>B</kbd>
<kbd>I</kbd> <kbd>U</kbd> <kbd>G</kbd> <kbd>K</kbd> <kbd>J</kbd> <kbd>D</kbd>
<kbd>E</kbd> <kbd>Y</kbd> <kbd>,</kbd> <kbd>-</kbd> <kbd>=</kbd> <kbd>0</kbd>
→ the `Ctrl` equivalent.

With Shift: <kbd>Super</kbd>+<kbd>Shift</kbd>+ <kbd>Z</kbd> (redo), <kbd>T</kbd>
(reopen tab), <kbd>N</kbd>, <kbd>F</kbd>, <kbd>G</kbd>.

### Text navigation

| Key | Action |
|---|---|
| <kbd>Super</kbd>+<kbd>←</kbd> / <kbd>→</kbd> | Start / end of line |
| <kbd>Super</kbd>+<kbd>↑</kbd> / <kbd>↓</kbd> | Top / bottom of document |
| <kbd>Super</kbd>+<kbd>Backspace</kbd> | Delete to line start |
| Add <kbd>Shift</kbd> to any of the above | Select instead of move |

### Panic key

> **<kbd>Backspace</kbd> + <kbd>Escape</kbd> + <kbd>Enter</kbd> together kills keyd.**
> Memorise it before installing. Permanent removal:
> `sudo systemctl disable --now keyd`

---

## Deliberately not remapped

| Key | Why |
|---|---|
| <kbd>Super</kbd>+<kbd>L</kbd> | Lock screen. macOS uses `Ctrl+Cmd+Q`, but losing one-key lock is worse than the inconsistency. |
| <kbd>Shift</kbd>+<kbd>Super</kbd>+<kbd>V</kbd> | Left free for clipboard history. macOS "paste and match style" is sacrificed. |
| <kbd>Ctrl</kbd>+<kbd>C</kbd> | Must stay SIGINT. The entire clipboard design exists to protect this. |

---

## When a Super shortcut misbehaves

**Test the `Ctrl+Alt` equivalent first.** If that works, the application is fine and
keyd is the problem — which narrows it enormously.

GNOME keybinding settings are arrays, so bind a keyd-proof fallback alongside:

```bash
gsettings --schemadir <schemas> set <schema> <key> "['<Shift><Super>v', '<Control><Alt>v']"
```

Full detail in [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
