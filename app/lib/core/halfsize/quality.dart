import 'dart:io';
import 'dart:math' as math;

import '../ffmpeg/ffmpeg_locator.dart';
import 'hdr.dart';

class QualitySample {
  const QualitySample({
    required this.ssim,
    required this.vmaf,
    required this.sampled,
    required this.samples,
  });

  final double? ssim;
  final double? vmaf;
  final int sampled;
  final int samples;
}

class QualityVerdict {
  const QualityVerdict(this.key, this.label, this.tone);

  final String key;
  final String label;
  final String tone;
}

Future<QualitySample> measureQuality(
  String source,
  String output,
  double duration, {
  required FfmpegInfo bins,
  int samples = 3,
  double seconds = 2,
  bool vmaf = true,
  bool sourceHdr = false,
  String? sourceTransfer,
}) async {
  if (!bins.ok) {
    return const QualitySample(ssim: null, vmaf: null, sampled: 0, samples: 0);
  }
  final sampleSeconds = math.min(seconds, math.max(1.0, duration / 4));
  final points = <double>[];
  for (var i = 0; i < samples; i++) {
    final at = (duration * (i + 1)) / (samples + 1) - sampleSeconds / 2;
    points.add(math.max(0.0, math.min(duration - sampleSeconds, at)));
  }

  final ssims = <double>[];
  for (final at in points) {
    final value = await _runMetric(bins.ffmpeg, [
      '-ss',
      _num(at),
      '-t',
      _num(sampleSeconds),
      '-i',
      output,
      '-ss',
      _num(at),
      '-t',
      _num(sampleSeconds),
      '-i',
      source,
      '-lavfi',
      _metricGraph(
        sourceHdr: sourceHdr,
        sourceTransfer: sourceTransfer,
        metric: 'ssim',
      ),
      '-f',
      'null',
      _nullDevice,
    ], RegExp(r'All:\s*([0-9.]+)'));
    if (value != null) ssims.add(value);
  }

  double? vmafScore;
  if (vmaf && duration > 1) {
    final at = math.max(0.0, duration / 2 - 1.5);
    vmafScore = await _runMetric(bins.ffmpeg, [
      '-ss',
      _num(at),
      '-t',
      '3',
      '-i',
      output,
      '-ss',
      _num(at),
      '-t',
      '3',
      '-i',
      source,
      '-lavfi',
      _metricGraph(
        sourceHdr: sourceHdr,
        sourceTransfer: sourceTransfer,
        metric: 'libvmaf=n_threads=2',
      ),
      '-f',
      'null',
      _nullDevice,
    ], RegExp(r'VMAF score:\s*([0-9.]+)'));
  }

  final ssim = ssims.isEmpty
      ? null
      : ssims.reduce((a, b) => a + b) / ssims.length;
  return QualitySample(
    ssim: ssim,
    vmaf: vmafScore,
    sampled: ssims.length,
    samples: samples,
  );
}

QualityVerdict verdict({double? vmaf, double? ssim}) {
  if (vmaf != null) {
    if (vmaf >= 95) {
      return const QualityVerdict(
        'indistinguishable',
        'indistinguishable',
        'good',
      );
    }
    if (vmaf >= 90) {
      return const QualityVerdict('same', 'looks the same', 'good');
    }
    if (vmaf >= 80) {
      return const QualityVerdict('slight', 'slight softening', 'ok');
    }
    if (vmaf >= 70) {
      return const QualityVerdict('visible', 'visible loss', 'warn');
    }
    return const QualityVerdict('degraded', 'clearly degraded', 'bad');
  }
  if (ssim != null) {
    if (ssim >= 0.98) {
      return const QualityVerdict(
        'indistinguishable',
        'indistinguishable',
        'good',
      );
    }
    if (ssim >= 0.95) {
      return const QualityVerdict('same', 'looks the same', 'good');
    }
    if (ssim >= 0.9) {
      return const QualityVerdict('slight', 'slight softening', 'ok');
    }
    return const QualityVerdict('visible', 'visible loss', 'warn');
  }
  return const QualityVerdict('none', 'not measured', 'unknown');
}

String _metricGraph({
  required bool sourceHdr,
  required String? sourceTransfer,
  required String metric,
}) {
  if (!sourceHdr) return '[0:v][1:v]scale2ref[a][b];[a][b]$metric';
  return '[1:v]${toneMapFilter(sourceTransfer)}[ref];'
      '[0:v][ref]scale2ref[a][b];[a][b]$metric';
}

Future<double?> _runMetric(String bin, List<String> args, RegExp regex) async {
  try {
    final result = await Process.run(bin, [
      '-hide_banner',
      '-nostats',
      ...args,
    ]).timeout(const Duration(seconds: 120));
    final match = regex.firstMatch(result.stderr as String);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  } catch (_) {
    return null;
  }
}

String _num(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

String get _nullDevice => Platform.isWindows ? 'NUL' : '/dev/null';
