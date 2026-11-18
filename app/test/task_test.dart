import 'package:flutter_test/flutter_test.dart';
import 'package:halfsizex/features/tasks/task_controller.dart';

void main() {
  test('task history survives a json round trip', () {
    final task =
        CompressTask(
            id: '1',
            inputPath: 'clip.mp4',
            options: const TaskOptions(
              targetBytes: 20000000,
              codec: 'h265',
              preset: 'slow',
              downscale: true,
              audio: false,
              qualityCheck: true,
              outputName: 'tiny',
            ),
            createdAt: DateTime(2026, 1, 2, 3, 4),
          )
          ..status = TaskStatus.done
          ..outputPath = 'tiny.mp4'
          ..finishedAt = DateTime(2026, 1, 2, 3, 5);

    final copy = TaskRecord.fromJson(TaskRecord.fromTask(task).toJson());

    expect(copy.name, 'clip.mp4');
    expect(copy.codec, 'h265');
    expect(copy.preset, 'slow');
    expect(copy.targetBytes, 20000000);
    expect(copy.status, 'done');
    expect(copy.outputPath, 'tiny.mp4');
  });
}
