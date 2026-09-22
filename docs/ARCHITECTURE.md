# Architecture

How the pieces fit, and why they are arranged this way.

---

## Run order

Order matters more than it looks. Packages must exist before the theme can be
built, the theme must be in place before extensions reference it, and keyd must be
confirmed running before the terminal is pointed at the media keys it emits.

```mermaid
flowchart TD
    A["00 · preflight<br/><i>dconf backup + thermal baseline</i>"] --> B["01 · performance<br/><b>sudo</b>"]
    B --> C["02 · packages<br/><b>sudo</b>"]
    C --> D["03 · theme"]
    C --> H["08 · snapshots<br/><b>sudo</b>"]
    D --> E["04 · extensions"]
    E --> F["05 · shortcuts"]
    C --> G["07 · voice"]
    F -.optional.-> K["06 · keyd<br/><b>sudo</b>"]
    F --> V["09 · verify"]
    G --> V
    H --> V
    K --> V

    style B fill:#1e3a5f,stroke:#6FA8F5,color:#E6EAF2
    style K fill:#4a3520,stroke:#F5A97F,color:#E6EAF2
    style V fill:#1f3d24,stroke:#9BD98E,color:#E6EAF2
```

**01 is highlighted** because it is the only script whose absence you will actually
feel. **06 is amber** because it is the most invasive. **09 is green** because it is
read-only and safe to run at any point.

---

## The clipboard problem

This is the one genuinely non-obvious piece of engineering in the repo.

Making `Cmd+C` work on Linux normally means remapping `Super+C` → `Ctrl+C`. In a
terminal that is a disaster: `Ctrl+C` is SIGINT. You end up choosing between copy
and interrupt.

The way out is to never send `Ctrl+C` at all.

```mermaid
flowchart LR
    subgraph naive ["The naive approach — broken"]
        direction TB
        N1["Super+C"] --> N2["remap to Ctrl+C"]
        N2 --> N3["GUI app: copies ✓"]
        N2 --> N4["Terminal: SIGINT ✗<br/><i>kills your process</i>"]
    end
```

```mermaid
flowchart LR
    subgraph works ["What this repo does — works"]
        direction TB
        W1["Super+C"] --> W2["keyd emits<br/><b>XF86Copy</b><br/><i>a media key</i>"]
        W2 --> W3["GTK / Qt app:<br/>handles natively ✓"]
        W2 --> W4["Terminal bound to<br/>XF86Copy: copies ✓"]
        W5["Ctrl+C"] --> W6["untouched —<br/>still SIGINT ✓"]
    end
```

Because `Ctrl+C` is never transmitted, interrupt keeps working. The terminal is then
told to listen for the media key instead of `Ctrl+Shift+C`:

```bash
gsettings set org.gnome.Ptyxis.Shortcuts copy-clipboard  'XF86Copy'
gsettings set org.gnome.Ptyxis.Shortcuts paste-clipboard 'XF86Paste'
```

> **Ordering trap.** That setting is a single string, not a list — it *replaces*
> `Ctrl+Shift+C` rather than adding to it. Applying it before keyd is running leaves
> the terminal with no working copy/paste at all. `06-keyd.sh` therefore only makes
> this change after `systemctl is-active keyd` succeeds.

---

## Where keyd sits

keyd works at the evdev level, below the display server. That is why it works on
Wayland, where X11-era tools like `xmodmap` do not.

```mermaid
flowchart TD
    K["Physical keyboard"] --> E["evdev"]
    E --> D["keyd<br/><i>rewrites here</i>"]
    D --> U["uinput<br/><i>virtual keyboard</i>"]
    U --> W["Wayland compositor<br/>(mutter)"]
    W --> G["GNOME shortcuts"]
    W --> A["Applications"]

    style D fill:#4a3520,stroke:#F5A97F,color:#E6EAF2
```

Two consequences follow, and both caused real bugs here:

1. **GNOME never sees what keyd consumed.** Any `Super+<key>` that keyd maps is gone
   before mutter gets it. That is why window tiling moved to `Ctrl+Super+arrows` —
   `Super+arrows` became macOS text navigation.

2. **Combinations keyd doesn't define pass straight through.** `Ctrl+Alt+V` never
   enters a keyd layer, so it is a reliable fallback when a `Super` binding misbehaves.
   The clipboard manager is bound to both for exactly this reason.

### Layer inheritance

The subtlest trap in the whole repo:

```mermaid
flowchart TD
    P["Press Shift+Super+V"] --> Q{"Is 'v' defined<br/>in [meta+shift]?"}
    Q -->|yes| R["Emit what it says<br/><i>v = M-S-v →<br/>passes through ✓</i>"]
    Q -->|no| S["<b>Fall back to [meta]</b>"]
    S --> T{"Is 'v' defined<br/>in [meta]?"}
    T -->|yes| U2["Emit that instead<br/><i>v = paste → XF86Paste ✗</i>"]
    T -->|no| V2["Pass through ✓"]

    style U2 fill:#4a2020,stroke:#F08A8A,color:#E6EAF2
    style R fill:#1f3d24,stroke:#9BD98E,color:#E6EAF2
```

Omission means **inherit**, not **pass through**. To genuinely let a key reach the
compositor, re-emit it explicitly.

---

## Why the thermal fix works

The failure was a feedback loop, not a single bad setting.

```mermaid
flowchart LR
    A["Any tiny task<br/><i>even a keystroke</i>"] --> B["governor=performance<br/>EPP=performance"]
    B --> C["Jump straight to<br/>max turbo, 4.8 GHz"]
    C --> D["15 W chip exceeds<br/>thermal headroom<br/>in milliseconds"]
    D --> E["PROCHOT fires,<br/>clocks cut hard"]
    E --> F["Recover"]
    F --> A

    style B fill:#4a2020,stroke:#F08A8A,color:#E6EAF2
    style E fill:#4a2020,stroke:#F08A8A,color:#E6EAF2
```

Measured: **24,440 throttle events** and **27% of wall-clock time throttled** while
the machine was doing nothing.

The fix breaks the loop at the top. With `EPP=balance_performance` the chip uses its
intermediate P-states — light work is serviced at 700–1100 MHz instead of 4.8 GHz, so
it never reaches the ceiling and never gets cut.

Frequency distribution, same machine, same idle conditions:

| | Before | After |
|---|---|---|
| Samples at minimum (400 MHz) | ~half | ~half |
| Samples at max turbo (4.2–4.8 GHz) | ~half | **none** |
| Samples in between | **1 of 96** | most |

The absence of a middle gear is the signature. If you see it, that is your problem.

---

## Layout

```
lib/common.sh          guards, hardware detection, helpers
                       everything else sources this

scripts/00 … 09        numbered, ordered, independently runnable
scripts/install.sh     orchestrator — runs them with the right privileges

conf/                  templatised configs (keyd, piper)
                       __PIPER__ / __VOICES__ substituted at install time

docs/                  this file, TROUBLESHOOTING, SHORTCUTS, FAQ
site/                  GitHub Pages landing page
```

### Privilege split

Root-level work and user-level work are deliberately in separate scripts rather than
sprinkled through one, so you can read exactly what runs as root:

| Root | User |
|---|---|
| 01 performance, 02 packages, 06 keyd, 08 snapshots | 00 preflight, 03 theme, 04 extensions, 05 shortcuts, 07 voice, 09 verify |

Where a root script must touch user settings, it goes through `as_user` in
`lib/common.sh`, which resolves the invoking human rather than writing into root's
own dconf.
