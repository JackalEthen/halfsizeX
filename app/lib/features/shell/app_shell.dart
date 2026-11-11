import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/brand.dart';
import '../../l10n/app_localizations.dart';
import '../compress/compress_page.dart';
import '../settings/settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) return _wide(context);
        return _narrow(context);
      },
    );
  }

  Widget _narrow(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: [
            CompressPage(compact: true, settings: widget.settings),
            SettingsPage(settings: widget.settings),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.compress_outlined),
            selectedIcon: const Icon(Icons.compress),
            label: l.tabCompress,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.tabSettings,
          ),
        ],
      ),
    );
  }

  Widget _wide(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(index: _index, onIndex: (i) => setState(() => _index = i)),
            Expanded(
              child: _index == 0
                  ? CompressPage(compact: false, settings: widget.settings)
                  : SettingsPage(settings: widget.settings),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.onIndex});

  final int index;
  final ValueChanged<int> onIndex;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      child: Row(
        children: [
          const Brand(),
          const Spacer(),
          _NavPills(index: index, onIndex: onIndex),
        ],
      ),
    );
  }
}

class _NavPills extends StatelessWidget {
  const _NavPills({required this.index, required this.onIndex});

  final int index;
  final ValueChanged<int> onIndex;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final l = AppLocalizations.of(context);
    final items = [l.tabCompress, l.tabSettings];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.panel2,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            GestureDetector(
              onTap: () => onIndex(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: i == index
                      ? p.accent.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  items[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: i == index ? p.accent : p.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
