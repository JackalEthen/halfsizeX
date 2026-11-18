import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ffmpeg_locator.dart';

class FfmpegInstaller {
  static const _release = 'b6.1.1';
  static const _officialBase =
      'https://github.com/eugeneware/ffmpeg-static/releases/download';
  static const _mirrorBase =
      'https://registry.npmmirror.com/-/binary/ffmpeg-static';

  static const _digests = <String, String>{
    'ffmpeg-darwin-arm64.gz':
        '8923876afa8db5585022d7860ec7e589af192f441c56793971276d450ed3bbfa',
    'ffmpeg-darwin-x64.gz':
        '929b375c1182d956c51f7ac25e0b2b0411fb01f6f407aa15c9758efeb4242106',
    'ffmpeg-linux-arm.gz':
        '64b115a12f0ab77c277e3c418aae8b40ef881e75e746a0e2d066a206b9bc5172',
    'ffmpeg-linux-arm64.gz':
        '754a678672298bc68156adff58aa7385a592c2b30b1d0ae8750c45c915c4bac0',
    'ffmpeg-linux-ia32.gz':
        '169b27c078a8ecedb814cac67afccf15a9868d63e9d74ef86088adefaa500d00',
    'ffmpeg-linux-x64.gz':
        'bfe8a8fc511530457b528c48d77b5737527b504a3797a9bc4866aeca69c2dffa',
    'ffmpeg-win32-x64.gz':
        '8883a3dffbd0a16cf4ef95206ea05283f78908dbfb118f73c83f4951dcc06d77',
    'ffprobe-darwin-arm64.gz':
        'd986a8ec7b030899fe66a8a288ed809a3543338705a3ce178cfb85869c5d80be',
    'ffprobe-darwin-x64.gz':
        'd4da574d6e2e197bd259b47d69cf262df9e312af24ad960444f6d806d3d4c186',
    'ffprobe-linux-arm.gz':
        '2471169c19fea00018413eebf188703c19ae5ab614477465146d4cdc7458b55d',
    'ffprobe-linux-arm64.gz':
        '2ab6aba60ee84412dff9188720703376cb4e7aaf7e0b5e43aa8249f2acae5bf8',
    'ffprobe-linux-ia32.gz':
        'a75c55bcaad1b0e79f2201d82b9cc43903d950857615f91baaea5ce92d756e63',
    'ffprobe-linux-x64.gz':
        '25d9b6ccb05e3d9de9e04e31e2506d8dd7f9f0418981965ac6df12e8d3afd067',
    'ffprobe-win32-x64.gz':
        'f309e6223ad89d2fe54bccd420a7709b66fd27540674e92309578ed491a43c8d',
  };

  static bool get canInstall => !Platform.isAndroid && _resolveTarget() != null;

