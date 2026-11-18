import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../core/halfsize/human.dart';
import '../../core/platform/android_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../l10n/task_text.dart';
import 'task_controller.dart';

class TaskPage extends StatefulWidget {
  const TaskPage({super.key, required this.tasks, required this.compact});

  final TaskController tasks;
  final bool compact;

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  String? _selectedId;

  CompressTask? _selected() {
    for (final task in widget.tasks.tasks) {
      if (task.id == _selectedId) return task;
    }
    return widget.tasks.tasks.isEmpty ? null : widget.tasks.tasks.first;
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskHistoryPage(tasks: widget.tasks),
      ),
    );
  }

  void _openDetail(CompressTask task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskDetailPage(task: task, tasks: widget.tasks),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tasks,
      builder: (context, _) {
        final p = AppPalette.of(context);
        final active = widget.tasks.tasks.where((task) => task.isActive).length;
        final header = _Header(
          active: active,
          onHistory: _openHistory,
          onClear:
              widget.tasks.tasks.any(
                (task) =>
                    task.status == TaskStatus.done ||
                    task.status == TaskStatus.failed ||
                    task.status == TaskStatus.cancelled,
              )
              ? widget.tasks.clearFinished
              : null,
        );
        if (widget.compact) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              header,
              const SizedBox(height: 14),
              if (widget.tasks.tasks.isEmpty)
                _Empty()
              else
                for (final task in widget.tasks.tasks) ...[
                  _TaskCard(
                    task: task,
                    selected: false,
                    onTap: () => _openDetail(task),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        }

        final selected = _selected();
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header,
                    const SizedBox(height: 14),
                    Expanded(
                      child: widget.tasks.tasks.isEmpty
                          ? _Empty()
                          : ListView.separated(
                              itemCount: widget.tasks.tasks.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final task = widget.tasks.tasks[index];
                                return _TaskCard(
                                  task: task,
                                  selected: task.id == selected?.id,
                                  onTap: () =>
                                      setState(() => _selectedId = task.id),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Center(child: Container(width: 1, height: 360, color: p.line)),
              const SizedBox(width: 24),
              Expanded(
                child: selected == null
                    ? _Empty()
                    : SingleChildScrollView(
                        child: _TaskDetailPane(
                          task: selected,
                          tasks: widget.tasks,
                          onShare: () => _openShare(selected),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openShare(CompressTask task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ShareCardPage(task: task)));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.active, required this.onHistory, this.onClear});

  final int active;
  final VoidCallback onHistory;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Text(
          TaskText.t(context, '任务', 'Tasks'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: p.text,
          ),
        ),
        if (active > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              TaskText.t(context, '$active 个进行中', '$active running'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: p.accent,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onClear != null)
          IconButton(
            onPressed: onClear,
            icon: Icon(
              Icons.cleaning_services_outlined,
              size: 20,
              color: p.dim,
            ),
            tooltip: TaskText.t(context, '清除已完成', 'Clear finished'),
          ),
        IconButton(
          onPressed: onHistory,
          icon: Icon(Icons.history, size: 21, color: p.muted),
          tooltip: TaskText.t(context, '历史记录', 'History'),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: p.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 30, color: p.dim),
            const SizedBox(height: 10),
            Text(
              TaskText.t(context, '还没有任务', 'No tasks yet'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TaskText.t(
                context,
                '在压缩页选择视频后，任务会出现在这里。',
                'Pick videos on the Compress tab and they show up here.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: p.dim),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.selected,
    required this.onTap,
  });

  final CompressTask task;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = _statusColor(p, task.status);
    final progress = task.ratio;
    return Material(
      color: selected ? p.panel2 : p.panel,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? p.accent.withValues(alpha: 0.45) : p.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                  ),
                  Text(
                    _statusLabel(context, task.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                TaskText.t(
                  context,
                  '目标 ${bytes(task.options.targetBytes)} · ${task.options.codec == 'h265' ? 'H.265' : 'H.264'}',
                  'Target ${bytes(task.options.targetBytes)} · ${task.options.codec == 'h265' ? 'H.265' : 'H.264'}',
                ),
                style: TextStyle(fontSize: 11.5, color: p.dim),
              ),
              if (task.isActive) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: p.panel2,
                    color: p.accent,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(fontSize: 10.5, color: p.dim),
                ),
              ] else if (task.status == TaskStatus.done) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      bytes(task.outputBytes),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.accent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ratio(
                        task.inputBytes,
                        task.outputBytes,
                      ).replaceAll('x', '×'),
                      style: TextStyle(fontSize: 11.5, color: p.dim),
                    ),
                  ],
                ),
              ] else if (task.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  task.error!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: p.bad),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key, required this.task, required this.tasks});

  final CompressTask task;
  final TaskController tasks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TaskText.t(context, '任务详情', 'Task details')),
        backgroundColor: AppPalette.of(context).bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: tasks,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              _TaskDetailPane(
                task: task,
                tasks: tasks,
                onShare: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ShareCardPage(task: task),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskDetailPane extends StatelessWidget {
  const _TaskDetailPane({
    required this.task,
    required this.tasks,
    required this.onShare,
  });

  final CompressTask task;
  final TaskController tasks;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = _statusColor(p, task.status);
    final result = task.result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(context, task.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                task.inputPath,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: p.dim),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(text: bytes(task.options.targetBytes)),
                  _Tag(text: task.options.codec == 'h265' ? 'H.265' : 'H.264'),
                  _Tag(text: task.options.preset),
                  if (task.info != null)
                    _Tag(
                      text:
                          '${task.info!.video.width}×${task.info!.video.height}',
                    ),
                ],
              ),
              if (task.isActive) ...[
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: task.ratio,
                    minHeight: 9,
                    backgroundColor: p.panel2,
                    color: p.accent,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${(task.ratio * 100).round()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.accent,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      task.progress?.speed ?? '',
                      style: TextStyle(fontSize: 12, color: p.dim),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => tasks.cancelTask(task.id),
                  child: Text(TaskText.t(context, '取消任务', 'Cancel task')),
                ),
              ],
              if (task.status == TaskStatus.queued) ...[
                const SizedBox(height: 18),
                Text(
                  TaskText.t(
                    context,
                    '等待前面的任务完成。',
                    'Waiting for the current task to finish.',
                  ),
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
              ],
              if (task.status == TaskStatus.failed ||
                  task.status == TaskStatus.cancelled) ...[
                const SizedBox(height: 18),
                Text(
                  task.error ??
                      TaskText.t(context, '任务未完成。', 'The task did not finish.'),
                  style: TextStyle(fontSize: 13, height: 1.45, color: p.bad),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => tasks.retry(task),
                  child: Text(TaskText.t(context, '重试', 'Retry')),
                ),
              ],
              if (task.status == TaskStatus.done && result != null) ...[
                const SizedBox(height: 18),
                Text(
                  ratio(
                    task.inputBytes,
                    result.outputBytes,
                  ).replaceAll('x', '×'),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TaskText.t(
                    context,
                    '${bytes(task.inputBytes)} → ${bytes(result.outputBytes)}',
                    '${bytes(task.inputBytes)} → ${bytes(result.outputBytes)}',
                  ),
                  style: TextStyle(fontSize: 13, color: p.muted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Stat(
                      label: 'VMAF',
                      value: task.quality?.vmaf?.toStringAsFixed(1) ?? '—',
                    ),
                    const SizedBox(width: 8),
                    _Stat(
                      label: 'SSIM',
                      value: task.quality?.ssim?.toStringAsFixed(3) ?? '—',
                    ),
                    const SizedBox(width: 8),
                    _Stat(
                      label: TaskText.t(context, '耗时', 'Time'),
                      value: duration((result.elapsedMs / 1000)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.panel2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    children: [
                      _kv(
                        p,
                        TaskText.t(context, '输出文件', 'Output'),
                        path.basename(task.outputPath ?? ''),
                      ),
                      _kv(
                        p,
                        TaskText.t(context, '分辨率', 'Resolution'),
                        task.plan == null
                            ? '-'
                            : '${task.plan!.width}×${task.plan!.height}',
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        task.outputPath ?? '',
                        style: TextStyle(fontSize: 11, color: p.dim),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openOutput(task.outputPath),
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: Text(
                          Platform.isAndroid
                              ? TaskText.t(context, '打开文件', 'Open file')
                              : TaskText.t(context, '打开文件夹', 'Open folder'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onShare,
                        icon: const Icon(Icons.ios_share, size: 16),
                        label: Text(TaskText.t(context, '分享', 'Share')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => tasks.retry(task),
                  child: Text(TaskText.t(context, '再压一次', 'Compress again')),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Widget _kv(AppPalette p, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: p.dim)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: p.panel2,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: p.line),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: p.muted,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: p.panel2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.line),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: p.dim,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskHistoryPage extends StatelessWidget {
  const TaskHistoryPage({super.key, required this.tasks});

  final TaskController tasks;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(TaskText.t(context, '历史记录', 'History')),
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (tasks.history.isNotEmpty)
            IconButton(
              onPressed: tasks.clearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: TaskText.t(context, '清空历史', 'Clear history'),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: tasks,
        builder: (context, _) {
          if (tasks.history.isEmpty) {
            return Center(
              child: Text(
                TaskText.t(context, '还没有历史记录', 'No history yet'),
                style: TextStyle(fontSize: 13, color: p.dim),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: tasks.history.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final record = tasks.history[index];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  children: [
                    Icon(
                      record.ok
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 20,
                      color: record.ok ? p.accent : p.bad,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            record.ok
                                ? '${bytes(record.inputBytes)} → ${bytes(record.outputBytes)}'
                                : (record.error ??
                                      TaskText.t(context, '失败', 'Failed')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: p.dim),
                          ),
                          if (record.outputPath != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              record.outputPath!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10.5, color: p.dim),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (record.outputPath != null)
                      IconButton(
                        onPressed: () => _openOutput(record.outputPath),
                        icon: const Icon(Icons.folder_open, size: 18),
                        tooltip: TaskText.t(context, '打开', 'Open'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ShareCardPage extends StatefulWidget {
  const ShareCardPage({super.key, required this.task});

  final CompressTask task;

  @override
  State<ShareCardPage> createState() => _ShareCardPageState();
}

class _ShareCardPageState extends State<ShareCardPage> {
  final _boundary = GlobalKey();
  bool _busy = false;

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final object = _boundary.currentContext?.findRenderObject();
      if (object is! RenderRepaintBoundary) return;
      final image = await object.toImage(pixelRatio: 2.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final dir = await _shareDir();
      final file = File(
        path.join(
          dir.path,
          'halfsizeX-share-${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(data.buffer.asUint8List());
      if (Platform.isAndroid) {
        await AndroidBridge.shareFile(file.path, 'image/png');
      } else {
        await _openOutput(file.path);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Platform.isAndroid
                ? TaskText.t(context, '已生成分享图', 'Share card ready')
                : TaskText.t(context, '分享图已保存', 'Share card saved'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Directory> _shareDir() async {
    if (Platform.isAndroid) return getTemporaryDirectory();
    final output = widget.task.outputPath;
    if (output != null && !output.startsWith('content://')) {
      final dir = Directory(path.dirname(output));
      if (await dir.exists()) return dir;
    }
    final downloads = await getDownloadsDirectory();
    if (downloads != null) return downloads;
    return getTemporaryDirectory();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final task = widget.task;
    final result = task.result;
    return Scaffold(
      appBar: AppBar(
        title: Text(TaskText.t(context, '分享图', 'Share card')),
        backgroundColor: p.bg,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: RepaintBoundary(
                key: _boundary,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: p.panel,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: p.line),
                    gradient: LinearGradient(
                      colors: [
                        p.accent.withValues(alpha: 0.12),
                        p.panel,
                        p.panel,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Brand(),
                      const SizedBox(height: 26),
                      Text(
                        ratio(
                          task.inputBytes,
                          result?.outputBytes,
                        ).replaceAll('x', '×'),
                        style: TextStyle(
                          fontSize: 58,
                          height: 0.95,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -3,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        TaskText.t(
                          context,
                          '更小，但还能看',
                          'Smaller, still watchable',
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.accent,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        TaskText.t(
                          context,
                          '${bytes(task.inputBytes)} → ${bytes(result?.outputBytes)}',
                          '${bytes(task.inputBytes)} → ${bytes(result?.outputBytes)}',
                        ),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: p.dim),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _ShareStat(
                            label: 'VMAF',
                            value:
                                task.quality?.vmaf?.toStringAsFixed(1) ?? '—',
                          ),
                          const SizedBox(width: 8),
                          _ShareStat(
                            label: 'SSIM',
                            value:
                                task.quality?.ssim?.toStringAsFixed(3) ?? '—',
                          ),
                          const SizedBox(width: 8),
                          _ShareStat(
                            label: TaskText.t(context, '耗时', 'Time'),
                            value: duration((result?.elapsedMs ?? 0) / 1000),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        TaskText.t(
                          context,
                          '${task.plan?.width ?? '-'}×${task.plan?.height ?? '-'} · ${task.options.codec == 'h265' ? 'H.265' : 'H.264'}',
                          '${task.plan?.width ?? '-'}×${task.plan?.height ?? '-'} · ${task.options.codec == 'h265' ? 'H.265' : 'H.264'}',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.muted,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        TaskText.t(
                          context,
                          '本地压缩 · 文件没有上传',
                          'Compressed locally · nothing uploaded',
                        ),
                        style: TextStyle(fontSize: 11, color: p.dim),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.ios_share, size: 17),
            label: Text(
              _busy
                  ? TaskText.t(context, '生成中…', 'Generating…')
                  : (Platform.isAndroid
                        ? TaskText.t(context, '分享图片', 'Share image')
                        : TaskText.t(context, '保存图片', 'Save image')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareStat extends StatelessWidget {
  const _ShareStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: p.panel2,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 9.5, color: p.dim)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusLabel(BuildContext context, TaskStatus status) {
  switch (status) {
    case TaskStatus.queued:
      return TaskText.t(context, '排队中', 'Queued');
    case TaskStatus.running:
      return TaskText.t(context, '压缩中', 'Running');
    case TaskStatus.measuring:
      return TaskText.t(context, '检测画质', 'Checking');
    case TaskStatus.done:
      return TaskText.t(context, '完成', 'Done');
    case TaskStatus.failed:
      return TaskText.t(context, '失败', 'Failed');
    case TaskStatus.cancelled:
      return TaskText.t(context, '已取消', 'Cancelled');
  }
}

Color _statusColor(AppPalette p, TaskStatus status) {
  switch (status) {
    case TaskStatus.done:
      return p.accent;
    case TaskStatus.failed:
      return p.bad;
    case TaskStatus.cancelled:
      return p.dim;
    case TaskStatus.queued:
      return p.muted;
    case TaskStatus.running:
    case TaskStatus.measuring:
      return p.warn;
  }
}

Future<void> _openOutput(String? path) async {
  if (path == null) return;
  if (Platform.isAndroid) {
    await AndroidBridge.openFile(path);
    return;
  }
  try {
    if (Platform.isWindows) {
      await Process.run('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  } catch (_) {}
}
