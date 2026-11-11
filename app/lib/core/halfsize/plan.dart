import 'dart:math' as math;

import 'hdr.dart';
import 'human.dart';
import 'models.dart';

class Codec {
  const Codec({
    required this.label,
    required this.encoder,
    required this.bpp,
    required this.twoPass,
  });

  final String label;
  final String encoder;
  final double bpp;
  final bool twoPass;
}

const codecs = <String, Codec>{
  'h264': Codec(label: 'H.264', encoder: 'libx264', bpp: 0.072, twoPass: true),
  'h265': Codec(label: 'H.265', encoder: 'libx265', bpp: 0.045, twoPass: true),
};

const _tiers = <(int, int)>[
  (3840, 2160),
  (2560, 1440),
  (1920, 1080),
  (1600, 900),
  (1280, 720),
  (960, 540),
  (854, 480),
  (640, 360),
  (426, 240),
];

int _even(num n) => math.max(2, (n / 2).round() * 2);

({int w, int h}) _fitTier(VideoInfo video, (int, int) tier) {
  final portrait = video.height > video.width;
  final tw = portrait ? tier.$2 : tier.$1;
  final th = portrait ? tier.$1 : tier.$2;
  final scale = math.min(1.0, math.min(tw / video.width, th / video.height));
  return (w: _even(video.width * scale), h: _even(video.height * scale));
}

List<({int w, int h})> _candidateSizes(ProbeInfo info) {
  final out = <({int w, int h})>[];
  final seen = <String>{};
  void push(int w, int h) {
    final key = '${w}x$h';
    if (seen.add(key)) out.add((w: w, h: h));
  }

  push(_even(info.video.width), _even(info.video.height));
  for (final tier in _tiers) {
    final size = _fitTier(info.video, tier);
    push(size.w, size.h);
  }
  return out;
}

void _warn(
  List<PlanWarning> list,
  String code,
  String message, [
  Map<String, Object?> params = const {},
]) {
  list.add(PlanWarning(code, message, params));
}

int _audioBitrate(ProbeInfo info, double totalKbps) {
  final audio = info.audio;
  if (audio == null) return 0;
  final preferred =
      totalKbps > 2500 ? 160 : (totalKbps > 800 ? 128 : (totalKbps > 300 ? 96 : 64));
  final source = audio.bitrate > 0 ? audio.bitrate / 1000 : preferred.toDouble();
  final share = totalKbps * 0.18;
  final value = math.min(preferred.toDouble(), math.min(source, share));
  return math.max(32, (value / 8).round() * 8);
}

double _capFps(double? fps) {
  if (fps == null || !fps.isFinite || fps <= 0) return 30;
  return math.min(60.0, (fps * 1000).round() / 1000);
}

