import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/halfsize/models.dart';
import '../../core/halfsize/quality.dart' as q;
import '../../core/settings/app_settings.dart';
import '../compress/compress_controller.dart';

enum TaskStatus { queued, running, measuring, done, failed, cancelled }

class TaskOptions {
  const TaskOptions({
    required this.targetBytes,
    required this.codec,
    required this.preset,
    required this.downscale,
    required this.audio,
    required this.qualityCheck,
    this.crf,
    this.outputName,
  });

  final int targetBytes;
  final String codec;
  final String preset;
  final bool downscale;
  final bool audio;
  final bool qualityCheck;
  final int? crf;
  final String? outputName;
}

class CompressTask {
  CompressTask({
    required this.id,
    required this.inputPath,
    required this.options,
    required this.createdAt,
  });

  final String id;
  final String inputPath;
  final TaskOptions options;
  final DateTime createdAt;

  TaskStatus status = TaskStatus.queued;
  EncodeProgress? progress;
  ProbeInfo? info;
  EncodePlan? plan;
  EncodeToSizeResult? result;
  q.QualitySample? quality;
  q.QualityVerdict? verdict;
  String? outputPath;
  String? error;
  bool skipped = false;
  DateTime? finishedAt;

  String get name => p.basename(inputPath);
  double get ratio => (progress?.ratio ?? 0).clamp(0.0, 1.0);
  int? get inputBytes => info?.sizeBytes;
  int? get outputBytes => result?.outputBytes;
  bool get isActive =>
      status == TaskStatus.running || status == TaskStatus.measuring;
}

class TaskRecord {
  const TaskRecord({
    required this.name,
    required this.inputPath,
    required this.outputPath,
    required this.codec,
    required this.preset,
    required this.targetBytes,
    this.crf,
    this.skipped = false,
    required this.inputBytes,
    required this.outputBytes,
    required this.elapsedMs,
    required this.vmaf,
    required this.ssim,
    required this.status,
    required this.createdAt,
    required this.finishedAt,
    required this.error,
  });

  final String name;
  final String inputPath;
  final String? outputPath;
  final String codec;
  final String preset;
  final int targetBytes;
  final int? crf;
  final bool skipped;
  final int? inputBytes;
  final int? outputBytes;
  final int? elapsedMs;
  final double? vmaf;
  final double? ssim;
  final String status;
  final DateTime createdAt;
  final DateTime? finishedAt;
  final String? error;

  bool get ok => status == 'done';

  Map<String, Object?> toJson() => {
    'name': name,
    'inputPath': inputPath,
    'outputPath': outputPath,
    'codec': codec,
    'preset': preset,
    'targetBytes': targetBytes,
    'crf': crf,
    'skipped': skipped,
    'inputBytes': inputBytes,
    'outputBytes': outputBytes,
    'elapsedMs': elapsedMs,
    'vmaf': vmaf,
    'ssim': ssim,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'error': error,
  };

  factory TaskRecord.fromJson(Map<String, Object?> json) {
    final created = DateTime.tryParse('${json['createdAt']}');
    final finished = DateTime.tryParse('${json['finishedAt']}');
    return TaskRecord(
      name: '${json['name'] ?? ''}',
      inputPath: '${json['inputPath'] ?? ''}',
      outputPath: json['outputPath'] as String?,
      codec: '${json['codec'] ?? 'h264'}',
      preset: '${json['preset'] ?? 'medium'}',
      targetBytes: (json['targetBytes'] as num?)?.toInt() ?? 0,
      crf: (json['crf'] as num?)?.toInt(),
      skipped: json['skipped'] == true,
      inputBytes: (json['inputBytes'] as num?)?.toInt(),
      outputBytes: (json['outputBytes'] as num?)?.toInt(),
      elapsedMs: (json['elapsedMs'] as num?)?.toInt(),
      vmaf: (json['vmaf'] as num?)?.toDouble(),
      ssim: (json['ssim'] as num?)?.toDouble(),
      status: '${json['status'] ?? 'failed'}',
      createdAt: created ?? DateTime.now(),
      finishedAt: finished,
      error: json['error'] as String?,
    );
  }

  factory TaskRecord.fromTask(CompressTask task) => TaskRecord(
    name: task.name,
    inputPath: task.inputPath,
    outputPath: task.outputPath,
    codec: task.options.codec,
    preset: task.options.preset,
    targetBytes: task.options.targetBytes,
    crf: task.options.crf,
    skipped: task.skipped,
    inputBytes: task.inputBytes,
    outputBytes: task.outputBytes,
    elapsedMs: task.result?.elapsedMs,
    vmaf: task.quality?.vmaf,
    ssim: task.quality?.ssim,
    status: task.status.name,
    createdAt: task.createdAt,
    finishedAt: task.finishedAt,
    error: task.error,
  );
}

class TaskController extends ChangeNotifier {
  TaskController({required this.settings});

  final AppSettings settings;
  final List<CompressTask> tasks = [];
  final List<TaskRecord> history = [];

  SharedPreferences? _prefs;
  CompressController? _worker;
  bool _cancelRequested = false;
  bool _pumping = false;
  bool _disposed = false;

