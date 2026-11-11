String bytes(num? n) {
  if (n == null) return '-';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = n.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  final digits = value >= 100 ? 0 : (value >= 10 ? 1 : 2);
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String duration(num? seconds) {
  if (seconds == null || !seconds.isFinite || seconds <= 0) return '-';
  final s = seconds.round();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  if (m > 0) return '${m}m ${sec.toString().padLeft(2, '0')}s';
  return '${sec}s';
}

String bitrate(num? kbps) {
  if (kbps == null || kbps == 0) return '-';
  return kbps >= 1000
      ? '${(kbps / 1000).toStringAsFixed(2)} Mbps'
      : '${kbps.round()} kbps';
}

String ratio(num? from, num? to) {
  if (from == null || to == null || from == 0 || to == 0) return '-';
  final value = from / to;
  if (value >= 10) return '${value.round()}x';
  return '${((value * 10).round() / 10).toStringAsFixed(1)}x';
}

String clock(num seconds) {
  final s = seconds < 0 ? 0 : seconds.round();
  final m = s ~/ 60;
  return '${m.toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';
}

int parseSize(Object input) {
  if (input is num) return input.toInt();
  final raw = input.toString().trim().toLowerCase();
  final match =
      RegExp(r'^([0-9]*\.?[0-9]+)\s*(b|kb|k|mb|m|gb|g)?$').firstMatch(raw);
  if (match == null) {
    throw FormatException(
      'Cannot read size "$input". Try 25mb, 700k or 1.5gb.',
    );
  }
  final value = double.parse(match.group(1)!);
  const scale = <String, int>{
    'b': 1,
    'k': 1000,
    'kb': 1000,
    'm': 1000000,
    'mb': 1000000,
    'g': 1000000000,
    'gb': 1000000000,
  };
  final unit = match.group(2) ?? 'mb';
  return (value * scale[unit]!).round();
}