String _numText(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

EncodePlan planEncode(ProbeInfo info, PlanOptions options) {
  final codec = codecs[options.codec];
  if (codec == null) {
    throw ArgumentError('Unknown codec "${options.codec}". Use h264 or h265.');
  }
  final preset = options.preset;
  final allowDownscale = options.downscale;
  final warnings = <PlanWarning>[];

  if (!info.duration.isFinite || info.duration <= 0) {
    throw ArgumentError('Could not read the duration of this file.');
  }

  final fps = _capFps(info.video.fps);

  if (info.audioTracks > 1) {
    _warn(
      warnings,
      'audio-tracks',
      'This file has ${info.audioTracks} audio tracks; only the first one is kept.',
      {'count': info.audioTracks},
    );
  }
  if (info.subtitleTracks > 0) {
    _warn(
      warnings,
      'subtitles',
      info.subtitleTracks == 1
          ? 'The subtitle track is not carried over to the MP4.'
          : '${info.subtitleTracks} subtitle tracks are not carried over to the MP4.',
      {'count': info.subtitleTracks},
    );
  }
  if ((info.audio?.channels ?? 0) > 2) {
    _warn(
      warnings,
      'downmix',
      'Audio has ${info.audio!.channels} channels and is downmixed to stereo.',
      {'channels': info.audio!.channels},
    );
  }
  if (info.video.fps > 60.001) {
    _warn(
      warnings,
      'fps-capped',
      'Frame rate is capped at 60 fps (the source is ${info.video.fps.round()} fps).',
      {'from': info.video.fps, 'to': 60},
    );
  }

  final audioChannels = info.audio?.channels == 1 ? 1 : 2;

  final toneMap = info.video.hdr
      ? toneMapFilter(info.video.hdrTransfer ?? info.video.colorTransfer)
      : null;
  if (toneMap != null) {
    final kind = info.video.hdrTransfer ?? hdrKind(info.video.colorTransfer);
    _warn(
      warnings,
      'hdr',
      'HDR source (${kind == 'pq' ? 'PQ' : (kind == 'hlg' ? 'HLG' : 'HDR')}) '
      'will be converted to SDR (BT.709) so it does not look washed out.',
      {'transfer': info.video.hdrTransfer},
    );
  }

  if (options.crf != null) {
    return EncodePlan(
      mode: 'quality',
      codec: options.codec,
      label: codec.label,
      encoder: codec.encoder,
      preset: preset,
      crf: options.crf,
      width: info.video.width,
      height: info.video.height,
      fps: fps,
      videoKbps: null,
      audioKbps: options.audio ? _audioBitrate(info, 2000) : 0,
      audioChannels: audioChannels,
      targetBytes: null,
      twoPass: false,
      downscaled: false,
      scaleFilter: null,
      fpsFilter: null,
      toneMap: toneMap,
      infeasible: false,
      minimumBytes: null,
      warnings: warnings,
    );
  }

  final targetBytes = options.targetBytes;
  if (targetBytes == null || targetBytes <= 0) {
    throw ArgumentError('A target size is required.');
  }

  final totalKbps = ((targetBytes * 8) / info.duration / 1000) * 0.97;
  final audioKbps = options.audio ? _audioBitrate(info, totalKbps) : 0;
  final videoKbps = math.max(40, (totalKbps - audioKbps).round());

  final sizes = _candidateSizes(info);
  final original = sizes.first;
  var chosen = sizes.last;
  for (final size in sizes) {
    final requiredKbps = (size.w * size.h * fps * codec.bpp) / 1000;
    if (requiredKbps <= videoKbps) {
      chosen = size;
      break;
    }
  }

  final requiredAtChosen = (chosen.w * chosen.h * fps * codec.bpp) / 1000;
  if (chosen.w == original.w &&
      chosen.h == original.h &&
      requiredAtChosen > videoKbps) {
    _warn(
      warnings,
      'aggressive',
      'The target is aggressive for this resolution; keeping full size will look soft.',
    );
  }
  if (!allowDownscale &&
      (chosen.w != original.w || chosen.h != original.h)) {
    chosen = original;
    _warn(
      warnings,
      'no-downscale',
      'Downscaling is disabled, so the target may be missed. Quality will suffer.',
    );
  }
  if (videoKbps < 120) {
    _warn(
      warnings,
      'low-bitrate',
      'Very low bitrate. Consider a larger target or H.265.',
    );
  }

  final minimumBytes =
      ((videoKbps + audioKbps) * 1000 * info.duration / 8).round();
  final infeasible = minimumBytes > targetBytes;
  if (infeasible) {
    _warn(
      warnings,
      'infeasible',
      '${bytes(targetBytes)} is below the ${bytes(minimumBytes)} this '
      '${duration(info.duration)} video needs at the lowest bitrate. '
      'Use a larger target, trim it, or --force.',
      {'minimumBytes': minimumBytes, 'targetBytes': targetBytes},
    );
  }

  final downscaled = chosen.w != original.w || chosen.h != original.h;
  final fpsChanged = fps < info.video.fps - 0.01;

  return EncodePlan(
    mode: 'size',
    codec: options.codec,
    label: codec.label,
    encoder: codec.encoder,
    preset: preset,
    crf: null,
    width: chosen.w,
    height: chosen.h,
    fps: fps,
    videoKbps: videoKbps,
    audioKbps: audioKbps,
    audioChannels: audioChannels,
    targetBytes: targetBytes,
    twoPass: codec.twoPass,
    downscaled: downscaled,
    scaleFilter:
        downscaled ? 'scale=${chosen.w}:${chosen.h}:flags=lanczos' : null,
    fpsFilter: fpsChanged ? 'fps=${_numText(fps)}' : null,
    toneMap: toneMap,
    infeasible: infeasible,
    minimumBytes: infeasible ? minimumBytes : null,
    warnings: warnings,
  );
}

int? estimateBytes(ProbeInfo info, EncodePlan plan) {
  if (plan.mode != 'size') return null;
  final kbps = (plan.videoKbps ?? 0) + plan.audioKbps;
  return (kbps * 1000 * info.duration / 8).round();
}

TighterPlan? tighterPlan(
  EncodePlan? plan,
  ProbeInfo? info,
  int? actualBytes,
  int? targetBytes,
) {
  if (plan == null ||
      plan.mode != 'size' ||
      plan.videoKbps == null ||
      plan.videoKbps == 0) {
    return null;
  }
  if (info == null ||
      info.duration <= 0 ||
      targetBytes == null ||
      targetBytes == 0 ||
      actualBytes == null ||
      actualBytes == 0) {
    return null;
  }
  if (actualBytes <= targetBytes) return null;
  final wanted =
      (plan.videoKbps! * ((targetBytes * 0.98) / actualBytes)).floor();
  final next = math.max(40, math.min(plan.videoKbps! - 1, wanted));
  if (next >= plan.videoKbps!) return null;
  return TighterPlan(next);
}
