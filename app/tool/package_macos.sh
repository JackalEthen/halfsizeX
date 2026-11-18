#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
app="$root/build/macos/Build/Products/Release/halfsizeX.app"
dist="$root/dist"
version="$(sed -nE 's/^version: *([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' "$root/pubspec.yaml" | head -n1)"
arch="$(uname -m)"
case "$arch" in
  arm64) arch=arm64 ;;
  x86_64) arch=x64 ;;
esac

if [[ ! -d "$app" ]]; then
  echo "macOS app not found: $app" >&2
  echo "Run: flutter build macos --release" >&2
  exit 1
fi

if [[ -n "${FFMPEG_DIR:-}" ]]; then
  bin="$app/Contents/Resources/bin"
  mkdir -p "$bin"
  install -m755 "$FFMPEG_DIR/ffmpeg" "$bin/ffmpeg"
  install -m755 "$FFMPEG_DIR/ffprobe" "$bin/ffprobe"
  if [[ -f "$FFMPEG_DIR/LICENSE" ]]; then
    install -m644 "$FFMPEG_DIR/LICENSE" "$bin/LICENSE.txt"
  fi
fi

if [[ ! -x "$app/Contents/Resources/bin/ffmpeg" ]]; then
  echo "FFmpeg is missing from the app bundle; set FFMPEG_DIR." >&2
  exit 1
fi

if [[ -n "${MACOS_SIGN_IDENTITY:-}" ]]; then
  codesign --force --options runtime --timestamp \
    --sign "$MACOS_SIGN_IDENTITY" "$app/Contents/Resources/bin/ffmpeg"
  codesign --force --options runtime --timestamp \
    --sign "$MACOS_SIGN_IDENTITY" "$app/Contents/Resources/bin/ffprobe"
  codesign --force --deep --options runtime --timestamp \
    --sign "$MACOS_SIGN_IDENTITY" "$app"
else
  codesign --force --sign - "$app/Contents/Resources/bin/ffmpeg"
  codesign --force --sign - "$app/Contents/Resources/bin/ffprobe"
  codesign --force --deep --sign - "$app"
fi

mkdir -p "$dist"
zip="$dist/halfsizeX-$version-macos-$arch.zip"
dmg="$dist/halfsizeX-$version-macos-$arch.dmg"
rm -f "$zip" "$dmg"
ditto -c -k --sequesterRsrc --keepParent "$app" "$zip"
hdiutil create -volname "halfsizeX $version" -srcfolder "$app" \
  -ov -format UDZO "$dmg"
echo "$zip"
echo "$dmg"
