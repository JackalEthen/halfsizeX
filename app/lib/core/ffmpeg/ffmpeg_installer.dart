import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ffmpeg_locator.dart';

class FfmpegInstaller {
  static const _windowsUrl =
      'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';
  static const _linuxUrl =
      'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz';

  static Future<FfmpegInfo> install({
    void Function(double progress)? onProgress,
  }) async {
    if (Platform.isAndroid || Platform.isMacOS) {
      throw UnsupportedError(
        'Automatic FFmpeg installation is not available on this platform.',
      );
    }
    final url = Platform.isWindows ? _windowsUrl : _linuxUrl;
    final temp = await Directory.systemTemp.createTemp('halfsizex-ffmpeg-');
    try {
      final archive = File(
        p.join(temp.path, Platform.isWindows ? 'ffmpeg.zip' : 'ffmpeg.tar.xz'),
      );
      await _download(Uri.parse(url), archive, onProgress);
      final extracted = Directory(p.join(temp.path, 'extracted'));
      await extracted.create(recursive: true);
      await _extract(archive, extracted);
      final ffmpeg = _find(
        extracted,
        Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg',
      );
      final ffprobe = _find(
        extracted,
        Platform.isWindows ? 'ffprobe.exe' : 'ffprobe',
      );
      if (ffmpeg == null || ffprobe == null) {
        throw FileSystemException('FFmpeg files were not found.');
      }
      final bin = Directory(
        p.join((await getApplicationSupportDirectory()).path, 'bin'),
      );
      await bin.create(recursive: true);
      final targetFfmpeg = await _copy(ffmpeg, bin);
      final targetFfprobe = await _copy(ffprobe, bin);
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', targetFfmpeg.path]);
        await Process.run('chmod', ['+x', targetFfprobe.path]);
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

  static Future<void> _download(
    Uri uri,
    File target,
    void Function(double)? onProgress,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
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

  static Future<void> _extract(File archive, Directory target) async {
    final result = Platform.isWindows
        ? await Process.run('powershell', [
            '-NoProfile',
            '-Command',
            'Expand-Archive -LiteralPath "${archive.path}" '
                '-DestinationPath "${target.path}" -Force',
          ])
        : await Process.run('tar', ['-xJf', archive.path, '-C', target.path]);
    if (result.exitCode != 0) {
      throw FileSystemException('Could not extract FFmpeg: ${result.stderr}');
    }
  }

  static File? _find(Directory root, String name) {
    for (final entity in root.listSync(recursive: true)) {
      if (entity is File &&
          p.basename(entity.path).toLowerCase() == name.toLowerCase()) {
        return entity;
      }
    }
    return null;
  }

  static Future<File> _copy(File source, Directory target) async {
    final file = File(p.join(target.path, p.basename(source.path)));
    await source.copy(file.path);
    return file;
  }
}
