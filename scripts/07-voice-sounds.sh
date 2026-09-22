#!/usr/bin/env bash
# 07 - NATURAL TTS VOICE (replaces robotic espeak-ng with Piper neural TTS)
# Run as your NORMAL USER: bash 07-voice-sounds.sh
# Everything lives in $HOME - no sudo, no system Python touched.
set -uo pipefail
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/common.sh"
require_user

# WARNING: the 'piper' RPM in Fedora's repos is a GAMING MOUSE tool.
# Piper TTS is not packaged for Fedora at all - hence this venv.
VENV="$HOME/.local/share/piper-venv"
VOICES="$HOME/.local/share/piper-voices"

echo "== Installing Piper =="
python3 -m venv "$VENV"
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet piper-tts

echo "== Downloading neural voices (~61MB each) =="
mkdir -p "$VOICES"
B="https://huggingface.co/rhasspy/piper-voices/resolve/main/en/en_US"
for spec in "hfc_female/medium/en_US-hfc_female-medium" "amy/medium/en_US-amy-medium"; do
  n=$(basename "$spec")
  [ -f "$VOICES/$n.onnx" ] || curl -sL -o "$VOICES/$n.onnx"      "$B/$spec.onnx"
  [ -f "$VOICES/$n.onnx.json" ] || curl -sL -o "$VOICES/$n.onnx.json" "$B/$spec.onnx.json"
  echo "  $n  $(du -h "$VOICES/$n.onnx" | cut -f1)"
done

echo "== Wiring into speech-dispatcher =="
mkdir -p "$HOME/.config/speech-dispatcher/modules"
sed -e "s|__PIPER__|$VENV/bin/piper|g" -e "s|__VOICES__|$VOICES|g" \
    "$(dirname "$0")/../conf/piper-generic.conf" \
    > "$HOME/.config/speech-dispatcher/modules/piper-generic.conf"

cp /etc/speech-dispatcher/speechd.conf "$HOME/.config/speech-dispatcher/speechd.conf"
cat >> "$HOME/.config/speech-dispatcher/speechd.conf" <<'CONF'

# --- Piper neural TTS ---
AddModule "piper-generic"  "sd_generic"  "piper-generic.conf"
DefaultModule piper-generic
DefaultVoiceType FEMALE1
DefaultLanguage en
CONF

# NEVER use `pkill -f speech-dispatcher` - the pattern matches the calling
# shell's own command line and kills your session.
systemctl --user restart speech-dispatcher.service 2>/dev/null || true

echo
echo "Verify:  spd-say -O   (should list piper-generic)"
echo "         spd-say -L   (should list only the neural voices)"
echo "Test:    spd-say -w 'Hello, this is the new voice.'"
echo "More voices: https://huggingface.co/rhasspy/piper-voices"
