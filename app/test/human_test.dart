import 'package:flutter_test/flutter_test.dart';
import 'package:halfsizex/core/halfsize/human.dart';

void main() {
  test('parseSize reads every unit people actually type', () {
    expect(parseSize('25mb'), 25000000);
    expect(parseSize('25 MB'), 25000000);
    expect(parseSize('700k'), 700000);
    expect(parseSize('1.5gb'), 1500000000);
    expect(parseSize('512b'), 512);
    expect(parseSize('2'), 2000000);
    expect(parseSize(1234), 1234);
  });

  test('parseSize rejects nonsense instead of guessing', () {
    expect(() => parseSize('abc'), throwsA(isA<FormatException>()));
    expect(() => parseSize('12 tb'), throwsA(isA<FormatException>()));
  });

  test('bytes switches units and keeps useful precision', () {
    expect(bytes(999), '999 B');
    expect(bytes(1000), '1.00 KB');
    expect(bytes(23200000), '23.2 MB');
    expect(bytes(1500000000), '1.50 GB');
    expect(bytes(null), '-');
  });

  test('duration is human, not seconds', () {
    expect(duration(8), '8s');
    expect(duration(75), '1m 15s');
    expect(duration(3725), '1h 02m');
    expect(duration(0), '-');
  });

  test('bitrate and ratio pick readable forms', () {
    expect(bitrate(900), '900 kbps');
    expect(bitrate(1810), '1.81 Mbps');
    expect(ratio(23.2, 1.99), '12x');
    expect(ratio(10, 8), '1.3x');
  });

  test('clock pads minutes and seconds', () {
    expect(clock(0), '00:00');
    expect(clock(65), '01:05');
    expect(clock(-3), '00:00');
  });
}
