#!/usr/bin/env bash
# 02 - REPOS, CODECS, TOOLS
# Run with: sudo bash 02-packages.sh
set -uo pipefail
[ "$EUID" -ne 0 ] && { echo "run with sudo"; exit 1; }
FED=$(rpm -E %fedora)

echo "== dnf speed (Fedora ships an empty dnf.conf) =="
cp /etc/dnf/dnf.conf /etc/dnf/dnf.conf.bak 2>/dev/null
cat > /etc/dnf/dnf.conf <<'CONF'
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=True
defaultyes=True
CONF

echo "== RPM Fusion (codecs) =="
dnf install -y --skip-unavailable \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FED}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FED}.noarch.rpm"

echo "== Full ffmpeg + hardware video decode =="
dnf swap -y ffmpeg-free ffmpeg --allowerasing 2>/dev/null
dnf install -y --skip-unavailable \
  libva-utils intel-media-driver libva-intel-media-driver intel-gpu-tools \
  gstreamer1-plugins-bad-freeworld

echo "== Desktop tooling =="
dnf install -y --skip-unavailable \
  gnome-tweaks sushi rsms-inter-fonts \
  tesseract tesseract-langpack-eng \
  pika-backup btrfs-assistant snapper \
  sassc glib2-devel   # needed to build GTK themes

echo "== Fix half-installed TPM stack (missing 'tss' user breaks boot units) =="
dnf reinstall -y tpm2-tss 2>/dev/null

echo
echo "Verify hardware video decode (should list VAProfileH264 etc):"
echo "  vainfo"
