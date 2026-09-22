## What this changes

<!-- One or two sentences. -->

## Why

<!-- What problem does it solve? Numbers welcome. -->

## Tested on

- Fedora version:
- GNOME version:
- Session: Wayland / X11
- Machine:

## Checklist

- [ ] `bash -n scripts/*.sh lib/*.sh` passes
- [ ] `bash scripts/09-verify.sh` still passes on my machine
- [ ] The script is idempotent — running it twice equals running it once
- [ ] The change is reversible, and the reversal is documented
- [ ] No hardcoded usernames or absolute home paths (`real_user` / `real_home` used)
- [ ] Hardware assumptions guarded via `lib/common.sh` helpers
- [ ] `CHANGELOG.md` updated

## If this touches thermals or power

Before/after from the cumulative counters, not spot temperatures:

```
package_throttle_total_time_ms before:
package_throttle_total_time_ms after:
uptime at each reading:
```
