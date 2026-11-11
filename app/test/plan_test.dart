import 'package:flutter_test/flutter_test.dart';
import 'package:halfsizex/core/halfsize/models.dart';
import 'package:halfsizex/core/halfsize/plan.dart';

ProbeInfo info({
  double duration = 60,
  int sizeBytes = 100000000,
  AudioInfo? audio = const AudioInfo(bitrate: 128000),
  int audioTracks = 0,
  int subtitleTracks = 0,
  VideoInfo? video,
}) {
  return ProbeInfo(
    file: 'in.mp4',
    duration: duration,
    sizeBytes: sizeBytes,
    container: 'mov',
    video: video ?? const VideoInfo(width: 1920, height: 1080, fps: 30),
    audio: audio,
    audioTracks: audioTracks,
    subtitleTracks: subtitleTracks,
  );
}

int target(int mb) => mb * 1000000;

void main() {
  test('a 25 MB target on a 100 MB clip downscales instead of over-compressing', () {
    final plan = planEncode(info(), const PlanOptions(targetBytes: 25000000));
    expect(plan.mode, 'size');
    expect(plan.codec, 'h264');
    expect(plan.twoPass, true);
    expect(plan.width, 1280);
    expect(plan.height, 720);
    expect(plan.downscaled, true);
    expect(plan.scaleFilter, 'scale=1280:720:flags=lanczos');
    expect(plan.videoKbps! > 3000, true);
    expect(plan.audioKbps, 128);
  });

  test('H.265 keeps more resolution at the same target', () {
    final h264 = planEncode(info(), const PlanOptions(targetBytes: 25000000));
    final h265 = planEncode(
      info(),
      const PlanOptions(targetBytes: 25000000, codec: 'h265'),
    );
    expect(h265.label, 'H.265');
    expect(h265.width > h264.width, true);
    expect(h265.width, 1920);
    expect(h265.height, 1080);
  });

  test('a generous target keeps the original resolution', () {
    final plan = planEncode(info(), PlanOptions(targetBytes: target(200)));
    expect(plan.width, 1920);
    expect(plan.height, 1080);
    expect(plan.downscaled, false);
    expect(plan.scaleFilter, null);
    expect(plan.warnings, isEmpty);
  });

  test('a tiny target is allowed but warned about', () {
    final plan = planEncode(
      info(duration: 600),
      PlanOptions(targetBytes: target(5)),
    );
    expect(plan.width <= 640, true);
    expect(plan.warnings.any((w) => w.code == 'low-bitrate'), true);
  });

  test('--no-downscale is respected and explains the cost', () {
    final plan = planEncode(
      info(),
      PlanOptions(targetBytes: target(5), downscale: false),
    );
    expect(plan.width, 1920);
    expect(plan.height, 1080);
    expect(plan.warnings.any((w) => w.code == 'no-downscale'), true);
  });

  test('CRF mode never invents a target or a second pass', () {
    final plan = planEncode(info(), const PlanOptions(crf: 23));
    expect(plan.mode, 'quality');
    expect(plan.crf, 23);
    expect(plan.twoPass, false);
    expect(plan.videoKbps, null);
    expect(plan.width, 1920);
    expect(plan.height, 1080);
  });

  test('portrait video is downscaled on the correct axis', () {
    final plan = planEncode(
      info(video: const VideoInfo(width: 1080, height: 1920, fps: 30)),
      PlanOptions(targetBytes: target(25)),
    );
    expect(plan.height > plan.width, true);
    expect(plan.width, 720);
    expect(plan.height, 1280);
  });

  test('fps is capped at 60 and never floored up', () {
    final fast = planEncode(
      info(video: const VideoInfo(width: 1920, height: 1080, fps: 120)),
      PlanOptions(targetBytes: target(200)),
    );
    expect(fast.fps, 60);
    expect(fast.warnings.any((w) => w.code == 'fps-capped'), true);

    final slow = planEncode(
      info(video: const VideoInfo(width: 1920, height: 1080, fps: 5)),
      PlanOptions(targetBytes: target(200)),
    );
    expect(slow.fps, 5);
    expect(slow.fpsFilter, null);
  });

  test('dropped audio, subtitle, and surround tracks are reported, not hidden', () {
    final plan = planEncode(
      info(
        audioTracks: 3,
        subtitleTracks: 2,
        audio: const AudioInfo(bitrate: 384000, channels: 6),
      ),
      PlanOptions(targetBytes: target(25)),
    );
    final codes = plan.warnings.map((w) => w.code).toList();
    expect(codes.contains('audio-tracks'), true);
    expect(codes.contains('subtitles'), true);
    expect(codes.contains('downmix'), true);
    expect(
      plan.warnings.firstWhere((w) => w.code == 'audio-tracks').params['count'],
      3,
    );
  });

  test('a plain stereo file with one audio track has no track warnings', () {
    final plan = planEncode(
      info(audioTracks: 1),
      PlanOptions(targetBytes: target(25)),
    );
    expect(plan.warnings.any((w) => w.code == 'audio-tracks'), false);
    expect(plan.warnings.any((w) => w.code == 'subtitles'), false);
  });

  test('odd source sizes still produce even output', () {
    final plan = planEncode(
      info(video: const VideoInfo(width: 1919, height: 1079, fps: 30)),
      PlanOptions(targetBytes: target(200)),
    );
    expect(plan.width % 2, 0);
    expect(plan.height % 2, 0);
  });

  test('silent video spends the whole budget on pixels', () {
    final plan = planEncode(
      info(audio: null),
      PlanOptions(targetBytes: target(25)),
    );
    expect(plan.audioKbps, 0);
    expect(plan.videoKbps! > 3000, true);
  });

  test('--no-audio drops the track and gives the bits to video', () {
    final withAudio = planEncode(info(), PlanOptions(targetBytes: target(25)));
    final muted = planEncode(
      info(),
      PlanOptions(targetBytes: target(25), audio: false),
    );
    expect(muted.audioKbps, 0);
    expect(muted.videoKbps! > withAudio.videoKbps!, true);
  });

  test('mono audio stays mono instead of being upmixed', () {
    final mono = planEncode(
      info(audio: const AudioInfo(bitrate: 96000, channels: 1)),
      PlanOptions(targetBytes: target(25)),
    );
    expect(mono.audioChannels, 1);

    final stereo = planEncode(
      info(audio: const AudioInfo(bitrate: 128000, channels: 2)),
      PlanOptions(targetBytes: target(25)),
    );
    expect(stereo.audioChannels, 2);
  });

  test('invalid input fails loudly', () {
    expect(
      () => planEncode(info(), const PlanOptions()),
      throwsA(
        predicate((e) => '$e'.contains('target size is required')),
      ),
    );
    expect(
      () => planEncode(
        info(duration: 0),
        PlanOptions(targetBytes: target(25)),
      ),
      throwsA(predicate((e) => '$e'.contains('duration'))),
    );
    expect(
      () => planEncode(
        info(),
        PlanOptions(targetBytes: target(25), codec: 'av1'),
      ),
      throwsA(predicate((e) => '$e'.contains('Unknown codec'))),
    );
  });

  test('estimate lands just under the target', () {
    final i = info();
    final plan = planEncode(i, PlanOptions(targetBytes: target(25)));
    final estimated = estimateBytes(i, plan)!;
    expect(estimated < target(25), true);
    expect(estimated > target(25) * 0.95, true);
  });

  test('HDR sources get a tone map and a reassuring warning, not a dead end', () {
    final plan = planEncode(
      info(
        video: const VideoInfo(
          width: 1920,
          height: 1080,
          fps: 30,
          hdr: true,
          hdrTransfer: 'hlg',
          colorTransfer: 'arib-std-b67',
        ),
      ),
      PlanOptions(targetBytes: target(25)),
    );
    expect(plan.toneMap, contains('tonemap=hable:desat=0'));
    expect(plan.toneMap, contains('setparams=color_trc=arib-std-b67'));
    expect(plan.toneMap, contains('npl=100'));
    final warning = plan.warnings.firstWhere((w) => w.code == 'hdr');
    expect(warning.message, contains('SDR'));
    expect(warning.message.contains('not implemented'), false);
  });

  test('PQ sources use the HDR10 nominal peak instead of the HLG one', () {
    final plan = planEncode(
      info(
        video: const VideoInfo(
          width: 1920,
          height: 1080,
          fps: 30,
          hdr: true,
          hdrTransfer: 'pq',
          colorTransfer: 'smpte2084',
        ),
      ),
      PlanOptions(targetBytes: target(25)),
    );
    expect(plan.toneMap, contains('npl=1000'));
  });

  test('a target below the bitrate floor is marked impossible before encoding', () {
    final i = info(duration: 60);
    final plan = planEncode(i, const PlanOptions(targetBytes: 100000));
    expect(plan.infeasible, true);
    expect(plan.minimumBytes! >= 500000, true);
    final warning = plan.warnings.firstWhere((w) => w.code == 'infeasible');
    expect(warning.params['minimumBytes'], plan.minimumBytes);

    final hour = planEncode(
      info(duration: 3600),
      PlanOptions(targetBytes: target(20)),
    );
    expect(hour.infeasible, true);
    expect(hour.minimumBytes! > target(30), true);
  });

  test('a normal target is not marked impossible', () {
    final plan = planEncode(info(), PlanOptions(targetBytes: target(25)));
    expect(plan.infeasible, false);
    expect(plan.minimumBytes, null);
  });

  test('an overshoot produces a tighter bitrate, but never below the floor', () {
    final i = info();
    final plan = planEncode(i, PlanOptions(targetBytes: target(25)));
    final tighter = tighterPlan(plan, i, target(26), target(25));
    expect(tighter, isNotNull);
    expect(tighter!.videoKbps < plan.videoKbps!, true);
    expect(tighter.videoKbps >= 40, true);

    final floor = plan.copyWith(videoKbps: 40);
    expect(tighterPlan(floor, i, 25500000, 25000000), null);
    expect(tighterPlan(plan, i, target(24), target(25)), null);
  });
}
