import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../core/constants/app_constants.dart';
import 'crypto_utils.dart';

/// Derives a 256-bit AES key from a master password using Argon2id.
abstract class KeyDerivation {
  /// Derive AES key bytes from [password] and [salt].
  /// [salt] must be [AppConstants.saltLength] (32) bytes.
  static Future<Uint8List> deriveKey({
    required String password,
    required Uint8List salt,
  }) async {
    final algo = Argon2id(
      memory: AppConstants.argon2Memory,
      iterations: AppConstants.argon2Iterations,
      parallelism: AppConstants.argon2Parallelism,
      hashLength: AppConstants.aesKeyLength,
    );

    final passwordBytes = utf8.encode(password);

    final secretKey = await algo.deriveKey(
      secretKey: SecretKey(passwordBytes),
      nonce: salt,
    );

    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }

  /// Generate a fresh random salt.
  static Uint8List generateSalt() =>
      CryptoUtils.randomBytes(AppConstants.saltLength);
}
