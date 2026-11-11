import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import '../ffmpeg/ffmpeg_locator.dart';
import 'models.dart';
import 'plan.dart';

typedef ProgressCallback = void Function(EncodeProgress progress);
typedef RetryCallback = void Function(int attempt, int videoKbps, int actualBytes);

class EncodeCancelToken {
  bool _cancelled = false;
  Process? _child;

  bool get cancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _child?.kill(ProcessSignal.sigterm);
  }

  void _attach(Process child) {
    _child = child;
    if (_cancelled) child.kill(ProcessSignal.sigterm);
  }

  void _detach() {
    _child = null;
  }
}

Future<EncodeResult> encode(
  String input,
  String output,
  EncodePlan plan,
  ProbeInfo info, {
  required FfmpegInfo bins,
  ProgressCallback? onProgress,
  EncodeCancelToken? cancel,
}) async {
  if (!bins.ok) {
    throw const HalfsizeException('HALFSIZE_FFMPEG_MISSING', 'FFmpeg was not found.');
  }
  final dir = p.dirname(output);
  Directory(dir).createSync(recursive: true);

  final temp = _tempPath(output);
  final passlog = p.join(
    Directory.systemTemp.path,
    'halfsize-${DateTime.now().millisecondsSinceEpoch}-${_hex(4)}',
  );
  final started = DateTime.now();

  try {
    if (cancel?.cancelled ?? false) {
      throw const HalfsizeException('HALFSIZE_CANCELLED', 'Cancelled.');
    }

    if (plan.mode == 'size' && plan.twoPass) {
      final pass1 = [
        ..._baseArgs(input, plan, passlog),
        '-b:v',
        '${plan.videoKbps}k',
        '-pass',
        '1',
        '-an',
        '-f',
        'null',
        _nullDevice,
      ];
      await _run(
        bins.ffmpeg,
        pass1,
        info.duration,
        (seconds, total, ratio, speed) {
          onProgress?.call(EncodeProgress(
            seconds: seconds,
            total: total,
            ratio: ratio * 0.5,
            speed: speed,
            pass: 1,
            passes: 2,
          ));
        },
        cancel,
      );

      final pass2 = [
        ..._baseArgs(input, plan, passlog),
        '-b:v',
        '${plan.videoKbps}k',
        '-pass',
        '2',
        ..._audioArgs(plan),
        '-movflags',
        '+faststart',
        temp,
      ];
      await _run(
        bins.ffmpeg,
        pass2,
        info.duration,
        (seconds, total, ratio, speed) {
          onProgress?.call(EncodeProgress(
            seconds: seconds,
            total: total,
            ratio: 0.5 + ratio * 0.5,
            speed: speed,
            pass: 2,
            passes: 2,
          ));
        },
        cancel,
      );
    } else {
      final args = [..._baseArgs(input, plan, null)];
      if (plan.mode == 'size') {
        args.addAll([
          '-b:v',
          '${plan.videoKbps}k',
          '-maxrate',
          '${(plan.videoKbps! * 1.2).round()}k',
          '-bufsize',
          '${plan.videoKbps! * 2}k',
        ]);
      } else {
        args.addAll(['-crf', '${plan.crf}']);
      }
      args.addAll([..._audioArgs(plan), '-movflags', '+faststart', temp]);
      await _run(
        bins.ffmpeg,
        args,
        info.duration,
        (seconds, total, ratio, speed) {
          onProgress?.call(EncodeProgress(
            seconds: seconds,
            total: total,
            ratio: ratio,
            speed: speed,
            pass: 1,
            passes: 1,
          ));
        },
        cancel,
      );
    }
  } catch (_) {
    await _removeQuietly(temp);
    rethrow;
  } finally {
    _cleanup(passlog);
  }

  try {
    File(temp).renameSync(output);
  } catch (e) {
    final reason = e is FileSystemException
        ? (e.osError?.message ?? e.message)
        : e.toString();
    throw HalfsizeException(
      'HALFSIZE_RENAME_FAILED',
      'Compressed, but could not replace ${p.basename(output)} '
      '($reason). The result is saved as ${p.basename(temp)}.',
    );
  }

  return EncodeResult(
    outputBytes: File(output).lengthSync(),
    elapsedMs: DateTime.now().difference(started).inMilliseconds,
  );
}

Future<EncodeToSizeResult> encodeToSize(
  String input,
  String output,
  EncodePlan plan,
  ProbeInfo info, {
  required FfmpegInfo bins,
  ProgressCallback? onProgress,
  EncodeCancelToken? cancel,
  RetryCallback? onRetry,
}) async {
  var current = plan;
  var elapsed = 0;

  for (var attempt = 1;; attempt++) {
    final result = await encode(
      input,
      output,
      current,
      info,
      bins: bins,
      onProgress: onProgress,
      cancel: cancel,
    );
    elapsed += result.elapsedMs;

    final target = plan.targetBytes;
    if (plan.mode != 'size' || target == null) {
      return EncodeToSizeResult(
        outputBytes: result.outputBytes,
        elapsedMs: elapsed,
        attempts: attempt,
        missedTarget: false,
      );
    }
    if (result.outputBytes <= target * 1.005) {
      return EncodeToSizeResult(
        outputBytes: result.outputBytes,
        elapsedMs: elapsed,
        attempts: attempt,
        missedTarget: false,
      );
    }

    final next = attempt < 3
        ? tighterPlan(current, info, result.outputBytes, target)
        : null;
    if (next == null) {
      return EncodeToSizeResult(
        outputBytes: result.outputBytes,
        elapsedMs: elapsed,
        attempts: attempt,
        missedTarget: result.outputBytes > target * 1.005,
      );
    }

    onRetry?.call(attempt + 1, next.videoKbps, result.outputBytes);
    current = current.copyWith(videoKbps: next.videoKbps);
  }
}

