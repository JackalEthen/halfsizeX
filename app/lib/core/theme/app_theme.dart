import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette({
    required this.bg,
    required this.panel,
    required this.panel2,
    required this.line,
    required this.text,
    required this.muted,
    required this.dim,
    required this.accent,
    required this.accent2,
    required this.warn,
    required this.bad,
    required this.fillGradient,
    required this.textGradient,
  });

  final Color bg;
  final Color panel;
  final Color panel2;
  final Color line;
  final Color text;
  final Color muted;
  final Color dim;
  final Color accent;
  final Color accent2;
  final Color warn;
  final Color bad;
  final LinearGradient fillGradient;
  final LinearGradient textGradient;

  static const dark = AppPalette(
    bg: Color(0xFF07080A),
    panel: Color(0xFF0D0F13),
    panel2: Color(0xFF11141A),
    line: Color(0xFF1E222B),
    text: Color(0xFFEEF1F6),
    muted: Color(0xFF9AA2B4),
    dim: Color(0xFF6B7385),
    accent: Color(0xFFB6F36A),
    accent2: Color(0xFF61D9A4),
    warn: Color(0xFFFFB547),
    bad: Color(0xFFFF6B6B),
    fillGradient: LinearGradient(
      colors: [Color(0xFFB6F36A), Color(0xFF61D9A4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textGradient: LinearGradient(
      colors: [Color(0xFFB6F36A), Color(0xFF61D9A4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const light = AppPalette(
    bg: Color(0xFFF7F8F3),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFF0F2EB),
    line: Color(0xFFE0E4D8),
    text: Color(0xFF12160F),
    muted: Color(0xFF5A6254),
    dim: Color(0xFF8B9285),
    accent: Color(0xFF4F8F12),
    accent2: Color(0xFF1F8F6A),
    warn: Color(0xFFFFB547),
    bad: Color(0xFFFF6B6B),
    fillGradient: LinearGradient(
      colors: [Color(0xFFA8E86A), Color(0xFF4FC79A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    textGradient: LinearGradient(
      colors: [Color(0xFF3F7D0E), Color(0xFF128A63)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark, Brightness.dark);
  static ThemeData light() => _build(AppPalette.light, Brightness.light);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final onAccent =
        brightness == Brightness.dark ? const Color(0xFF0A1206) : Colors.white;
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final scheme =
        ColorScheme.fromSeed(seedColor: p.accent, brightness: brightness)
            .copyWith(
      primary: p.accent,
      onPrimary: onAccent,
      secondary: p.accent2,
      onSecondary: onAccent,
      surface: p.panel,
      onSurface: p.text,
      error: p.bad,
      onError: Colors.white,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      dividerColor: p.line,
      textTheme: base.textTheme.apply(bodyColor: p.text, displayColor: p.text),
      cardTheme: CardThemeData(
        color: p.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.panel,
        indicatorColor: p.accent.withValues(alpha: 0.14),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, color: p.muted),
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: p.muted)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: onAccent,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? onAccent : p.dim,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.panel2,
        ),
        trackOutlineColor: WidgetStatePropertyAll(p.line),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.panel2,
        contentTextStyle: TextStyle(color: p.text),
      ),
    );
  }
}
