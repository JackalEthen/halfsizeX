#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bundle="$root/build/linux/x64/release/bundle"
dist="$root/dist"
work="$root/build/linux/package"
version="$(sed -nE 's/^version: *([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' "$root/pubspec.yaml" | head -n1)"

if [[ ! -d "$bundle" ]]; then
  echo "Linux bundle not found: $bundle" >&2
  echo "Run: flutter build linux --release" >&2
  exit 1
fi

mkdir -p "$dist"
rm -rf "$work"
mkdir -p "$work"

if [[ -n "${FFMPEG_DIR:-}" ]]; then
  mkdir -p "$bundle/bin"
  install -m755 "$FFMPEG_DIR/ffmpeg" "$bundle/bin/ffmpeg"
  install -m755 "$FFMPEG_DIR/ffprobe" "$bundle/bin/ffprobe"
  if [[ -f "$(dirname "$FFMPEG_DIR")/LICENSE.txt" ]]; then
    install -m644 "$(dirname "$FFMPEG_DIR")/LICENSE.txt" "$bundle/bin/LICENSE.txt"
  fi
fi

portable="$dist/halfsizeX-$version-linux-x64-portable.tar.gz"
portable_dir="$work/portable/halfsizeX-$version"
mkdir -p "$portable_dir"
cp -a "$bundle/." "$portable_dir/"
rm -f "$portable"
tar -czf "$portable" -C "$work/portable" "halfsizeX-$version"

appdir="$work/AppDir"
mkdir -p "$appdir"
cp -a "$bundle/." "$appdir/"
cat > "$appdir/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/halfsizeX" "$@"
EOF
chmod 755 "$appdir/AppRun"
install -m644 "$root/linux/com.halfsizeX.video.desktop" "$appdir/com.halfsizeX.video.desktop"
install -m644 "$root/assets/icon.png" "$appdir/com.halfsizeX.video.png"

if [[ -n "${APPIMAGETOOL:-}" ]]; then
  appimage="$dist/halfsizeX-$version-linux-x64.AppImage"
  rm -f "$appimage"
  if [[ "$APPIMAGETOOL" == *.AppImage ]]; then
    APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 "$APPIMAGETOOL" "$appdir" "$appimage"
  else
    ARCH=x86_64 "$APPIMAGETOOL" "$appdir" "$appimage"
  fi
  [[ -f "$appimage" ]] || { echo "appimagetool produced no AppImage" >&2; exit 1; }
else
  echo "warning: APPIMAGETOOL is not set; skipped AppImage" >&2
fi

debroot="$work/deb"
mkdir -p "$debroot/DEBIAN" "$debroot/opt/halfsizeX" "$debroot/usr/bin"
mkdir -p "$debroot/usr/share/applications" "$debroot/usr/share/icons/hicolor/256x256/apps"
cp -a "$bundle/." "$debroot/opt/halfsizeX/"
ln -s /opt/halfsizeX/halfsizeX "$debroot/usr/bin/halfsizeX"
install -m644 "$root/linux/com.halfsizeX.video.desktop" "$debroot/usr/share/applications/com.halfsizeX.video.desktop"
install -m644 "$root/assets/icon.png" "$debroot/usr/share/icons/hicolor/256x256/apps/com.halfsizeX.video.png"
cat > "$debroot/DEBIAN/control" <<EOF
Package: halfsizex
Version: $version
Section: video
Priority: optional
Architecture: amd64
Depends: libgtk-3-0
Maintainer: halfsizeX contributors
Homepage: https://github.com/YKLovePython/halfsize
Description: Compress a video to an exact size, locally.
EOF
deb="$dist/halfsizeX-$version-linux-x64.deb"
rm -f "$deb"
dpkg-deb --build --root-owner-group "$debroot" "$deb" >/dev/null

rpmtop="$work/rpm"
mkdir -p "$rpmtop/BUILD" "$rpmtop/RPMS" "$rpmtop/SOURCES" "$rpmtop/SPECS" "$rpmtop/SRPMS"
cp -a "$bundle" "$rpmtop/SOURCES/bundle"
install -m644 "$root/linux/com.halfsizeX.video.desktop" "$rpmtop/SOURCES/com.halfsizeX.video.desktop"
install -m644 "$root/assets/icon.png" "$rpmtop/SOURCES/com.halfsizeX.video.png"
cat > "$rpmtop/SPECS/halfsizex.spec" <<EOF
Name: halfsizex
Version: $version
Release: 1
Summary: Compress a video to an exact size
License: MIT
BuildArch: x86_64
Requires: gtk3

%description
Compress a video to an exact size, locally.

%install
mkdir -p %{buildroot}/opt/halfsizeX
cp -a %{_sourcedir}/bundle/. %{buildroot}/opt/halfsizeX/
mkdir -p %{buildroot}/usr/bin
ln -s /opt/halfsizeX/halfsizeX %{buildroot}/usr/bin/halfsizeX
mkdir -p %{buildroot}/usr/share/applications
cp %{_sourcedir}/com.halfsizeX.video.desktop %{buildroot}/usr/share/applications/
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps
cp %{_sourcedir}/com.halfsizeX.video.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/

%files
/opt/halfsizeX
/usr/bin/halfsizeX
/usr/share/applications/com.halfsizeX.video.desktop
/usr/share/icons/hicolor/256x256/apps/com.halfsizeX.video.png
EOF
rpmbuild -bb --define "_topdir $rpmtop" --define "_sourcedir $rpmtop/SOURCES" "$rpmtop/SPECS/halfsizex.spec" >/dev/null
rpmfile="$(find "$rpmtop/RPMS" -name '*.rpm' | head -n1)"
if [[ -z "$rpmfile" ]]; then
  echo "rpmbuild produced no package" >&2
  exit 1
fi
rpm="$dist/halfsizeX-$version-linux-x64.rpm"
rm -f "$rpm"
cp "$rpmfile" "$rpm"

for artifact in "$portable" "$deb" "$rpm"; do
  [[ -f "$artifact" ]] || { echo "missing artifact: $artifact" >&2; exit 1; }
done

echo "$portable"
echo "$dist/halfsizeX-$version-linux-x64.AppImage"
echo "$deb"
echo "$rpm"
