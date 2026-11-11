import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as path;

import '../../core/halfsize/human.dart';
import '../../core/halfsize/models.dart';
import '../../core/halfsize/plan.dart';
import '../../core/platform/android_bridge.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../l10n/app_localizations.dart';
import 'compress_controller.dart';

class CompressPage extends StatefulWidget {
  const CompressPage({super.key, required this.compact, this.settings});

  final bool compact;
  final AppSettings? settings;

  @override
  State<CompressPage> createState() => _CompressPageState();
}

class _CompressPageState extends State<CompressPage> {
  late final CompressController _c;
  bool _showOriginal = false;
  Player? _player;
  VideoController? _videoController;
  String? _videoPath;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    _c = CompressController(settings: widget.settings);
    _c.addListener(_syncPlayer);
  }

  @override
  void dispose() {
    _c.removeListener(_syncPlayer);
    _player?.dispose();
    _c.dispose();
    super.dispose();
  }

  void _syncPlayer() {
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;
    final desired = _c.stage == CompressStage.done && !_showOriginal
        ? _c.outputPath
        : _c.inputPath;
    if (desired == null) {
      if (_videoPath == null) return;
      _videoPath = null;
      _clearPlayer();
      return;
    }
    if (desired == _videoPath) return;
    _videoPath = desired;
    _openPlayer(desired);
  }

  Future<void> _clearPlayer() async {
    final old = _player;
    _player = null;
    _videoController = null;
    _videoReady = false;
    if (mounted) setState(() {});
    await old?.dispose();
  }

  Future<void> _openPlayer(String file) async {
    final old = _player;
    _player = null;
    _videoController = null;
    _videoReady = false;
    if (mounted) setState(() {});
    await old?.dispose();
    final player = Player();
    final controller = VideoController(player);
    _player = player;
    _videoController = controller;
    try {
      await player.open(Media(file), play: false);
    } catch (_) {
      return;
    }
    if (!mounted || _videoPath != file) return;
    setState(() => _videoReady = true);
  }

  @override
  Widget build(BuildContext context) {
    final content = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final p = AppPalette.of(context);
        final l = AppLocalizations.of(context);
        if (_c.stage == CompressStage.idle ||
            _c.stage == CompressStage.probing) {
          return _empty(p, l);
        }
        return widget.compact ? _mobile(p, l) : _desktop(p, l);
      },
    );
    if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return content;
    }
    return DropTarget(
      onDragDone: (detail) {
        if (detail.files.isEmpty) return;
        _c.loadPath(detail.files.first.path);
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
            _DropCard(
              height: 210,
              busy: _c.stage == CompressStage.probing,
              onTap: _c.pick,
            ),
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
                  child: _DropCard(
                    height: null,
                    busy: _c.stage == CompressStage.probing,
                    onTap: _c.pick,
                  ),
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
        _fileCard(p, l),
        if (_c.error != null) ...[const SizedBox(height: 12), _errorCard(p, l)],
        if (_c.stage == CompressStage.ready) ...[
          const SizedBox(height: 14),
          _configCard(p, l),
          const SizedBox(height: 12),
          _warnings(p, l),
        ],
        if (_c.stage == CompressStage.encoding) ...[
          const SizedBox(height: 14),
          _progressCard(p, l),
        ],
        if (_c.stage == CompressStage.measuring) ...[
          const SizedBox(height: 14),
          _measuringCard(p, l),
        ],
        if (_c.stage == CompressStage.done) ...[
          const SizedBox(height: 14),
          _resultCard(p, l),
        ],
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
                if (_c.stage == CompressStage.done) ...[
                  _desktopSegment(p, l),
                  const SizedBox(height: 12),
                ],
                _desktopPreview(p, l),
                const SizedBox(height: 12),
                _desktopFileMeta(p, l),
                if (_c.stage == CompressStage.encoding ||
                    _c.stage == CompressStage.measuring) ...[
                  const SizedBox(height: 12),
                  _desktopPlanCard(p, l),
                ],
                const SizedBox(height: 16),
                _Notice(text: l.localOnly),
              ],
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 420,
            child: ListView(
              children: [
                if (_c.error != null) ...[
                  _errorCard(p, l),
                  const SizedBox(height: 12),
                ],
                if (_c.stage == CompressStage.ready) ...[
                  _configCard(p, l),
                  const SizedBox(height: 12),
                  _warnings(p, l),
                ],
                if (_c.stage == CompressStage.encoding) ...[
                  _progressCard(p, l),
                  const SizedBox(height: 12),
                  _desktopStatusCard(p, l),
                ],
                if (_c.stage == CompressStage.measuring) ...[
                  _measuringCard(p, l),
                  const SizedBox(height: 12),
                  _desktopStatusCard(p, l),
                ],
                if (_c.stage == CompressStage.done) ...[_resultCard(p, l)],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopSegment(AppPalette p, AppLocalizations l) {
    return SizedBox(
      width: 240,
      child: Row(
        children: [
          Expanded(
            child: _SegChip(
              label: l.ffmpegSource,
              selected: _showOriginal,
              onTap: () {
                setState(() => _showOriginal = true);
                _syncPlayer();
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _SegChip(
              label: l.result,
              selected: !_showOriginal,
              onTap: () {
                setState(() => _showOriginal = false);
                _syncPlayer();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _desktopPreview(AppPalette p, AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _videoReady && _videoController != null
            ? Video(
                controller: _videoController!,
                controls: AdaptiveVideoControls,
              )
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openVideo,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.2),
                          radius: 1.1,
                          colors: [
                            p.accent.withValues(alpha: 0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.09),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _desktopFileMeta(AppPalette p, AppLocalizations l) {
    final info = _c.info;
    final result = _c.result;
    final plan = _c.plan;
    final showOutput = _c.stage == CompressStage.done && !_showOriginal;
    final name = showOutput
        ? path.basename(_c.outputPath ?? '')
        : (info == null ? l.analyzing : path.basename(info.file));
    final tags = <String>[
      if (showOutput && result != null) bytes(result.outputBytes),
      if (!showOutput && info != null) bytes(info.sizeBytes),
      if (info != null) duration(info.duration),
      if (showOutput && plan != null)
        '${plan.width}×${plan.height}'
      else if (info != null)
        '${info.video.width}×${info.video.height}',
      if (!showOutput && info != null)
        '${info.video.fps.toStringAsFixed(0)} fps',
      if (showOutput)
        _c.codec == 'h265' ? 'H.265' : 'H.264'
      else if (info?.video.codec != null)
        info!.video.codec!.toUpperCase(),
      if (info?.audio != null) l.keepAudio,
    ];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final tag in tags) _Tag(text: tag)],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(onPressed: _c.pick, child: Text(l.chooseAnother)),
      ],
    );
  }

  Widget _desktopPlanCard(AppPalette p, AppLocalizations l) {
    final plan = _c.plan;
    if (plan == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.result, style: _label(p)),
          const SizedBox(height: 10),
          _kv(
            p,
            l.codec,
            '${_c.codec == 'h265' ? 'H.265' : 'H.264'} · ${_c.preset}',
          ),
          _kv(p, l.resolution, '${plan.width}×${plan.height}'),
          _kv(
            p,
            l.videoBitrate,
            plan.videoKbps == null ? 'auto' : bitrate(plan.videoKbps),
          ),
          _kv(p, l.audioBitrate, bitrate(plan.audioKbps)),
          if (_c.info != null)
            _kv(p, l.estimated, bytes(estimateBytes(_c.info!, plan))),
        ],
      ),
    );
  }

  Widget _desktopStatusCard(AppPalette p, AppLocalizations l) {
    final progress = _c.progress;
    final name = path.basename(_c.outputPath ?? '');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.result, style: _label(p)),
          const SizedBox(height: 10),
          _kv(p, l.passOf, '${progress?.pass ?? 1}/${progress?.passes ?? 2}'),
          if (name.isNotEmpty) _kv(p, l.outputFile, name),
        ],
      ),
    );
  }

  Widget _fileCard(AppPalette p, AppLocalizations l) {
    final info = _c.info;
    final name = _c.inputPath == null ? '' : path.basename(_c.inputPath!);
    final meta = info == null
        ? l.analyzing
        : '${duration(info.duration)} · '
              '${info.video.width}×${info.video.height} · '
              '${bytes(info.sizeBytes)}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: p.panel2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.line),
            ),
            child: Icon(Icons.movie_outlined, size: 20, color: p.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(meta, style: TextStyle(fontSize: 12, color: p.dim)),
              ],
            ),
          ),
          TextButton(onPressed: _c.pick, child: Text(l.chooseAnother)),
        ],
      ),
    );
  }

  Widget _errorCard(AppPalette p, AppLocalizations l) {
    final canRetry = _c.info != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: p.accent2),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _c.error ?? l.error,
              style: TextStyle(fontSize: 12.5, color: p.text),
            ),
          ),
          TextButton(
            onPressed: canRetry ? _c.start : _c.pick,
            child: Text(l.retry),
          ),
        ],
      ),
    );
  }

  Widget _configCard(AppPalette p, AppLocalizations l) {
    final plan = _c.plan;
    const presets = <({String id, String name, int mb})>[
      (id: 'discord', name: 'Discord', mb: 20),
      (id: 'whatsapp', name: 'WhatsApp', mb: 16),
      (id: 'wechat', name: 'WeChat', mb: 20),
      (id: 'gmail', name: 'Gmail', mb: 18),
      (id: 'outlook', name: 'Outlook', mb: 15),
      (id: 'email', name: 'Email', mb: 18),
      (id: 'x', name: 'X', mb: 512),
    ];

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
          Text(l.mode, style: _label(p)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SegChip(
                  label: l.modeSize,
                  selected: _c.crf == null,
                  onTap: () => _c.setTargetBytes(_c.targetBytes),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegChip(
                  label: l.modeCrf,
                  selected: _c.crf != null,
                  onTap: () => _c.setCrf(_c.crf ?? 23),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_c.crf == null) ...[
            Text(
              l.targetSize,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: p.text,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in presets)
                  _Chip(
                    label: '${preset.name} ${preset.mb} MB',
                    selected: _c.platformPreset == preset.id,
                    onTap: () => _c.setPreset(preset.id, preset.mb * 1000000),
                  ),
                _Chip(
                  label: l.custom,
                  selected: _c.platformPreset == null,
                  onTap: () => _pickCustom(context),
                ),
              ],
            ),
          ] else ...[
            Text(
              l.crfHint,
              style: TextStyle(fontSize: 12, color: p.muted, height: 1.4),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final crf in const [18, 20, 23, 26, 28])
                  _Chip(
                    label: 'CRF $crf',
                    selected: _c.crf == crf,
                    onTap: () => _c.setCrf(crf),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Text(l.codec, style: _label(p)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SegChip(
                  label: 'H.264',
                  selected: _c.codec == 'h264',
                  onTap: () => _c.setCodec('h264'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegChip(
                  label: 'H.265',
                  selected: _c.codec == 'h265',
                  onTap: () => _c.setCodec('h265'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ToggleRow(
            label: l.downscale,
            value: _c.downscale,
            onChanged: _c.setDownscale,
          ),
          _ToggleRow(
            label: l.qualityCheck,
            value: _c.qualityCheck,
            onChanged: _c.setQualityCheck,
          ),
          _ToggleRow(
            label: l.keepAudio,
            value: _c.audio,
            onChanged: _c.setAudio,
          ),
          if (plan != null) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: p.line),
            const SizedBox(height: 12),
            _kv(p, l.resolution, '${plan.width}×${plan.height}'),
            _kv(
              p,
              l.videoBitrate,
              plan.videoKbps == null ? 'auto' : bitrate(plan.videoKbps),
            ),
            _kv(p, l.audioBitrate, bitrate(plan.audioKbps)),
            if (plan.mode == 'size')
              _kv(p, l.estimated, bytes(estimateBytes(_c.info!, plan))),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  plan == null ||
                      _c.stage == CompressStage.encoding ||
                      _c.stage == CompressStage.measuring
                  ? null
                  : () => _startPressed(context),
              child: Text(l.start),
            ),
          ),
          if (plan != null && plan.infeasible) ...[
            const SizedBox(height: 10),
            Text(
              plan.minimumBytes == null
                  ? l.targetTooSmall
                  : l.minimumNeeded(bytes(plan.minimumBytes!)),
              style: TextStyle(fontSize: 12, color: p.accent2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _progressCard(AppPalette p, AppLocalizations l) {
    final progress = _c.progress;
    final ratio = (progress?.ratio ?? 0).clamp(0.0, 1.0).toDouble();
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
          Row(
            children: [
              Text(
                l.compressing,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const Spacer(),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: p.panel2,
              color: p.accent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${l.passOf} ${progress?.pass ?? 1}/${progress?.passes ?? 2}',
                style: TextStyle(fontSize: 12, color: p.dim),
              ),
              const Spacer(),
              Text(
                progress?.speed ?? '',
                style: TextStyle(fontSize: 12, color: p.dim),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: _c.cancel, child: Text(l.cancel)),
        ],
      ),
    );
  }

  Widget _measuringCard(AppPalette p, AppLocalizations l) {
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
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l.measuring,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              backgroundColor: p.panel2,
              color: p.accent,
            ),
          ),
        ],
      ),
    );
  }

  String _verdictText(AppLocalizations l, String key) {
    switch (key) {
      case 'indistinguishable':
        return l.qualityIndistinguishable;
      case 'same':
        return l.qualitySame;
      case 'slight':
        return l.qualitySlight;
      case 'visible':
        return l.qualityVisible;
      case 'degraded':
        return l.qualityDegraded;
      default:
        return l.qualityNone;
    }
  }

  Widget _resultCard(AppPalette p, AppLocalizations l) {
    final result = _c.result;
    if (result == null) return const SizedBox.shrink();
    final plan = _c.plan;
    final inputBytes = _c.info?.sizeBytes;
    final ratioText = ratio(
      inputBytes,
      result.outputBytes,
    ).replaceAll('x', '×');
    final resolution = plan == null ? '-' : '${plan.width}×${plan.height}';
    final codec = _c.codec == 'h265' ? 'H.265' : 'H.264';
    final fileName = path.basename(_c.outputPath ?? '');
    final vmaf = _c.quality?.vmaf;
    final ssim = _c.quality?.ssim;

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
          Text(
            ratioText,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
              color: p.text,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: p.muted),
              children: [
                TextSpan(text: '${l.smaller} · '),
                TextSpan(
                  text: bytes(inputBytes),
                  style: TextStyle(color: p.text, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' · '),
                TextSpan(
                  text: bytes(result.outputBytes),
                  style: TextStyle(
                    color: p.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (_c.verdict != null && _c.verdict!.key != 'none') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _verdictText(l, _c.verdict!.key),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                ),
              ),
            ),
          ],
          if (result.missedTarget) ...[
            const SizedBox(height: 6),
            Text(
              l.missedTarget,
              style: TextStyle(fontSize: 12, color: p.accent2),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: 'VMAF', value: vmaf?.toStringAsFixed(1) ?? '—'),
              const SizedBox(width: 8),
              _Stat(label: 'SSIM', value: ssim?.toStringAsFixed(3) ?? '—'),
              const SizedBox(width: 8),
              _Stat(label: l.elapsed, value: duration(result.elapsedMs / 1000)),
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
                _kv(p, l.outputFile, fileName),
                _kv(p, l.resolution, '$resolution · $codec'),
                const SizedBox(height: 6),
                SelectableText(
                  _c.outputPath ?? '',
                  style: TextStyle(fontSize: 11.5, color: p.dim),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _openFolder,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: Text(Platform.isAndroid ? l.openFile : l.openFolder),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _c.reset,
                  child: Text(l.startOver),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _warnings(AppPalette p, AppLocalizations l) {
    final warnings = _c.plan?.warnings ?? const <PlanWarning>[];
    if (warnings.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.warnings,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.muted,
            ),
          ),
          const SizedBox(height: 8),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(Icons.info_outline, size: 14, color: p.accent),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _warningText(l, warning),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: p.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _warningText(AppLocalizations l, PlanWarning warning) {
    switch (warning.code) {
      case 'audio-tracks':
        return l.warningAudioTracks;
      case 'subtitles':
        return l.warningSubtitles;
      case 'downmix':
        return l.warningDownmix;
      case 'fps-capped':
        return l.warningFpsCapped;
      case 'hdr':
        return l.warningHdr;
      case 'aggressive':
        return l.warningAggressive;
      case 'no-downscale':
        return l.warningNoDownscale;
      case 'low-bitrate':
        return l.warningLowBitrate;
      case 'infeasible':
        return l.warningInfeasible;
      default:
        return warning.message;
    }
  }

  Future<void> _startPressed(BuildContext context) async {
    final plan = _c.plan;
    if (plan == null) return;
    final minimum = plan.minimumBytes;
    if (!plan.infeasible || minimum == null) {
      await _c.start();
      return;
    }
    final l = AppLocalizations.of(context);
    final raised = ((minimum / 100000).ceil() * 100000);
    final choice = await showDialog<String>(
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
                  l.targetTooSmall,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.minimumNeeded(bytes(minimum)),
                  style: TextStyle(fontSize: 13, color: p.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                _DialogButton(
                  label: l.raiseTarget(bytes(raised)),
                  primary: true,
                  onTap: () => Navigator.of(context).pop('raise'),
                ),
                const SizedBox(height: 8),
                _DialogButton(
                  label: l.encodeAnyway,
                  onTap: () => Navigator.of(context).pop('force'),
                ),
                const SizedBox(height: 8),
                _DialogButton(
                  label: MaterialLocalizations.of(context).cancelButtonLabel,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted) return;
    if (choice == 'raise') {
      _c.setTargetBytes(raised);
    } else if (choice == 'force') {
      await _c.start(force: true);
    }
  }

  Future<void> _pickCustom(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var input = _c.targetBytes % 1000000 == 0
        ? '${_c.targetBytes ~/ 1000000}'
        : (_c.targetBytes / 1000000).toStringAsFixed(1);
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        final p = AppPalette.of(context);
        final screenWidth = MediaQuery.sizeOf(context).width;
        return Dialog(
          backgroundColor: p.panel,
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenWidth > 600 ? (screenWidth - 380) / 2 : 28,
          ),
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
                    suffixStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: p.muted,
                    ),
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
      _c.setTargetBytes(parseSize(text));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.invalidSize)));
    }
  }

  Future<void> _openVideo() async {
    final file = _c.stage == CompressStage.done && !_showOriginal
        ? _c.outputPath
        : _c.inputPath;
    if (file == null) return;
    if (Platform.isAndroid) {
      await AndroidBridge.openFile(file);
      return;
    }
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [file]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [file]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file]);
      }
    } catch (_) {}
  }

  Future<void> _openFolder() async {
    final output = _c.outputPath;
    if (output == null) return;
    if (Platform.isAndroid) {
      await AndroidBridge.openFile(output);
      return;
    }
    final dir = path.dirname(output);
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', [dir]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [dir]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [dir]);
      }
    } catch (_) {}
  }

  static TextStyle _label(AppPalette p) =>
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.muted);

  static Widget _kv(AppPalette p, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: p.dim)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.text,
            ),
          ),
        ],
      ),
    );
  }
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

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: p.panel2,
        borderRadius: BorderRadius.circular(6),
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
              busy ? l.analyzing : l.pickVideo,
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
                letterSpacing: 0.4,
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
