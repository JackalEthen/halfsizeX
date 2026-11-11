import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../core/ffmpeg/ffmpeg_locator.dart';
import '../../core/halfsize/encode.dart';
import '../../core/halfsize/models.dart';
import '../../core/halfsize/plan.dart';
import '../../core/halfsize/probe.dart';
import '../../core/halfsize/quality.dart' as q;
import '../../core/platform/android_bridge.dart';
import '../../core/settings/app_settings.dart';

enum CompressStage { idle, probing, ready, encoding, measuring, done, error }

class CompressController extends ChangeNotifier {
  CompressController({AppSettings? settings}) : _settings = settings {
    _applyDefaults();
  }

  final AppSettings? _settings;
  bool _customized = false;

  CompressStage stage = CompressStage.idle;
  String? inputPath;
  ProbeInfo? info;
  EncodePlan? plan;
  String? outputPath;
  int targetBytes = 20000000;
  String? platformPreset;
  String codec = 'h264';
  String preset = 'medium';
  bool downscale = true;
  bool audio = true;
  bool qualityCheck = true;
  EncodeProgress? progress;
  q.QualitySample? quality;
  q.QualityVerdict? verdict;
  int? crf;
  EncodeToSizeResult? result;
  String? error;
  FfmpegInfo bins = FfmpegInfo.missing;

  EncodeCancelToken? _cancel;
  bool _disposed = false;
  int _lastAndroidPercent = -1;

  String get targetLabel => platformPreset ?? _targetLabel(targetBytes);

  String get fileTag => crf != null
      ? 'crf$crf'
      : (platformPreset ?? _targetLabel(targetBytes).toLowerCase());

  void _applyDefaults() {
    final s = _settings;
    targetBytes = s?.defaultTargetBytes ?? 20000000;
    codec = s?.defaultCodec ?? 'h264';
    preset = s?.defaultPreset ?? 'medium';
    qualityCheck = s?.qualityCheck ?? true;
    platformPreset = null;
  }

