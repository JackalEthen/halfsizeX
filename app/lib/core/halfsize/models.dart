class VideoInfo {
  const VideoInfo({
    required this.width,
    required this.height,
    required this.fps,
    this.codec,
    this.profile,
    this.pixFmt,
    this.bitrate = 0,
    this.hdr = false,
    this.colorTransfer,
    this.hdrTransfer,
    this.rotation = 0,
  });

  final String? codec;
  final String? profile;
  final int width;
  final int height;
  final double fps;
  final String? pixFmt;
  final int bitrate;
  final bool hdr;
  final String? colorTransfer;
  final String? hdrTransfer;
  final int rotation;
}

class AudioInfo {
  const AudioInfo({
    required this.bitrate,
    this.codec,
    this.channels = 2,
    this.sampleRate = 48000,
  });

  final String? codec;
  final int channels;
  final int sampleRate;
  final int bitrate;
}

class ProbeInfo {
  const ProbeInfo({
    required this.file,
    required this.duration,
    required this.sizeBytes,
    required this.video,
    this.container = '',
    this.bitrate = 0,
    this.audio,
    this.audioTracks = 0,
    this.subtitleTracks = 0,
  });

  final String file;
  final double duration;
  final int sizeBytes;
  final String container;
  final int bitrate;
  final VideoInfo video;
  final AudioInfo? audio;
  final int audioTracks;
  final int subtitleTracks;
}

class PlanWarning {
  const PlanWarning(this.code, this.message, [this.params = const {}]);

  final String code;
  final String message;
  final Map<String, Object?> params;
}

class EncodePlan {
  const EncodePlan({
    required this.mode,
    required this.codec,
    required this.label,
    required this.encoder,
    required this.preset,
    required this.crf,
    required this.width,
    required this.height,
    required this.fps,
    required this.videoKbps,
    required this.audioKbps,
    required this.audioChannels,
    required this.targetBytes,
    required this.twoPass,
    required this.downscaled,
    required this.scaleFilter,
    required this.fpsFilter,
    required this.toneMap,
    required this.infeasible,
    required this.minimumBytes,
    required this.warnings,
  });

  final String mode;
  final String codec;
  final String label;
  final String encoder;
  final String preset;
  final int? crf;
  final int width;
  final int height;
  final double fps;
  final int? videoKbps;
  final int audioKbps;
  final int audioChannels;
  final int? targetBytes;
  final bool twoPass;
  final bool downscaled;
  final String? scaleFilter;
  final String? fpsFilter;
  final String? toneMap;
  final bool infeasible;
  final int? minimumBytes;
  final List<PlanWarning> warnings;

  EncodePlan copyWith({int? videoKbps, String? encoder}) => EncodePlan(
        mode: mode,
        codec: codec,
        label: label,
        encoder: encoder ?? this.encoder,
        preset: preset,
        crf: crf,
        width: width,
        height: height,
        fps: fps,
        videoKbps: videoKbps ?? this.videoKbps,
        audioKbps: audioKbps,
        audioChannels: audioChannels,
        targetBytes: targetBytes,
        twoPass: twoPass,
        downscaled: downscaled,
        scaleFilter: scaleFilter,
        fpsFilter: fpsFilter,
        toneMap: toneMap,
        infeasible: infeasible,
        minimumBytes: minimumBytes,
        warnings: warnings,
      );
}

class PlanOptions {
  const PlanOptions({
    this.targetBytes,
    this.codec = 'h264',
    this.preset = 'medium',
    this.downscale = true,
    this.audio = true,
    this.crf,
  });

  final int? targetBytes;
  final String codec;
  final String preset;
  final bool downscale;
  final bool audio;
  final int? crf;
}

class TighterPlan {
  const TighterPlan(this.videoKbps);

  final int videoKbps;
}

class EncodeProgress {
  const EncodeProgress({
    required this.seconds,
    required this.total,
    required this.ratio,
    required this.speed,
    required this.pass,
    required this.passes,
  });

  final double seconds;
  final double total;
  final double ratio;
  final String speed;
  final int pass;
  final int passes;
}

class EncodeResult {
  const EncodeResult({required this.outputBytes, required this.elapsedMs});

  final int outputBytes;
  final int elapsedMs;
}

class EncodeToSizeResult {
  const EncodeToSizeResult({
    required this.outputBytes,
    required this.elapsedMs,
    required this.attempts,
    required this.missedTarget,
  });

  final int outputBytes;
  final int elapsedMs;
  final int attempts;
  final bool missedTarget;
}

class HalfsizeException implements Exception {
  const HalfsizeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