List<String> _baseArgs(String input, EncodePlan plan, String? passlog) {
  final args = ['-hide_banner', '-y', '-i', input, '-map', '0:v:0'];
  if (plan.audioKbps > 0) args.addAll(['-map', '0:a:0?']);
  args.addAll(['-vf', _filters(plan)]);
  args.addAll([
    '-fps_mode',
    'cfr',
    '-c:v',
    plan.encoder,
    '-preset',
    plan.preset,
  ]);
  if (plan.codec == 'h265') {
    args.addAll(['-x265-params', 'log-level=error']);
    args.addAll(['-tag:v', 'hvc1']);
  }
  args.addAll(['-pix_fmt', 'yuv420p', '-shortest']);
  if (passlog != null) args.addAll(['-passlogfile', passlog]);
  return args;
}

String _filters(EncodePlan plan) {
  final filters = <String>[];
  if (plan.toneMap != null) filters.add(plan.toneMap!);
  if (plan.scaleFilter != null) filters.add(plan.scaleFilter!);
  filters.add('fps=${_numText(plan.fps)}');
  return filters.join(',');
}

List<String> _audioArgs(EncodePlan plan) {
  if (plan.audioKbps == 0) return ['-an'];
  return [
    '-c:a',
    'aac',
    '-b:a',
    '${plan.audioKbps}k',
    '-ac',
    plan.audioChannels == 1 ? '1' : '2',
  ];
}

Future<void> _run(
  String bin,
  List<String> args,
  double duration,
  void Function(double seconds, double total, double ratio, String speed)
      onProgress,
  EncodeCancelToken? cancel,
) async {
  if (cancel?.cancelled ?? false) {
    throw const HalfsizeException('HALFSIZE_CANCELLED', 'Cancelled.');
  }

  final child = await Process.start(
    bin,
    ['-progress', 'pipe:1', '-nostats', ...args],
  );
  cancel?._attach(child);

  final stderrBuffer = StringBuffer();
  var buffer = '';
  var lastSpeed = '';

  child.stdout.transform(utf8.decoder).listen((chunk) {
    buffer += chunk;
    final lines = buffer.split(RegExp(r'\r?\n'));
    buffer = lines.removeLast();
    for (final line in lines) {
      final index = line.indexOf('=');
      if (index < 0) continue;
      final key = line.substring(0, index);
      final value = line.substring(index + 1);
      if (key == 'out_time') {
        final seconds = _parseTime(value);
        final ratio = duration > 0 ? math.min(1.0, seconds / duration) : 0.0;
        onProgress(seconds, duration, ratio, lastSpeed);
      } else if (key == 'speed') {
        lastSpeed = value;
      }
    }
  });

  child.stderr.transform(utf8.decoder).listen((chunk) {
    stderrBuffer.write(chunk);
    if (stderrBuffer.length > 20000) {
      final text = stderrBuffer.toString();
      stderrBuffer
        ..clear()
        ..write(text.substring(text.length - 20000));
    }
  });

  final code = await child.exitCode;
  cancel?._detach();

  if (cancel?.cancelled ?? false) {
    throw const HalfsizeException('HALFSIZE_CANCELLED', 'Cancelled.');
  }
  if (code != 0) {
    final tail = stderrBuffer
        .toString()
        .split(RegExp(r'\r?\n'))
        .where((line) => line.isNotEmpty)
        .toList();
    final last = tail.length > 12 ? tail.sublist(tail.length - 12) : tail;
    throw HalfsizeException(
      'HALFSIZE_ENCODE_FAILED',
      'FFmpeg exited with code $code\n${last.join('\n')}',
    );
  }
}

double _parseTime(String value) {
  if (value.isEmpty) return 0;
  final dot = value.indexOf('.');
  final hms = dot >= 0 ? value.substring(0, dot) : value;
  final frac = dot >= 0 ? value.substring(dot + 1) : '0';
  final parts = hms.split(':').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((v) => v == null)) return 0;
  return parts[0]! * 3600 +
      parts[1]! * 60 +
      parts[2]! +
      (double.tryParse('0.$frac') ?? 0);
}

String _numText(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

String _tempPath(String output) {
  final dir = p.dirname(output);
  final ext = p.extension(output);
  final base = p.basenameWithoutExtension(output);
  return p.join(dir, '.$base.part-${_hex(4)}$ext');
}

String _hex(int bytes) {
  final random = math.Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < bytes; i++) {
    buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

Future<void> _removeQuietly(String file) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    try {
      final f = File(file);
      if (f.existsSync()) f.deleteSync();
      return;
    } catch (_) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
  }
}

void _cleanup(String passlog) {
  try {
    final dir = Directory(p.dirname(passlog));
    final base = p.basename(passlog);
    for (final entity in dir.listSync()) {
      final name = p.basename(entity.path);
      if (name.startsWith(base)) {
        try {
          entity.deleteSync();
        } catch (_) {}
      }
    }
  } catch (_) {
    // best effort
  }
}

String get _nullDevice => Platform.isWindows ? 'NUL' : '/dev/null';
