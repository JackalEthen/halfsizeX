import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:halfsizex/core/ffmpeg/ffmpeg_locator.dart';
import 'package:halfsizex/core/halfsize/encode.dart';
import 'package:halfsizex/core/halfsize/models.dart';
import 'package:halfsizex/core/halfsize/plan.dart';
import 'package:halfsizex/core/halfsize/probe.dart';
import 'package:halfsizex/core/halfsize/quality.dart';
import 'package:path/path.dart' as p;

late FfmpegInfo bins;
late Directory work;

Future<String> source(
  String name, {
  required int seconds,
  String size = '320x240',
}) async {
  final file = p.join(work.path, name);
  final result = await Process.run(bins.ffmpeg, [
    '-hide_banner',
    '-loglevel',
    'error',
    '-y',
    '-f',
    'lavfi',
    '-i',
    'testsrc2=size=$size:rate=30',
    '-f',
    'lavfi',
    '-i',
    'sine=frequency=440:sample_rate=48000',
    '-t',
    '$seconds',
    '-c:v',
    'libx264',
    '-preset',
    'ultrafast',
    '-b:v',
    '4M',
    '-pix_fmt',
    'yuv420p',
    '-c:a',
    'aac',
    '-b:a',
    '96k',
    file,
  ]);
  if (result.exitCode != 0) {
    throw StateError('fixture failed: ${result.stderr}');
  }
  return file;
}

List<String> partFiles(String dir) => Directory(dir)
    .listSync()
    .map((e) => p.basename(e.path))
    .where((name) => name.contains('.part-'))
    .toList();

void main() {
  setUpAll(() async {
    bins = await FfmpegLocator.resolve();
    work = Directory.systemTemp.createTempSync('halfsize-encode-');
  });

  tearDownAll(() {
    if (work.existsSync()) work.deleteSync(recursive: true);
  });

  test('encodes to the target and leaves no temp files', () async {
    if (Platform.environment['HALFSIZE_E2E'] != '1') return;
    final input = await source('ok.mp4', seconds: 2);
    final info = await probeFile(input, bins: bins);
    final plan = planEncode(info, const PlanOptions(targetBytes: 400000));
    final output = p.join(work.path, 'ok-out.mp4');
    final progress = <EncodeProgress>[];

    final result = await encodeToSize(
      input,
      output,
      plan,
      info,
      bins: bins,
      onProgress: progress.add,
    );

    expect(File(output).existsSync(), true);
    expect(result.outputBytes > 100000, true);
    expect(result.attempts, greaterThanOrEqualTo(1));
    expect(progress, isNotEmpty);
    expect(progress.last.pass, 2);
    expect(progress.last.ratio, greaterThan(0.5));
    expect(partFiles(work.path), isEmpty);
  });

  test(
    'a failed encode leaves neither the output nor a partial file',
    () async {
      if (Platform.environment['HALFSIZE_E2E'] != '1') return;
      final input = await source('fail.mp4', seconds: 2);
      final info = await probeFile(input, bins: bins);
      final plan = planEncode(
        info,
        const PlanOptions(targetBytes: 150000),
      ).copyWith(encoder: 'libx264_does_not_exist');
      final output = p.join(work.path, 'fail-out.mp4');

      await expectLater(
        encode(input, output, plan, info, bins: bins),
        throwsA(isA<HalfsizeException>()),
      );

      expect(File(output).existsSync(), false);
      expect(partFiles(work.path), isEmpty);
    },
  );

  test('an aborted encode leaves nothing behind', () async {
    if (Platform.environment['HALFSIZE_E2E'] != '1') return;
    final input = await source('abort.mp4', seconds: 8, size: '1280x720');
    final info = await probeFile(input, bins: bins);
    final plan = planEncode(info, const PlanOptions(targetBytes: 900000));
    final output = p.join(work.path, 'abort-out.mp4');
    final token = EncodeCancelToken();
    final timer = Future<void>.delayed(
      const Duration(milliseconds: 250),
      token.cancel,
    );

    try {
      await expectLater(
        encode(
          input,
          output,
          EncodePlan(
            mode: plan.mode,
            codec: plan.codec,
            label: plan.label,
            encoder: plan.encoder,
            preset: 'veryslow',
            crf: plan.crf,
            width: plan.width,
            height: plan.height,
            fps: plan.fps,
            videoKbps: plan.videoKbps,
            audioKbps: plan.audioKbps,
            audioChannels: plan.audioChannels,
            targetBytes: plan.targetBytes,
            twoPass: plan.twoPass,
            downscaled: plan.downscaled,
            scaleFilter: plan.scaleFilter,
            fpsFilter: plan.fpsFilter,
            toneMap: plan.toneMap,
            infeasible: plan.infeasible,
            minimumBytes: plan.minimumBytes,
            warnings: plan.warnings,
          ),
          info,
          bins: bins,
          cancel: token,
        ),
        throwsA(
          predicate(
            (e) => e is HalfsizeException && e.code == 'HALFSIZE_CANCELLED',
          ),
        ),
      );
    } finally {
      await timer;
    }

    expect(File(output).existsSync(), false);
    expect(partFiles(work.path), isEmpty);
  });

  test('an already-aborted encode never starts ffmpeg', () async {
    if (Platform.environment['HALFSIZE_E2E'] != '1') return;
    final input = await source('pre-aborted.mp4', seconds: 2);
    final info = await probeFile(input, bins: bins);
    final plan = planEncode(info, const PlanOptions(targetBytes: 150000));
    final output = p.join(work.path, 'pre-aborted-out.mp4');
    final token = EncodeCancelToken()..cancel();

    await expectLater(
      encode(input, output, plan, info, bins: bins, cancel: token),
      throwsA(isA<HalfsizeException>()),
    );
    expect(File(output).existsSync(), false);
  });

  test('measures VMAF and SSIM on the encoded output', () async {
    if (Platform.environment['HALFSIZE_E2E'] != '1') return;
    final input = await source('measure.mp4', seconds: 3);
    final info = await probeFile(input, bins: bins);
    final plan = planEncode(info, const PlanOptions(targetBytes: 500000));
    final output = p.join(work.path, 'measure-out.mp4');

    await encodeToSize(input, output, plan, info, bins: bins);
    final sample = await measureQuality(
      input,
      output,
      info.duration,
      bins: bins,
    );

    expect(sample.ssim, isNotNull);
    expect(sample.ssim, greaterThan(0.5));
    expect(sample.sampled, greaterThan(0));
    expect(sample.vmaf, isNotNull);
    expect(verdict(vmaf: sample.vmaf, ssim: sample.ssim).key, isNot('none'));
  });
}
