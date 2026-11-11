import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemePref { system, dark, light }

enum LangPref { system, zh, en }

class AppSettings extends ChangeNotifier {
  AppSettings._(
    this._prefs,
    this._theme,
    this._lang,
    this._defaultTargetBytes,
    this._defaultCodec,
    this._defaultPreset,
    this._outputDir,
    this._qualityCheck,
  );

  static const _themeKey = 'theme';
  static const _langKey = 'language';
  static const _targetKey = 'default_target_bytes';
  static const _codecKey = 'default_codec';
  static const _presetKey = 'default_preset';
  static const _outputDirKey = 'output_dir';
  static const _qualityKey = 'quality_check';

  final SharedPreferences _prefs;
  ThemePref _theme;
  LangPref _lang;
  int _defaultTargetBytes;
  String _defaultCodec;
  String _defaultPreset;
  String? _outputDir;
  bool _qualityCheck;

  ThemePref get theme => _theme;
  LangPref get lang => _lang;
  int get defaultTargetBytes => _defaultTargetBytes;
  String get defaultCodec => _defaultCodec;
  String get defaultPreset => _defaultPreset;
  String? get outputDir => _outputDir;
  bool get qualityCheck => _qualityCheck;

  ThemeMode get themeMode => switch (_theme) {
    ThemePref.system => ThemeMode.system,
    ThemePref.dark => ThemeMode.dark,
    ThemePref.light => ThemeMode.light,
  };

  Locale? get locale => switch (_lang) {
    LangPref.system => null,
    LangPref.zh => const Locale('zh'),
    LangPref.en => const Locale('en'),
  };

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings._(
      prefs,
      _parseTheme(prefs.getString(_themeKey)),
      _parseLang(prefs.getString(_langKey)),
      prefs.getInt(_targetKey) ?? 20000000,
      prefs.getString(_codecKey) ?? 'h264',
      prefs.getString(_presetKey) ?? 'medium',
      prefs.getString(_outputDirKey),
      prefs.getBool(_qualityKey) ?? true,
    );
  }

  Future<void> setTheme(ThemePref value) async {
    if (value == _theme) return;
    _theme = value;
    notifyListeners();
    await _prefs.setString(_themeKey, value.name);
  }

  Future<void> setLang(LangPref value) async {
    if (value == _lang) return;
    _lang = value;
    notifyListeners();
    await _prefs.setString(_langKey, value.name);
  }

  Future<void> setDefaultTargetBytes(int value) async {
    if (value == _defaultTargetBytes) return;
    _defaultTargetBytes = value;
    notifyListeners();
    await _prefs.setInt(_targetKey, value);
  }

  Future<void> setDefaultCodec(String value) async {
    if (value == _defaultCodec) return;
    _defaultCodec = value;
    notifyListeners();
    await _prefs.setString(_codecKey, value);
  }

  Future<void> setDefaultPreset(String value) async {
    if (value == _defaultPreset) return;
    _defaultPreset = value;
    notifyListeners();
    await _prefs.setString(_presetKey, value);
  }

  Future<void> setQualityCheck(bool value) async {
    if (value == _qualityCheck) return;
    _qualityCheck = value;
    notifyListeners();
    await _prefs.setBool(_qualityKey, value);
  }

  Future<void> setOutputDir(String? value) async {
    if (value == _outputDir) return;
    _outputDir = value;
    notifyListeners();
    if (value == null || value.isEmpty) {
      await _prefs.remove(_outputDirKey);
    } else {
      await _prefs.setString(_outputDirKey, value);
    }
  }

  static ThemePref _parseTheme(String? raw) => ThemePref.values.firstWhere(
    (v) => v.name == raw,
    orElse: () => ThemePref.system,
  );

  static LangPref _parseLang(String? raw) => LangPref.values.firstWhere(
    (v) => v.name == raw,
    orElse: () => LangPref.system,
  );
}
