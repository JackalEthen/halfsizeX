import 'package:flutter_test/flutter_test.dart';
import 'package:halfsizex/core/halfsize/models.dart';
import 'package:halfsizex/core/halfsize/plan.dart';
import 'package:halfsizex/features/compress/compress_controller.dart';

void main() {
  test('a source already under the target is not encoded again', () async {
    const input = 'already-small.mp4';
    final info = ProbeInfo(
      file: input,
      duration: 10,
      sizeBytes: 1000000,
      video: const VideoInfo(width: 1280, height: 720, fps: 30),
    );
    final controller = CompressController()
      ..info = info
      ..plan = planEncode(info, const PlanOptions(targetBytes: 20000000));

    await controller.start();

    expect(controller.skipped, true);
    expect(controller.outputPath, input);
    expect(controller.result?.outputBytes, 1000000);
    expect(controller.stage, CompressStage.done);
  });
}
