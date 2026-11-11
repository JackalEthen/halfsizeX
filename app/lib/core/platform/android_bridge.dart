import 'dart:io';

import 'package:flutter/services.dart';

class AndroidBridge {
  static const _channel = MethodChannel('halfsizex/platform');

  static Future<(String, String)?> ffmpegPaths() async {
    if (!Platform.isAndroid) return null;
    try {
      final map = await _channel.invokeMapMethod<String, String>('ffmpegPaths');
      final ffmpeg = map?['ffmpeg'];
      final ffprobe = map?['ffprobe'];
      if (ffmpeg == null || ffprobe == null) return null;
      return (ffmpeg, ffprobe);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> exportToDownloads(
    String srcPath,
    String displayName,
  ) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('exportToDownloads', {
        'srcPath': srcPath,
        'displayName': displayName,
      });
    } catch (_) {
      return null;
    }
  }

  static Future<String?> pickOutputDir() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('pickOutputDir');
    } catch (_) {
      return null;
    }
  }

  static Future<String?> currentOutputDir() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('outputDir');
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearOutputDir() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('clearOutputDir');
    } catch (_) {}
  }

  static Future<void> openFile(String path) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openFile', {'path': path});
    } catch (_) {}
  }

  static Future<void> startService(String title) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('startCompressService', {
        'title': title,
      });
    } catch (_) {}
  }

  static Future<void> updateProgress(int percent, String text) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('updateCompressProgress', {
        'progress': percent,
        'text': text,
      });
    } catch (_) {}
  }

  static Future<void> stopService() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('stopCompressService');
    } catch (_) {}
  }
}
