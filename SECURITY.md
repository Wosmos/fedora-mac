# Security

## What this software does to your machine

Be aware before running anything here. These scripts:

- **install a kernel-level key remapper** (`06-keyd.sh`) that sees every keystroke
- **replace a system gresource** used by the login screen (the optional GDM theme)
- **modify CPU governor, power and thermal settings**
- **download and execute third-party code** — GNOME extensions, the WhiteSur theme,
  a macOS sound theme, and keyd itself, built from source
- **add a systemd service** that limits battery charge

All of it runs with `sudo` where noted. Read the scripts first. They are commented
for exactly that reason.

## Reporting a vulnerability

Do **not** open a public issue for a security problem.

Use [GitHub's private vulnerability reporting](https://github.com/Wosmos/fedora-mac/security/advisories/new),
or contact the maintainer through [GitHub](https://github.com/Wosmos).

Please include what an attacker could achieve, and the affected script or config.
Expect an initial response within a week.

## Known risk areas

| Area | Risk |
|---|---|
| `06-keyd.sh` | A kernel-level input daemon. A bad config can make the keyboard unusable — panic key is <kbd>Backspace</kbd>+<kbd>Escape</kbd>+<kbd>Enter</kbd>. |
| GDM theming | Replaces a system file the login screen depends on. Reversible; `Ctrl+Alt+F3` gets you a console. |
| Third-party downloads | Extensions and themes are fetched from upstream at install time and are not pinned. |
| Clipboard history | Stores copied text on disk. Password managers are excluded by default — verify that list suits you. |

## Not a supply-chain guarantee

This repo pulls from extensions.gnome.org, GitHub and Hugging Face at install time.
It does not pin hashes. If you need reproducibility, vendor the dependencies yourself.
