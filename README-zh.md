# halfsizeX

**把视频压到指定大小，全程本地。不上传、不登录、无遥测。**

简体中文 | [English](README.md)

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](./SPEC.md)
[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Windows](https://img.shields.io/badge/Windows-x64-0078D6?logo=windows&logoColor=white)](#已支持的客户端)
[![Android](https://img.shields.io/badge/Android-arm64%20%7C%20armv7-3DDC84?logo=android&logoColor=white)](#已支持的客户端)
[![Linux](https://img.shields.io/badge/Linux-x64-FCC624?logo=linux&logoColor=black)](#已支持的客户端)
[![FFmpeg](https://img.shields.io/badge/FFmpeg-bundled-007808)](#ffmpeg-与许可)
[![Offline](https://img.shields.io/badge/Offline-100%25-success)](#隐私)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Upstream](https://img.shields.io/badge/Upstream-YKLovePython%2Fhalfsize-blueviolet?logo=github)](https://github.com/YKLovePython/halfsize)
[![PRs](https://img.shields.io/badge/PRs-welcome-brightgreen)](#参与贡献)

halfsizeX 是 [YKLovePython/halfsize](https://github.com/YKLovePython/halfsize)（MIT）的 Flutter 重写版。
它会把视频压到接近目标大小，同时尽量保持可看，并在 FFmpeg 支持时用 VMAF / SSIM 给出画质结论，
而不是只猜一个码率。

应用是原生桌面/移动 GUI，FFmpeg 随包内置，处理过程不离开本机。

## 为什么做

大多数“视频压缩”工具要么让你填一个无法换算成 MB 的画质参数，要么压出来的文件仍然超过上传限制。
halfsizeX 会根据目标大小、时长、分辨率和音频预算先生成编码计划，再验证结果。

## 已实现功能

- 指定目标大小（MB），内置 Discord、WhatsApp、WeChat、Gmail、Outlook、X 等平台预设。
- 自定义大小和 CRF 模式。
- H.264（`libx264`）和 H.265（`libx265`），可选 preset。
- 目标大小两遍编码；首次结果超出目标时自动重试。
- 自动选择是否降分辨率，也可强制保留原分辨率。
- 保留或去掉音频；处理单声道/立体声和音频码率预算。
- 检测 HDR（PQ/HLG），在 FFmpeg 支持时做 HDR→SDR tone mapping。
- 进度、速度、剩余时间、遍数、取消，以及失败/取消后的临时文件清理。
- VMAF / SSIM 画质测量和人类可读结论。
- 安全的输出命名（`原名.tag.mp4`，重名追加序号）和自定义输出目录。
- 桌面拖拽；所有平台使用原生文件选择器。
- Windows 内嵌视频预览（原片 / 压缩后），基于 `media_kit`。
- Android 前台服务、通知进度、SAF 输入、MediaStore Downloads 输出。
- 中英文界面；跟随系统/深色/浅色主题；设置持久化。
- Windows MSI 安装包和便携 ZIP。
- Linux AppImage、deb、rpm 和便携 tar.gz。

## 未做

- 批量队列（计划 v0.2）。
- 分享卡片。
- macOS 构建和打包（接口保持跨平台）。
- 自动更新、文件关联、首次运行下载 FFmpeg。
- 硬件编码（当前使用软件 x264/x265）。
- 字幕保留。

## 已支持的客户端

| 客户端 | 状态 | 说明 |
|---|---|---|
| Windows x64 | 已支持 | Release 构建，MSI + 便携 ZIP，内嵌预览 |
| Android arm64-v8a | 已支持 | 内置原生 FFmpeg，前台服务 |
| Android armeabi-v7a | 已支持 | 内置原生 FFmpeg |
| Linux x64 | 已支持 | AppImage、deb、rpm 和便携包；播放器库仍在完善 |
| macOS | 计划中 | 暂无 CI 和发布产物 |

## 下载

推送 `v*` tag 后，release 工作流会发布这些产物：

- `halfsizeX-<version>-windows-x64.msi`
- `halfsizeX-<version>-windows-x64-portable.zip`
- `halfsizeX-<version>-android-arm64-v8a.apk`
- `halfsizeX-<version>-android-armeabi-v7a.apk`
- `halfsizeX-<version>-linux-x64.AppImage`
- `halfsizeX-<version>-linux-x64.deb`
- `halfsizeX-<version>-linux-x64.rpm`
- `halfsizeX-<version>-linux-x64-portable.tar.gz`

## 从源码构建

需要 Flutter 3.41+ / Dart 3.11+，以及对应平台的工具链。

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

生成 MSI 和便携 ZIP 时，准备一个包含 `ffmpeg.exe`、`ffprobe.exe` 和 FFmpeg DLL 的目录：

```powershell
.\tool\package_windows.ps1 -FfmpegDir C:\path\to\ffmpeg\bin
```

脚本需要 [WiX](https://wixtoolset.org/)（`dotnet tool install --global wix`）。

### Android

```bash
cd app
flutter build apk --release --split-per-abi
```

Android FFmpeg 二进制位于 `app/android/app/src/main/jniLibs/<abi>/`。Release 签名通过
`android/key.properties` 或 `HALFSIZE_KEYSTORE`、`HALFSIZE_STORE_PASSWORD`、`HALFSIZE_KEY_ALIAS`、
`HALFSIZE_KEY_PASSWORD` 环境变量读取；CI 使用仓库 secrets。未配置 keystore 时回退 debug 签名。

### Linux

```bash
cd app
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev
flutter build linux --release
```

release 工作流随后运行 `tool/package_linux.sh`，生成 AppImage、deb、rpm 和便携 tar.gz。

## CI/CD

- `ci.yml`：在 push 和 pull request 时运行 `flutter analyze`、`flutter test`。
- `build.yml`：手动触发或 `v*` tag 时构建 Android、Windows、Linux 产物。
- tag 构建会把 Android APK、Windows ZIP/MSI、Linux AppImage/deb/rpm/便携包发布到 GitHub Release。

Android 正式签名通过 `android/key.properties` 或 `HALFSIZE_*` 环境变量读取；CI 使用仓库 secrets。
具体命令见 `.github/workflows/`。

## 隐私

探测、规划、编码和画质测量全部在本机完成。应用没有账号、云上传、分析或遥测。
网络只用于构建工具，不用于应用运行时。

## FFmpeg 与许可

halfsizeX 自身使用 MIT 许可。FFmpeg、x264、x265 保留各自许可；再分发时必须附带对应许可文本。
分发方式和 GPL 说明见 [SPEC.md](SPEC.md)。应用不会替换或隐藏 FFmpeg 的许可。

## 项目结构

```text
app/                 Flutter 应用
  lib/core/          probe、plan、encode、quality、FFmpeg 定位、设置
  lib/features/      压缩和设置界面
  android/           Android runner、前台服务、jniLibs
  windows/           Windows runner 和安装包脚本
  linux/             Linux runner、desktop entry 和图标安装规则
  test/              单元测试和 widget 测试
```

## 参与贡献

欢迎提交 issue 和 pull request。改动尽量小，行为变更请附带测试。提交 PR 前运行：

```bash
cd app
flutter analyze
flutter test
```

## 致谢

- 原项目：[YKLovePython/halfsize](https://github.com/YKLovePython/halfsize)（MIT）。
- FFmpeg、x264、x265、libvmaf 和 media_kit。
- Flutter 及 Flutter 社区。
