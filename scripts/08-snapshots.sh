#!/usr/bin/env bash
# 08 - BTRFS SNAPSHOT SAFETY NET
# Run with: sudo bash 08-snapshots.sh
set -uo pipefail
[ "$EUID" -ne 0 ] && { echo "run with sudo"; exit 1; }
findmnt -no FSTYPE / | grep -q btrfs || { echo "root is not btrfs - skipping"; exit 0; }

dnf install -y --skip-unavailable snapper btrfs-assistant python3-dnf-plugin-snapper
snapper -c root create-config / 2>/dev/null

snapper -c root set-config TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes
snapper -c root set-config TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7
snapper -c root set-config TIMELINE_LIMIT_WEEKLY=4 TIMELINE_LIMIT_MONTHLY=2
snapper -c root set-config TIMELINE_LIMIT_YEARLY=0 NUMBER_LIMIT=10

systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
snapper -c root create --description "baseline $(date +%F)"
snapper -c root list | tail -5

echo
echo "Browse and roll back with the 'Btrfs Assistant' GUI."
echo "NOTE: snapshots live on the SAME disk. They are not a backup."
echo "      Set up Pika Backup to an external drive as well."
