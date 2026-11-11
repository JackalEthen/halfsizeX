import 'package:flutter_test/flutter_test.dart';
import 'package:halfsizex/core/halfsize/quality.dart';

void main() {
  test('VMAF is preferred when both metrics exist', () {
    final v = verdict(vmaf: 96, ssim: 0.9);
    expect(v.key, 'indistinguishable');
    expect(v.tone, 'good');
  });

  test('VMAF thresholds map to human words', () {
    expect(verdict(vmaf: 95).key, 'indistinguishable');
    expect(verdict(vmaf: 90).key, 'same');
    expect(verdict(vmaf: 80).key, 'slight');
    expect(verdict(vmaf: 70).key, 'visible');
    expect(verdict(vmaf: 42).key, 'degraded');
    expect(verdict(vmaf: 42).tone, 'bad');
  });

  test('SSIM is the fallback when VMAF is unavailable', () {
    expect(verdict(ssim: 0.99).key, 'indistinguishable');
    expect(verdict(ssim: 0.96).key, 'same');
    expect(verdict(ssim: 0.92).key, 'slight');
    expect(verdict(ssim: 0.7).key, 'visible');
  });

  test('no metrics means no claim', () {
    final v = verdict();
    expect(v.key, 'none');
    expect(v.tone, 'unknown');
  });
}
