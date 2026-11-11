import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ffmpeg/ffmpeg_locator.dart';
import '../../core/platform/android_bridge.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _version = '0.1.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadOutputDir();
  }

  Future<void> _loadOutputDir() async {
    if (!Platform.isAndroid || widget.settings.outputDir != null) return;
    final dir = await AndroidBridge.currentOutputDir();
    if (dir != null && mounted) {
      await widget.settings.setOutputDir(dir);
    }
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = info.version);
    } catch (_) {
      // The fallback version is enough when the plugin is unavailable.
    }
  }

  Future<void> _pickOutputDir() async {
    try {
      final dir = Platform.isAndroid
          ? await AndroidBridge.pickOutputDir()
          : await FilePicker.getDirectoryPath();
      if (dir != null && dir.isNotEmpty) {
        await widget.settings.setOutputDir(dir);
      }
    } catch (_) {
      // The platform may not offer a directory picker; keep the default.
    }
  }

  Future<void> _clearOutputDir() async {
    if (Platform.isAndroid) await AndroidBridge.clearOutputDir();
    await widget.settings.setOutputDir(null);
  }

  Future<void> _openUpstream() async {
    try {
      await launchUrl(
        Uri.parse('https://github.com/YKLovePython/halfsize'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final l = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) return _wide(p, l);
        return _narrow(p, l);
      },
    );
  }

  Widget _narrow(AppPalette p, AppLocalizations l) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Text(
              l.settingsTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: p.text,
              ),
            ),
            const SizedBox(height: 18),
            _themeSection(l),
            const SizedBox(height: 14),
            _languageSection(l),
            const SizedBox(height: 14),
            _defaultsSection(l),
            const SizedBox(height: 14),
            _outputSection(l),
            const SizedBox(height: 14),
            _diagnosticsSection(context, l),
            const SizedBox(height: 14),
            _aboutSection(p, l),
          ],
        ),
      ),
    );
  }

  Widget _wide(AppPalette p, AppLocalizations l) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        Row(
          children: [
            Text(
              l.settingsTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: p.text,
              ),
            ),
            const Spacer(),
            Text('v$_version', style: TextStyle(fontSize: 12, color: p.dim)),
          ],
        ),
        const SizedBox(height: 18),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _themeSection(l)),
              const SizedBox(width: 16),
              Expanded(child: _languageSection(l)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _defaultsSection(l)),
              const SizedBox(width: 16),
              Expanded(child: _outputSection(l)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _aboutSection(p, l),
        const SizedBox(height: 16),
        _diagnosticsSection(context, l),
      ],
    );
  }

  Widget _themeSection(AppLocalizations l) {
    return _Section(
      title: l.theme,
      child: _Segmented<ThemePref>(
        value: widget.settings.theme,
        options: [
          (ThemePref.system, l.themeSystem),
          (ThemePref.dark, l.themeDark),
          (ThemePref.light, l.themeLight),
        ],
        onChanged: widget.settings.setTheme,
      ),
    );
  }

  Widget _languageSection(AppLocalizations l) {
    return _Section(
      title: l.language,
      child: _Segmented<LangPref>(
        value: widget.settings.lang,
        options: [
          (LangPref.system, l.languageSystem),
          (LangPref.zh, l.languageZh),
          (LangPref.en, l.languageEn),
        ],
        onChanged: widget.settings.setLang,
      ),
    );
  }

  Widget _defaultsSection(AppLocalizations l) {
    return _Section(
      title: l.defaults,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(text: l.defaultTarget),
          const SizedBox(height: 8),
          _Segmented<int>(
            value: widget.settings.defaultTargetBytes,
            options: const [
              (5000000, '5 MB'),
              (10000000, '10 MB'),
              (16000000, '16 MB'),
              (20000000, '20 MB'),
            ],
            onChanged: widget.settings.setDefaultTargetBytes,
          ),
          const SizedBox(height: 12),
          _Label(text: l.defaultCodec),
          const SizedBox(height: 8),
          _Segmented<String>(
            value: widget.settings.defaultCodec,
            options: const [('h264', 'H.264'), ('h265', 'H.265')],
            onChanged: widget.settings.setDefaultCodec,
          ),
          const SizedBox(height: 12),
          _Label(text: l.defaultPreset),
          const SizedBox(height: 8),
          _Segmented<String>(
            value: widget.settings.defaultPreset,
            options: [
              ('fast', l.presetFast),
              ('medium', l.presetMedium),
              ('slow', l.presetSlow),
            ],
            onChanged: widget.settings.setDefaultPreset,
          ),
          const SizedBox(height: 4),
          _SwitchRow(
            title: l.qualityCheck,
            subtitle: l.qualityCheckHint,
            value: widget.settings.qualityCheck,
            onChanged: widget.settings.setQualityCheck,
          ),
        ],
      ),
    );
  }

  Widget _outputSection(AppLocalizations l) {
    return _Section(
      title: l.outputPath,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PathRow(
            label: l.outputDir,
            value:
                widget.settings.outputDir ??
                (Platform.isAndroid ? l.outputDirDownloads : l.outputDirAuto),
            action: l.change,
            onTap: _pickOutputDir,
          ),
          if (widget.settings.outputDir != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearOutputDir,
                child: Text(l.reset),
              ),
            ),
        ],
      ),
    );
  }

  Widget _diagnosticsSection(BuildContext context, AppLocalizations l) {
    return _Section(
      title: l.diagnostics,
      child: _Tile(
        icon: Icons.terminal,
        title: l.diagnosticsRun,
        subtitle: l.diagnostics,
        onTap: () => _showDiagnostics(context),
      ),
    );
  }

  Widget _aboutSection(AppPalette p, AppLocalizations l) {
    return _Section(
      title: l.about,
      child: Column(
        children: [
          _Row(label: l.version, value: _version),
          Divider(height: 1, color: p.line),
          _Row(
            label: l.upstream,
            value: 'YKLovePython/halfsize',
            onTap: _openUpstream,
          ),
          Divider(height: 1, color: p.line),
          _Row(label: l.license, value: 'MIT'),
        ],
      ),
    );
  }

  Future<void> _showDiagnostics(BuildContext context) {
    final l = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.diagnostics),
        content: SizedBox(
          width: 440,
          child: FutureBuilder<FfmpegInfo>(
            future: FfmpegLocator.resolve(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l.checking),
                  ],
                );
              }
              final info = snapshot.data ?? FfmpegInfo.missing;
              if (!info.ok) return Text(l.ffmpegMissing);
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.ffmpegReady,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _Kv(label: l.path, value: info.ffmpeg),
                    _Kv(label: l.ffmpegSource, value: info.source),
                    if (info.version != null)
                      _Kv(label: l.version, value: info.version!),
                    for (final e in info.encoders.entries)
                      _Kv(
                        label: '${l.encoder} ${e.key}',
                        value: e.value ? '✓' : '—',
                      ),
                    for (final f in info.filters.entries)
                      _Kv(
                        label: '${l.filter} ${f.key}',
                        value: f.value ? '✓' : '—',
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: p.muted,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
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
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.muted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.panel2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          for (final (v, label) in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == value
                        ? p.accent.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: v == value ? p.accent : p.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: p.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: p.dim)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: p.dim),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: p.dim)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PathRow extends StatelessWidget {
  const _PathRow({
    required this.label,
    required this.value,
    required this.action,
    required this.onTap,
  });

  final String label;
  final String value;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.dim),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              action,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: p.muted)),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: onTap == null ? p.text : p.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12, color: p.dim)),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(fontSize: 12, color: p.text),
            ),
          ),
        ],
      ),
    );
  }
}
