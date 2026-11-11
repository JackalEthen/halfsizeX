import 'dart:convert';
import 'dart:io';

import '../ffmpeg/ffmpeg_locator.dart';
import 'hdr.dart';
import 'models.dart';

const _notVideo = {'tty', 'image2', 'lavfi'};

ProbeInfo parseProbeJson(String source, {required String file}) {
  final json = jsonDecode(source) as Map<String, dynamic>;
  final format =
      (json['format'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
  final streams = ((json['streams'] as List?) ?? const [])
      .whereType<Map<String, dynamic>>()
      .toList();

  final container =
      (format['format_name']?.toString() ?? '').split(',').first;
  if (_notVideo.contains(container)) {
    throw const FormatException(
      'This file is not a video. Pick an MP4, MOV, MKV, AVI, or WebM file.',
    );
  }

  Map<String, dynamic>? video;
  for (final stream in streams) {
    if (stream['codec_type'] == 'video' && _attachedPic(stream) != 1) {
      video = stream;
      break;
    }
  }
  if (video == null) {
    throw const FormatException('No video stream found in this file.');
  }

  Map<String, dynamic>? audio;
  for (final stream in streams) {
    if (stream['codec_type'] == 'audio') {
      audio = stream;
      break;
    }
  }

  final duration = _firstNonZero(
    _asDouble(format['duration']),
    _asDouble(video['duration']),
  );
  final sizeBytes = _asInt(format['size']) ?? 0;

  final rotation = _rotation(video);
  final rawWidth = _asInt(video['width']) ?? 0;
  final rawHeight = _asInt(video['height']) ?? 0;
  final width = rotation % 180 == 0 ? rawWidth : rawHeight;
  final height = rotation % 180 == 0 ? rawHeight : rawWidth;

  final colorTransfer = video['color_transfer']?.toString();
  final hdrTransfer = hdrKind(colorTransfer);

  final avg = _parseFps(video['avg_frame_rate']);
  final r = _parseFps(video['r_frame_rate']);
  final fps = (avg != null && avg != 0)
      ? avg
      : ((r != null && r != 0) ? r : 30.0);

  return ProbeInfo(
    file: file,
    duration: duration,
    sizeBytes: sizeBytes,
    container: container,
    bitrate: _asInt(format['bit_rate']) ?? 0,
    video: VideoInfo(
      codec: video['codec_name']?.toString(),
      profile: video['profile']?.toString(),
      width: width,
      height: height,
      fps: fps,
      pixFmt: video['pix_fmt']?.toString(),
      bitrate: _asInt(video['bit_rate']) ?? 0,
      hdr: hdrTransfer != null,
      colorTransfer: colorTransfer,
      hdrTransfer: hdrTransfer,
      rotation: rotation,
    ),
    audio: audio == null
        ? null
        : AudioInfo(
            codec: audio['codec_name']?.toString(),
            channels: _asInt(audio['channels']) ?? 0,
            sampleRate: _asInt(audio['sample_rate']) ?? 0,
            bitrate: _asInt(audio['bit_rate']) ?? 0,
          ),
    audioTracks:
        streams.where((s) => s['codec_type'] == 'audio').length,
    subtitleTracks:
        streams.where((s) => s['codec_type'] == 'subtitle').length,
  );
}

Future<ProbeInfo> probeFile(
  String file, {
  required FfmpegInfo bins,
}) async {
  if (!bins.ok) {
    throw const HalfsizeException('HALFSIZE_FFMPEG_MISSING', 'FFmpeg was not found.');
  }
  final result = await Process.run(bins.ffprobe, [
    '-v',
    'error',
    '-print_format',
    'json',
    '-show_format',
    '-show_streams',
    file,
  ]);
  if (result.exitCode != 0) {
    final debug = Platform.environment['HALFSIZE_DEBUG'];
    final detail =
        (debug != null && debug.isNotEmpty) ? '\n${result.stderr}' : '';
    throw FormatException('FFmpeg could not read this file as a video.$detail');
  }
  return parseProbeJson(result.stdout as String, file: file);
}

int _attachedPic(Map<String, dynamic> stream) {
  final disposition = stream['disposition'];
  if (disposition is Map) return _asInt(disposition['attached_pic']) ?? 0;
  return 0;
}

int _rotation(Map<String, dynamic> video) {
  final side = video['side_data_list'];
  if (side is List) {
    for (final item in side) {
      if (item is Map && item['rotation'] != null) {
        return (_asInt(item['rotation']) ?? 0).abs() % 360;
      }
    }
  }
  final tags = video['tags'];
  if (tags is Map && tags['rotate'] != null) {
    return (_asInt(tags['rotate']) ?? 0).abs() % 360;
  }
  return 0;
}

double? _parseFps(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty || text == '0/0') return 0;
  final parts = text.split('/');
  final a = double.tryParse(parts.first);
  if (a == null) return 0;
  if (parts.length < 2) return a;
  final b = double.tryParse(parts[1]);
  if (b == null || b == 0) return a;
  return a / b;
}

double _firstNonZero(double? a, double? b) {
  if (a != null && a != 0) return a;
  return b ?? 0;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