  static Future<FfmpegInfo> install({
    void Function(double progress)? onProgress,
  }) async {
    if (Platform.isAndroid) {
      throw UnsupportedError(
        'Automatic FFmpeg installation is not available on Android.',
      );
    }
    final target = _resolveTarget();
    if (target == null) {
      throw UnsupportedError(
        'No FFmpeg build is available for this platform and architecture.',
      );
    }

    final current = await FfmpegLocator.resolve();
    if (current.ok) return current;

    final bin = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'bin'),
    );
    await bin.create(recursive: true);
    final temp = await Directory.systemTemp.createTemp('halfsizex-ffmpeg-');
    try {
      var completed = 0;
      for (final name in const ['ffmpeg', 'ffprobe']) {
        await _installBinary(
          name,
          target,
          bin,
          temp,
          (value) =>
              onProgress?.call(((completed + value) / 2).clamp(0.0, 1.0)),
        );
        completed++;
        onProgress?.call((completed / 2).clamp(0.0, 1.0));
      }
      final info = await FfmpegLocator.resolve();
      if (!info.ok) {
        throw FileSystemException('FFmpeg was installed but is not runnable.');
      }
      return info;
    } finally {
      try {
        await temp.delete(recursive: true);
      } catch (_) {}
    }
  }

  static Future<void> _installBinary(
    String name,
    _Target target,
    Directory bin,
    Directory temp,
    void Function(double) onProgress,
  ) async {
    final asset = '$name-${target.platform}-${target.arch}.gz';
    final expected = _digests[asset];
    if (expected == null) {
      throw FileSystemException('No published checksum for $asset.');
    }

    final exe = Platform.isWindows ? '.exe' : '';
    final dest = File(p.join(bin.path, '$name$exe'));
    final gz = File(p.join(temp.path, asset));
    final part = File('${dest.path}.part$exe');
    final failures = <String>[];

    for (final url in _urls(asset)) {
      try {
        await _download(url, gz, onProgress);
        final actual = await _sha256(gz);
        if (actual != expected) {
          throw StateError(
            'checksum mismatch (got ${actual.substring(0, 12)}, '
            'expected ${expected.substring(0, 12)})',
          );
        }
        await part.writeAsBytes(
          gzip.decode(await gz.readAsBytes()),
          flush: true,
        );
        if (!Platform.isWindows) {
          await Process.run('chmod', ['+x', part.path]);
        }
        if (!await _works(part.path)) {
          throw StateError('the unpacked binary did not run');
        }
        if (await dest.exists()) await dest.delete();
        await part.rename(dest.path);
        try {
          await gz.delete();
        } catch (_) {}
        return;
      } catch (e) {
        failures.add('$url -> $e');
        try {
          await gz.delete();
        } catch (_) {}
        try {
          await part.delete();
        } catch (_) {}
      }
    }

    throw FileSystemException(
      'Could not download $name:\n  ${failures.join('\n  ')}',
    );
  }

  static List<Uri> _urls(String asset) {
    final bases = <String?>[
      Platform.environment['HALFSIZE_BINARIES_URL'],
      Platform.environment['FFMPEG_BINARIES_URL'],
      _officialBase,
      _mirrorBase,
    ];
    final urls = <Uri>[];
    final seen = <String>{};
    for (final base in bases) {
      if (base == null || base.isEmpty) continue;
      final normalized = base.replaceAll(RegExp(r'/+$'), '');
      final value = '$normalized/$_release/$asset';
      if (seen.add(value)) urls.add(Uri.parse(value));
    }
    return urls;
  }

  static Future<void> _download(
    Uri uri,
    File target,
    void Function(double)? onProgress,
  ) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'halfsizeX');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Download failed with HTTP ${response.statusCode}.',
          uri: uri,
        );
      }
      final total = response.contentLength;
      var received = 0;
      final sink = target.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) {
            onProgress?.call((received / total).clamp(0.0, 1.0));
          }
        }
      } finally {
        await sink.close();
      }
      onProgress?.call(1);
    } finally {
      client.close(force: true);
    }
  }

  static Future<String> _sha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  static Future<bool> _works(String path) async {
    try {
      final result = await Process.run(path, [
        '-version',
      ]).timeout(const Duration(seconds: 20));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static _Target? _resolveTarget() {
    final abi = Abi.current();
    if (Platform.isWindows) {
      if (abi == Abi.windowsArm64) {
        return const _Target('win32', 'x64', true);
      }
      if (abi == Abi.windowsX64) {
        return const _Target('win32', 'x64', false);
      }
      return null;
    }
    if (Platform.isMacOS) {
      if (abi == Abi.macosArm64) {
        return const _Target('darwin', 'arm64', false);
      }
      if (abi == Abi.macosX64) {
        return const _Target('darwin', 'x64', false);
      }
      return null;
    }
    if (Platform.isLinux) {
      if (abi == Abi.linuxX64) {
        return const _Target('linux', 'x64', false);
      }
      if (abi == Abi.linuxArm64) {
        return const _Target('linux', 'arm64', false);
      }
      if (abi == Abi.linuxArm) {
        return const _Target('linux', 'arm', false);
      }
      if (abi == Abi.linuxIA32) {
        return const _Target('linux', 'ia32', false);
      }
    }
    return null;
  }
}

class _Target {
  const _Target(this.platform, this.arch, this.emulated);

  final String platform;
  final String arch;
  final bool emulated;
}
