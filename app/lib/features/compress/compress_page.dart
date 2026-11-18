import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../../core/halfsize/human.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/task_text.dart';
import '../tasks/task_controller.dart';

class CompressPage extends StatefulWidget {
  const CompressPage({
    super.key,
    required this.compact,
    required this.tasks,
    required this.onTasksAdded,
    this.settings,
  });

  final bool compact;
  final TaskController tasks;
  final VoidCallback onTasksAdded;
  final AppSettings? settings;

  @override
  State<CompressPage> createState() => _CompressPageState();
}

class _CompressPageState extends State<CompressPage> {
  final _output = TextEditingController();
  final List<String> _paths = [];

  int _targetBytes = 20000000;
  String _codec = 'h264';
  String _preset = 'medium';
  bool _downscale = true;
  bool _qualityCheck = true;
  bool _audio = true;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _targetBytes = s?.defaultTargetBytes ?? _targetBytes;
    _codec = s?.defaultCodec ?? _codec;
    _preset = s?.defaultPreset ?? _preset;
    _qualityCheck = s?.qualityCheck ?? _qualityCheck;
  }

  @override
  void dispose() {
    _output.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final files = await FilePicker.pickFiles(type: FileType.video);
      if (!mounted) return;
      _addPaths(files.map((file) => file.path).whereType<String>());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TaskText.t(context, '无法打开文件选择器', 'Could not open the picker'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _addPaths(Iterable<String> paths) {
    final added = <String>[];
    for (final item in paths) {
      if (item.isEmpty || _paths.contains(item)) continue;
      _paths.add(item);
      added.add(item);
    }
    if (added.isEmpty) return;
    setState(() {});
  }

  void _removePath(String item) {
    setState(() => _paths.remove(item));
  }

  void _start() {
    if (_paths.isEmpty) return;
    final single = _paths.length == 1;
    widget.tasks.addFiles(
      List.of(_paths),
      TaskOptions(
        targetBytes: _targetBytes,
        codec: _codec,
        preset: _preset,
        downscale: _downscale,
        audio: _audio,
        qualityCheck: _qualityCheck,
        outputName: single ? _output.text.trim() : null,
      ),
    );
    setState(() {
      _paths.clear();
      _output.clear();
    });
    widget.onTasksAdded();
  }

  @override
  Widget build(BuildContext context) {
    final content = _paths.isEmpty
        ? _empty(AppPalette.of(context), AppLocalizations.of(context))
        : (widget.compact
              ? _mobile(AppPalette.of(context), AppLocalizations.of(context))
              : _desktop(AppPalette.of(context), AppLocalizations.of(context)));
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return content;
    }
    return DropTarget(
      onDragDone: (detail) {
        if (detail.files.isEmpty) return;
        _addPaths(detail.files.map((file) => file.path));
      },
      child: content,
    );
  }

  Widget _empty(AppPalette p, AppLocalizations l) {
    if (!widget.compact) return _desktopEmpty(p, l);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Row(
              children: [
                const Brand(),
                const Spacer(),
                _Pill(text: l.localBadge),
              ],
            ),
            const SizedBox(height: 28),
            _GradientTitle(text: l.emptyTitle),
            const SizedBox(height: 10),
            Text(
              l.emptyBody,
              style: TextStyle(color: p.muted, height: 1.5, fontSize: 14),
            ),
            const SizedBox(height: 22),
            _DropCard(busy: _picking, onTap: _pick, height: 210),
            const SizedBox(height: 14),
            _Notice(text: l.localOnly),
          ],
        ),
      ),
    );
  }

  Widget _desktopEmpty(AppPalette p, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GradientTitle(text: l.emptyTitle),
                const SizedBox(height: 10),
                Text(
                  l.emptyBody,
                  style: TextStyle(color: p.muted, height: 1.5, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _DropCard(busy: _picking, onTap: _pick, height: null),
                ),
                const SizedBox(height: 14),
                _Notice(text: l.localOnly),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 400,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.42,
                child: ListView(children: [_configCard(p, l)]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobile(AppPalette p, AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            const Brand(),
            const Spacer(),
            _Pill(text: l.localBadge),
          ],
        ),
        const SizedBox(height: 16),
        _selectedCard(p, l),
        const SizedBox(height: 14),
        _configCard(p, l),
        const SizedBox(height: 12),
        _Notice(text: l.localOnly),
      ],
    );
  }

  Widget _desktop(AppPalette p, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              children: [
                _selectedCard(p, l),
                const SizedBox(height: 14),
                _Notice(text: l.localOnly),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 400,
            child: ListView(children: [_configCard(p, l)]),
          ),
        ],
      ),
    );
  }

  Widget _selectedCard(AppPalette p, AppLocalizations l) {
    final total = _paths.fold<int>(0, (sum, item) => sum + _size(item));
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                TaskText.t(
                  context,
                  '已选择 ${_paths.length} 个视频',
                  '${_paths.length} video${_paths.length == 1 ? '' : 's'} selected',
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const Spacer(),
              Text(
                bytes(total),
                style: TextStyle(fontSize: 12, color: p.dim),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in _paths)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: p.panel2,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: p.line),
                    ),
                    child: Icon(
                      Icons.movie_outlined,
                      size: 17,
                      color: p.accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          path.basename(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: p.text,
                          ),
                        ),
                        Text(
                          bytes(_size(item)),
                          style: TextStyle(fontSize: 11, color: p.dim),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removePath(item),
                    icon: Icon(Icons.close, size: 17, color: p.dim),
                    tooltip: TaskText.t(context, '移除', 'Remove'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          OutlinedButton.icon(
            onPressed: _picking ? null : _pick,
            icon: const Icon(Icons.add, size: 17),
            label: Text(TaskText.t(context, '继续添加', 'Add more')),
          ),
        ],
      ),
    );
  }

  Widget _configCard(AppPalette p, AppLocalizations l) {
    final single = _paths.length == 1;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.targetSize, style: _label(p)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mb in const [20, 16, 5])
                _Chip(
                  label: '$mb MB',
                  selected: _targetBytes == mb * 1000000,
                  onTap: () => setState(() => _targetBytes = mb * 1000000),
                ),
              _Chip(
                label: l.custom,
                selected: !const [20, 16, 5].contains(_targetBytes ~/ 1000000),
                onTap: () => _pickCustom(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(l.codec, style: _label(p)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SegChip(
                  label: 'H.264',
                  selected: _codec == 'h264',
                  onTap: () => setState(() => _codec = 'h264'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegChip(
                  label: 'H.265',
                  selected: _codec == 'h265',
                  onTap: () => setState(() => _codec = 'h265'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(l.preset, style: _label(p)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SegChip(
                  label: l.presetFast,
                  selected: _preset == 'fast',
                  onTap: () => setState(() => _preset = 'fast'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SegChip(
                  label: l.presetMedium,
                  selected: _preset == 'medium',
                  onTap: () => setState(() => _preset = 'medium'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _SegChip(
                  label: l.presetSlow,
                  selected: _preset == 'slow',
                  onTap: () => setState(() => _preset = 'slow'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(l.outputFile, style: _label(p)),
          const SizedBox(height: 8),
          TextField(
            controller: _output,
            enabled: single,
            style: TextStyle(fontSize: 13, color: p.text),
            decoration: InputDecoration(
              hintText: single
                  ? TaskText.t(context, '留空自动命名', 'Auto name if empty')
                  : TaskText.t(
                      context,
                      '批量任务自动按原文件名命名',
                      'Batch tasks use the source name',
                    ),
              hintStyle: TextStyle(fontSize: 12.5, color: p.dim),
              filled: true,
              fillColor: p.panel2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: p.accent),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _ToggleRow(
            label: l.downscale,
            value: _downscale,
            onChanged: (value) => setState(() => _downscale = value),
          ),
          _ToggleRow(
            label: l.qualityCheck,
            value: _qualityCheck,
            onChanged: (value) => setState(() => _qualityCheck = value),
          ),
          _ToggleRow(
            label: l.keepAudio,
            value: _audio,
            onChanged: (value) => setState(() => _audio = value),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _paths.isEmpty ? null : _start,
              child: Text(
                _paths.length > 1
                    ? TaskText.t(
                        context,
                        '开始压缩 · ${_paths.length} 个任务',
                        'Start · ${_paths.length} tasks',
                      )
                    : l.start,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var input = _targetBytes % 1000000 == 0
        ? '${_targetBytes ~/ 1000000}'
        : (_targetBytes / 1000000).toStringAsFixed(1);
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        final p = AppPalette.of(context);
        return Dialog(
          backgroundColor: p.panel,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: p.line),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.customSize,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: input,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                  decoration: InputDecoration(
                    hintText: '25',
                    suffixText: 'MB',
                    filled: true,
                    fillColor: p.panel2,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: p.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: p.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: p.accent),
                    ),
                  ),
                  onChanged: (value) => input = value,
                  onFieldSubmitted: (value) => Navigator.of(context).pop(value),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: MaterialLocalizations.of(
                          context,
                        ).cancelButtonLabel,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogButton(
                        label: MaterialLocalizations.of(context).okButtonLabel,
                        primary: true,
                        onTap: () => Navigator.of(context).pop(input),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    if (text == null || !mounted) return;
    try {
      final value = parseSize(text);
      setState(() => _targetBytes = value);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.invalidSize)));
    }
  }

  static int _size(String file) {
    try {
      return File(file).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  static TextStyle _label(AppPalette p) =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.muted);
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => p.textGradient.createShader(rect),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: p.panel,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: p.muted)),
    );
  }
}

class _DropCard extends StatelessWidget {
  const _DropCard({required this.onTap, required this.busy, this.height});

  final VoidCallback onTap;
  final bool busy;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.line),
          gradient: RadialGradient(
            center: const Alignment(0, -0.8),
            radius: 1.2,
            colors: [p.accent.withValues(alpha: 0.06), p.panel],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: p.panel2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.line),
              ),
              child: busy
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.accent,
                      ),
                    )
                  : Icon(Icons.upload_file, color: p.accent, size: 26),
            ),
            const SizedBox(height: 16),
            Text(
              busy
                  ? l.analyzing
                  : TaskText.t(context, '选择视频（可多选）', 'Choose videos'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(l.pickHint, style: TextStyle(fontSize: 12, color: p.dim)),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.08),
        border: Border.all(color: p.accent.withValues(alpha: 0.22)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: p.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(fontSize: 12.5, color: p.text)),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SizedBox(
      height: 46,
      child: Material(
        color: primary ? p.accent.withValues(alpha: 0.14) : p.panel2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: primary ? p.accent.withValues(alpha: 0.35) : p.line,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primary ? p.accent : p.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.12) : p.panel2,
          border: Border.all(
            color: selected ? p.accent.withValues(alpha: 0.4) : p.line,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? p.accent : p.muted,
          ),
        ),
      ),
    );
  }
}

class _SegChip extends StatelessWidget {
  const _SegChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.12) : p.panel2,
          border: Border.all(
            color: selected ? p.accent.withValues(alpha: 0.4) : p.line,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? p.accent : p.muted,
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(fontSize: 13, color: p.text)),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
