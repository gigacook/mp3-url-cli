#!/usr/bin/env bash
# Installs deps via brew and links ytmp3 into your PATH.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${BIN:-/opt/homebrew/bin}"

command -v brew >/dev/null || { echo "homebrew required: https://brew.sh"; exit 1; }

echo "» brew install yt-dlp ffmpeg"
brew install yt-dlp ffmpeg

chmod +x "$HERE/ytmp3"
ln -sf "$HERE/ytmp3" "$BIN/ytmp3"
ln -sf "$HERE/ytmp3" "$BIN/mp3"      # short alias
echo "✓ linked $BIN/ytmp3 -> $HERE/ytmp3"
echo "✓ linked $BIN/mp3   -> $HERE/ytmp3"
echo "  try:  mp3 <url>"