  static const _historyKey = 'task_history';
  static const _historyLimit = 100;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_historyKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        history
          ..clear()
          ..addAll(
            list.map(
              (item) =>
                  TaskRecord.fromJson(Map<String, Object?>.from(item as Map)),
            ),
          );
      } catch (_) {
        // Ignore a damaged history file rather than blocking the app.
      }
    }
    _notify();
  }

  int addFiles(List<String> paths, TaskOptions options) {
    final now = DateTime.now();
    var index = 0;
    for (final input in paths) {
      tasks.add(
        CompressTask(
          id: '${now.microsecondsSinceEpoch}-${index++}',
          inputPath: input,
          options: options,
          createdAt: now,
        ),
      );
    }
    _notify();
    _pump();
    return paths.length;
  }

  void cancelTask(String id) {
    CompressTask? task;
    for (final item in tasks) {
      if (item.id == id) {
        task = item;
        break;
      }
    }
    if (task == null) return;
    if (task.isActive) {
      _cancelRequested = true;
      _worker?.cancel();
      return;
    }
    if (task.status == TaskStatus.queued) {
      task.status = TaskStatus.cancelled;
      task.finishedAt = DateTime.now();
      _record(task);
      _notify();
    }
  }

  void retry(CompressTask task) {
    if (task.isActive || task.status == TaskStatus.queued) return;
    task
      ..status = TaskStatus.queued
      ..progress = null
      ..info = null
      ..plan = null
      ..result = null
      ..quality = null
      ..verdict = null
      ..outputPath = null
      ..error = null
      ..skipped = false
      ..finishedAt = null;
    _notify();
    _pump();
  }

  void removeTask(CompressTask task) {
    if (task.isActive) return;
    tasks.remove(task);
    _notify();
  }

  void clearFinished() {
    tasks.removeWhere(
      (task) =>
          task.status == TaskStatus.done ||
          task.status == TaskStatus.failed ||
          task.status == TaskStatus.cancelled,
    );
    _notify();
  }

  Future<void> clearHistory() async {
    history.clear();
    await _prefs?.remove(_historyKey);
    _notify();
  }

  void _pump() {
    if (_pumping) return;
    _pumping = true;
    unawaited(_runQueue());
  }

  Future<void> _runQueue() async {
    try {
      while (true) {
        CompressTask? next;
        for (final task in tasks) {
          if (task.status == TaskStatus.queued) {
            next = task;
            break;
          }
        }
        if (next == null) break;
        await _runTask(next);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _runTask(CompressTask task) async {
    _cancelRequested = false;
    task
      ..status = TaskStatus.running
      ..progress = null
      ..info = null
      ..plan = null
      ..result = null
      ..quality = null
      ..verdict = null
      ..outputPath = null
      ..error = null
      ..skipped = false
      ..finishedAt = null;
    _notify();

    final worker = CompressController(settings: settings)
      ..configure(
        targetBytes: task.options.targetBytes,
        codec: task.options.codec,
        preset: task.options.preset,
        downscale: task.options.downscale,
        audio: task.options.audio,
        qualityCheck: task.options.qualityCheck,
        crf: task.options.crf,
        outputName: task.options.outputName,
      );
    _worker = worker;

    void listener() {
      task.info = worker.info;
      task.plan = worker.plan;
      task.progress = worker.progress;
      task.result = worker.result;
      task.quality = worker.quality;
      task.verdict = worker.verdict;
      task.outputPath = worker.outputPath;
      task.error = worker.error;
      task.skipped = worker.skipped;
      if (worker.stage == CompressStage.measuring) {
        task.status = TaskStatus.measuring;
      } else if (worker.stage == CompressStage.encoding) {
        task.status = TaskStatus.running;
      }
      _notify();
    }

    worker.addListener(listener);
    try {
      await worker.loadPath(task.inputPath);
      if (_cancelRequested) {
        task.status = TaskStatus.cancelled;
      } else if (worker.stage == CompressStage.error) {
        task.status = TaskStatus.failed;
        task.error = worker.error ?? 'Could not read this video.';
      } else {
        await worker.start();
        if (_cancelRequested) {
          task.status = TaskStatus.cancelled;
        } else if (worker.stage == CompressStage.done) {
          task.status = TaskStatus.done;
        } else {
          task.status = TaskStatus.failed;
          task.error = worker.error ?? 'Compression failed.';
        }
      }
    } catch (e) {
      task.status = TaskStatus.failed;
      task.error = e.toString();
    } finally {
      task.finishedAt = DateTime.now();
      if (task.status == TaskStatus.done ||
          task.status == TaskStatus.failed ||
          task.status == TaskStatus.cancelled) {
        _record(task);
      }
      worker.removeListener(listener);
      worker.dispose();
      _worker = null;
      _cancelRequested = false;
      _notify();
    }
  }

  void _record(CompressTask task) {
    history.insert(0, TaskRecord.fromTask(task));
    if (history.length > _historyLimit) {
      history.removeRange(_historyLimit, history.length);
    }
    unawaited(_saveHistory());
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs = prefs;
      await prefs.setString(
        _historyKey,
        jsonEncode(history.map((record) => record.toJson()).toList()),
      );
    } catch (_) {
      // History is a convenience; a failed write must not break compression.
    }
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _worker?.cancel();
    _worker?.dispose();
    super.dispose();
  }
}
