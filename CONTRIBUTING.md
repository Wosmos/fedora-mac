# Contributing

Thanks for looking. This repo automates a desktop setup, which means a bad patch
can leave someone with no keyboard, no copy/paste, or no login screen. The bar for
changes is correspondingly high — but the rules are simple.

## Ground rules

**Every script must be idempotent.** Running it twice must be identical to running
it once. No appending to files without checking, no blind `>>`.

**Every script must be reversible**, and the reversal documented in
[`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md). If you can't describe how to
undo it, it doesn't go in.

**Never assume the reference hardware.** The scripts run on machines with no
battery, no zram, no btrfs, AMD CPUs and terminals that aren't Ptyxis. Use the
detection helpers in [`lib/common.sh`](lib/common.sh) rather than probing
`/sys` paths directly.

**No hardcoded usernames or absolute home paths.** Use `real_user` and `real_home`
from `lib/common.sh` — they resolve correctly even under `sudo`.

**Guard before you act.** Scripts that download call `require_net`. Scripts that
need tools call `require_cmds`. Scripts that need root call `require_root`.

## Before opening a PR

```bash
bash -n scripts/*.sh lib/*.sh      # must parse
shellcheck scripts/*.sh lib/*.sh   # if you have it; warnings are fine, errors are not
bash scripts/09-verify.sh          # must still pass on your machine
```

State in the PR **which Fedora and GNOME versions you tested on**. "Should work" is
not a test — much of the pain documented in this repo came from plausible
assumptions that were wrong.

## Adding a GNOME extension

Check a build exists for the target shell version *before* adding it. An extension
without a matching build reports `OUT OF DATE` and silently never runs:

```bash
curl -s "https://extensions.gnome.org/extension-info/?pk=<PK>&shell_version=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)"
```

If `download_url` is `null`, there is no build. Don't add it.

## Adding a keyd mapping

Read the compound-layer section of the troubleshooting guide first. Omitting a key
from `[meta+shift]` does **not** pass it through — it inherits from `[meta]`. Test
the actual keypress, and add a non-Super fallback binding for anything important.

## Touching thermals or power

Include before/after numbers from the cumulative throttle counters:

```bash
cat /sys/devices/system/cpu/cpu0/thermal_throttle/package_throttle_total_time_ms
```

Spot temperature readings are not evidence. This is explained at length in the
troubleshooting guide, because it nearly caused a misdiagnosis here.

## Reporting a bug

Please run `bash scripts/09-verify.sh` and paste the output. It covers most of what
anyone would ask you for anyway.

## Scope

In scope: Fedora, GNOME, Wayland, the macOS look and feel, and performance.

Out of scope: other distributions, other desktops, and anything that ships Apple's
proprietary assets. Ports to KDE or other distros are welcome as forks, and happily
linked from the README.

## Licence

Contributions are accepted under the [MIT Licence](LICENSE).
