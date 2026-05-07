import 'dart:math';
import 'dart:typed_data';

/// Cryptographic utility helpers.
abstract class CryptoUtils {
  static final _rng = Random.secure();

  /// Generate [length] cryptographically random bytes.
  static Uint8List randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _rng.nextInt(256);
    }
    return bytes;
  }

  /// Zero out a byte array in memory (best-effort in Dart / GC language).
  static void wipe(List<int> bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }

  /// Encode bytes to hex string.
  static String toHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Decode hex string to bytes.
  static Uint8List fromHex(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }
}
