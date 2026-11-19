import 'dart:math';

final Random _rng = Random.secure();
const _alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';

/// Random lowercase base-36 string of [length] characters (cryptographically secure).
String randomId([int length = 20]) =>
    List.generate(length, (_) => _alphabet[_rng.nextInt(_alphabet.length)]).join();

/// RFC-4122 v4 UUID.
String uuidV4() {
  final b = List<int>.generate(16, (_) => _rng.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

/// Local calendar date as YYYY-MM-DD.
String localDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