  Future<void> pick() async {
    PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(type: FileType.video);
    } catch (e) {
      error = e.toString();
      stage = CompressStage.error;
      _notify();
      return;
    }
    final path = picked?.path;
    if (path == null) return;
    await loadPath(path);
  }

  Future<void> loadPath(String path) async {
    if (!_customized) _applyDefaults();
    inputPath = path;
    info = null;
    plan = null;
    result = null;
    progress = null;
    error = null;
    stage = CompressStage.probing;
    _notify();

    bins = await FfmpegLocator.resolve();
    if (!bins.ok) {
      error = Platform.isAndroid
          ? 'FFmpeg is not bundled in this build.'
          : 'FFmpeg was not found. Set HALFSIZE_FFMPEG or bundle it next to the app.';
      stage = CompressStage.error;
      _notify();
      return;
    }

    try {
      info = await probeFile(path, bins: bins);
      if (info!.video.hdr && !(bins.filters['zscale'] ?? true)) {
        error = 'This FFmpeg build cannot tone map HDR. Use an SDR source.';
        stage = CompressStage.error;
        _notify();
        return;
      }
      _replan();
      stage = CompressStage.ready;
    } catch (e) {
      error = e.toString();
      stage = CompressStage.error;
    }
    _notify();
  }

  void setTargetBytes(int bytes) {
    _customized = true;
    targetBytes = bytes;
    platformPreset = null;
    crf = null;
    _replan();
  }

  void setPreset(String id, int bytes) {
    _customized = true;
    targetBytes = bytes;
    platformPreset = id;
    crf = null;
    _replan();
  }

  void setCrf(int value) {
    _customized = true;
    crf = value;
    platformPreset = null;
    _replan();
  }

  void setCodec(String value) {
    _customized = true;
    codec = value;
    _replan();
  }

  void setDownscale(bool value) {
    _customized = true;
    downscale = value;
    _replan();
  }

  void setAudio(bool value) {
    _customized = true;
    audio = value;
    _replan();
  }

  void setQualityCheck(bool value) {
    qualityCheck = value;
    _notify();
  }

  void _replan() {
    final i = info;
    if (i == null) return;
    try {
      plan = planEncode(
        i,
        PlanOptions(
          targetBytes: crf == null ? targetBytes : null,
          crf: crf,
          codec: codec,
          preset: preset,
          downscale: downscale,
          audio: audio,
        ),
      );
      error = null;
    } catch (e) {
      plan = null;
      error = e.toString();
    }
    _notify();
  }

  Future<void> start({bool force = false}) async {
    final i = info;
    final current = plan;
    if (i == null ||
        current == null ||
        stage == CompressStage.encoding ||
        stage == CompressStage.measuring) {
      return;
    }
    if (current.infeasible && !force) {
      error = 'The target is below the minimum bitrate for this video.';
      stage = CompressStage.error;
      _notify();
      return;
    }

    stage = CompressStage.encoding;
    progress = null;
    result = null;
    quality = null;
    verdict = null;
    error = null;
    outputPath = _uniqueOutput(i.file);
    _cancel = EncodeCancelToken();
    _lastAndroidPercent = -1;
    if (Platform.isAndroid) {
      await AndroidBridge.startService('halfsizeX');
    }
    _notify();

    try {
      final encoded = await encodeToSize(
        i.file,
        outputPath!,
        current,
        i,
        bins: bins,
        cancel: _cancel,
        onProgress: (value) {
          progress = value;
          if (Platform.isAndroid) {
            final percent = (value.ratio * 100).round();
            if (percent - _lastAndroidPercent >= 2 || percent >= 100) {
              _lastAndroidPercent = percent;
              AndroidBridge.updateProgress(percent, '$percent%');
            }
          }
          _notify();
        },
      );
      result = encoded;
      if (qualityCheck) {
        stage = CompressStage.measuring;
        _notify();
        try {
          quality = await q.measureQuality(
            i.file,
            outputPath!,
            i.duration,
            bins: bins,
            sourceHdr: i.video.hdr,
            sourceTransfer: i.video.hdrTransfer ?? i.video.colorTransfer,
          );
          verdict = q.verdict(vmaf: quality?.vmaf, ssim: quality?.ssim);
        } catch (_) {
          quality = null;
          verdict = q.verdict();
        }
      } else {
        quality = null;
        verdict = q.verdict();
      }
      if (Platform.isAndroid) {
        final exported = await AndroidBridge.exportToDownloads(
          outputPath!,
          p.basename(outputPath!),
        );
        if (exported != null) {
          try {
            await File(outputPath!).delete();
          } catch (_) {}
          outputPath = exported;
        }
      }
      stage = CompressStage.done;
    } on HalfsizeException catch (e) {
      if (e.code == 'HALFSIZE_CANCELLED') {
        stage = CompressStage.ready;
      } else {
        error = e.message;
        stage = CompressStage.error;
      }
    } catch (e) {
      error = e.toString();
      stage = CompressStage.error;
    } finally {
      if (Platform.isAndroid) await AndroidBridge.stopService();
    }
    _cancel = null;
    _notify();
  }

  void cancel() => _cancel?.cancel();

  void reset() {
    if (Platform.isAndroid) AndroidBridge.stopService();
    _customized = false;
    stage = CompressStage.idle;
    inputPath = null;
    info = null;
    plan = null;
    outputPath = null;
    progress = null;
    result = null;
    quality = null;
    verdict = null;
    error = null;
    _notify();
  }

  String _uniqueOutput(String input) {
    final configured = _settings?.outputDir;
    final dir =
        !Platform.isAndroid &&
            configured != null &&
            configured.isNotEmpty &&
            Directory(configured).existsSync()
        ? configured
        : p.dirname(input);
    final base = '${p.basenameWithoutExtension(input)}.$fileTag';
    var candidate = p.join(dir, '$base.mp4');
    var index = 2;
    while (File(candidate).existsSync()) {
      candidate = p.join(dir, '$base ($index).mp4');
      index++;
    }
    return candidate;
  }

  static String _targetLabel(int bytes) {
    if (bytes % 1000000 == 0) return '${bytes ~/ 1000000}MB';
    return '${(bytes / 1000000).toStringAsFixed(1)}MB';
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancel?.cancel();
    super.dispose();
  }
}
