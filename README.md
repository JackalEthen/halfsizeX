<p align="center">
  <img src="app/assets/icon.png" alt="halfsizeX icon" width="160">
</p>

<h1 align="center">halfsizeX</h1>

**Compress a video to an exact size, locally. No upload, no account, no telemetry.**

[简体中文](README-zh.md) | English

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](./SPEC.md)
[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Windows](https://img.shields.io/badge/Windows-x64-0078D6?logo=windows&logoColor=white)](#supported-clients)
[![Android](https://img.shields.io/badge/Android-arm64%20%7C%20armv7-3DDC84?logo=android&logoColor=white)](#supported-clients)
[![Linux](https://img.shields.io/badge/Linux-x64-FCC624?logo=linux&logoColor=black)](#supported-clients)
[![FFmpeg](https://img.shields.io/badge/FFmpeg-bundled-007808)](#ffmpeg-and-licensing)
[![Offline](https://img.shields.io/badge/Offline-100%25-success)](#privacy)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Upstream](https://img.shields.io/badge/Upstream-YKLovePython%2Fhalfsize-blueviolet?logo=github)](https://github.com/YKLovePython/halfsize)
[![PRs](https://img.shields.io/badge/PRs-welcome-brightgreen)](#contributing)

halfsizeX is a Flutter rewrite of [YKLovePython/halfsize](https://github.com/YKLovePython/halfsize) (MIT).
It turns a video into a file close to a requested size while keeping the result watchable, and reports
the measured quality instead of  trust a bitrate guess.

The app is a native desktop/mobile GUI. FFmpeg is bundled; processing never leaves the device.

## Why

Most "compress video" tools either ask for a quality number you cannot translate into megabytes, or
produce a file that misses the upload limit. halfsizeX plans the encode from the target size, the
duration, the resolution and the audio budget, then verifies the result with VMAF or SSIM when the
bundled FFmpeg supports it.

## Features

### Implemented

- Exact target size in MB, plus platform presets (Discord, WhatsApp, WeChat, Gmail, Outlook, X).
- Custom target size and CRF mode.
- H.264 (`libx264`) and H.265 (`libx265`) with selectable preset.
- Two-pass size-targeted encoding; automatic retry when the first result overshoots.
- Automatic downscale selection, with an option to keep the original resolution.
- Keep or drop audio; mono/stereo handling and audio bitrate budget.
- HDR (PQ/HLG) detection and HDR-to-SDR tone mapping when the FFmpeg build supports it.
- Progress, speed, ETA, pass number, cancel, and cleanup of partial files.
- VMAF / SSIM quality measurement with a human-readable verdict.
- Safe output naming (`name.tag.mp4`, collision suffixes) and a configurable output directory.
- Drag and drop on desktop; native file picker on all platforms.
- Embedded video preview on Windows (original / compressed), powered by `media_kit`.
- Android foreground service with notification progress; SAF input and MediaStore Downloads output.
- Chinese and English UI; system/dark/light theme; persisted settings.
- Windows MSI installer and portable ZIP.
- Linux AppImage, deb, rpm and portable tarball.

### Not implemented yet

- Batch queue (planned for v0.2).
- Share cards.
- macOS build and packaging (interfaces are kept platform-neutral).
- Auto-update, file associations, and first-run FFmpeg download.
- Hardware-accelerated encoding (current builds use software x264/x265).
- Subtitle retention.

## Supported clients

| Client | Status | Notes |
|---|---|---|
| Windows x64 | Supported | Release build, MSI + portable ZIP, embedded preview |
| Android arm64-v8a | Supported | Native FFmpeg libraries bundled; foreground service |
| Android armeabi-v7a | Supported | Native FFmpeg libraries bundled |
| Linux x64 | Supported | AppImage, deb, rpm and portable tarball; player libraries still being finished |
| macOS | Planned | No CI or release artifact yet |

## Download

Once a `v*` tag is pushed, the release workflow publishes these artifacts:

- `halfsizeX-<version>-windows-x64.msi`
- `halfsizeX-<version>-windows-x64-portable.zip`
- `halfsizeX-<version>-android-arm64-v8a.apk`
- `halfsizeX-<version>-android-armeabi-v7a.apk`
- `halfsizeX-<version>-linux-x64.AppImage`
- `halfsizeX-<version>-linux-x64.deb`
- `halfsizeX-<version>-linux-x64.rpm`
- `halfsizeX-<version>-linux-x64-portable.tar.gz`

## Build from source

Requirements: Flutter 3.41+ / Dart 3.11+, and the platform toolchain for your target.

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

### Windows

```powershell
cd app
flutter build windows --release
```

To produce the MSI and portable ZIP, provide a directory containing `ffmpeg.exe`, `ffprobe.exe` and
the FFmpeg DLLs:

```powershell
.\tool\package_windows.ps1 -FfmpegDir C:\path\to\ffmpeg\bin
```

The script needs [WiX](https://wixtoolset.org/) (`dotnet tool install --global wix`).

### Android

```bash
cd app
flutter build apk --release --split-per-abi
```

The Android FFmpeg binaries live in `app/android/app/src/main/jniLibs/<abi>/`. Release signing reads
`android/key.properties` or the `HALFSIZE_KEYSTORE`, `HALFSIZE_STORE_PASSWORD`, `HALFSIZE_KEY_ALIAS`
and `HALFSIZE_KEY_PASSWORD` environment variables. CI uses repository secrets; without a keystore the
build falls back to the debug key.

### Linux

```bash
cd app
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
flutter build linux --release
```

The release workflow then runs `tool/package_linux.sh` to build the AppImage, deb, rpm and portable
tarball.

## CI/CD

- `ci.yml` runs `flutter analyze` and `flutter test` on pushes and pull requests.
- `build.yml` builds Android, Windows and Linux artifacts on manual dispatch and `v*` tags.
- Tag builds publish a GitHub Release with the Android APKs, Windows ZIP/MSI, and Linux
  AppImage/deb/rpm/portable tarball.

Android release signing reads `android/key.properties` or the `HALFSIZE_*` environment variables; CI
uses repository secrets. See the workflow files under `.github/workflows/` for the exact commands.

## Privacy

All probing, planning, encoding and quality measurement run locally. The app has no account, cloud
upload, analytics or telemetry. Network access is only used by the build tooling, not by the app.

## FFmpeg and licensing

halfsizeX itself is MIT-licensed. FFmpeg, x264 and x265 keep their own licenses; redistributed builds
must include the corresponding license texts. See [SPEC.md](SPEC.md) for the intended distribution
and GPL notes. The app never replaces or hides FFmpeg's license.

## Project layout

```text
app/                 Flutter application
  lib/core/          probe, plan, encode, quality, FFmpeg locator, settings
  lib/features/      compress and settings UI
  android/           Android runner, service, jniLibs
  windows/           Windows runner and installer script
  linux/             Linux runner, desktop entry and icon install rules
  test/              unit and widget tests
```

## Contributing

Issues and pull requests are welcome. Keep changes small and include a test for behavior changes.
Before opening a PR, run:

```bash
cd app
flutter analyze
flutter test
```

## Credits

- Original project: [YKLovePython/halfsize](https://github.com/YKLovePython/halfsize) (MIT).
- FFmpeg, x264, x265, libvmaf and media_kit.
- Flutter and the Flutter community.
