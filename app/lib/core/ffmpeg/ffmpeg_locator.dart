import 'dart:io';

import 'package:path/path.dart' as p;

import '../platform/android_bridge.dart';

class FfmpegInfo {
  const FfmpegInfo({
    required this.ffmpeg,
    required this.ffprobe,
    required this.source,
    this.version,
    this.encoders = const {},
    this.filters = const {},
  });

  final String ffmpeg;
  final String ffprobe;
  final String source;
  final String? version;
  final Map<String, bool> encoders;
  final Map<String, bool> filters;

  bool get ok => ffmpeg.isNotEmpty && ffprobe.isNotEmpty;

  static const missing =
      FfmpegInfo(ffmpeg: '', ffprobe: '', source: 'none');
}

class FfmpegLocator {
  static Future<FfmpegInfo> resolve() async {
    if (Platform.isAndroid) {
      final paths = await AndroidBridge.ffmpegPaths();
      if (paths == null) return FfmpegInfo.missing;
      return _inspect(paths.$1, paths.$2, 'bundled');
    }

    final envFfmpeg = Platform.environment['HALFSIZE_FFMPEG'];
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final candidates = <(String, String)>[
      if (envFfmpeg != null && envFfmpeg.isNotEmpty) (envFfmpeg, 'env'),
      (p.join(exeDir, 'bin', _exeName('ffmpeg')), 'bundled'),
      (p.join(exeDir, '..', 'Resources', 'bin', _exeName('ffmpeg')),
          'bundled'),
      (_exeName('ffmpeg'), 'path'),
    ];

    for (final (candidate, source) in candidates) {
      if (!await _works(candidate)) continue;
      return _inspect(candidate, _ffprobeFor(candidate, source), source);
    }
    return FfmpegInfo.missing;
  }

  static String _exeName(String name) => Platform.isWindows ? '$name.exe' : name;

  static String _ffprobeFor(String ffmpeg, String source) {
    final env = Platform.environment['HALFSIZE_FFPROBE'];
    if (env != null && env.isNotEmpty) return env;
    if (source == 'path') return _exeName('ffprobe');
    return p.join(p.dirname(ffmpeg), _exeName('ffprobe'));
  }

  static Future<bool> _works(String bin) async {
    try {
      final result = await Process.run(bin, ['-version'])
          .timeout(const Duration(seconds: 6));
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<FfmpegInfo> _inspect(
    String ffmpeg,
    String ffprobe,
    String source,
  ) async {
    String? version;
    final encoders = <String, bool>{};
    final filters = <String, bool>{};
    try {
      final v = await Process.run(ffmpeg, ['-version'])
          .timeout(const Duration(seconds: 6));
      version = (v.stdout as String)
          .split('\n')
          .first
          .replaceFirst('ffmpeg version ', '')
          .trim();
      final e = await Process.run(ffmpeg, ['-hide_banner', '-encoders'])
          .timeout(const Duration(seconds: 6));
      final enc = e.stdout as String;
      for (final name in const ['libx264', 'libx265']) {
        encoders[name] = enc.contains(name);
      }
      final f = await Process.run(ffmpeg, ['-hide_banner', '-filters'])
          .timeout(const Duration(seconds: 6));
      final filtersOut = f.stdout as String;
      for (final name in const ['libvmaf', 'zscale', 'tonemap']) {
        filters[name] = filtersOut.contains(name);
      }
    } catch (_) {
      // Version already proved the binary runs; extra probes are best effort.
    }
    return FfmpegInfo(
      ffmpeg: ffmpeg,
      ffprobe: ffprobe,
      source: source,
      version: version,
      encoders: encoders,
      filters: filters,
    );
  }
}
