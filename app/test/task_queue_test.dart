import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:halfsizex/core/ffmpeg/ffmpeg_locator.dart';
import 'package:halfsizex/core/settings/app_settings.dart';
import 'package:halfsizex/features/tasks/task_controller.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('queues a video and records it when finished', () async {
    if (Platform.environment['HALFSIZE_E2E'] != '1') return;
    final bins = await FfmpegLocator.resolve();
    if (!bins.ok) return;
    final work = Directory.systemTemp.createTempSync('halfsize-queue-');
    try {
      final input = p.join(work.path, 'clip.mp4');
      final made = await Process.run(bins.ffmpeg, [
        '-hide_banner',
        '-loglevel',
        'error',
        '-y',
        '-f',
        'lavfi',
        '-i',
        'testsrc2=size=320x240:rate=30',
        '-f',
        'lavfi',
        '-i',
        'sine=frequency=440:sample_rate=48000',
        '-t',
        '2',
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
        input,
      ]);
      expect(made.exitCode, 0, reason: '${made.stderr}');

      SharedPreferences.setMockInitialValues({});
      final settings = await AppSettings.load();
      final controller = TaskController(settings: settings);
      await controller.init();
      controller.addFiles(
        [input],
        const TaskOptions(
          targetBytes: 400000,
          codec: 'h264',
          preset: 'ultrafast',
          downscale: true,
          audio: true,
          qualityCheck: false,
        ),
      );

      final deadline = DateTime.now().add(const Duration(seconds: 60));
      while (controller.tasks.single.status != TaskStatus.done &&
          controller.tasks.single.status != TaskStatus.failed &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      final task = controller.tasks.single;
      expect(task.status, TaskStatus.done, reason: task.error);
      expect(task.outputPath, isNotNull);
      expect(File(task.outputPath!).existsSync(), true);
      expect(controller.history, hasLength(1));
      controller.dispose();
    } finally {
      work.deleteSync(recursive: true);
    }
  });
}
