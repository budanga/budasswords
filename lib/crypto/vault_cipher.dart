import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../core/constants/app_constants.dart';
import 'crypto_utils.dart';

/// AES-256-GCM encrypt / decrypt helper.
///
/// Blob format: [12-byte IV][N-byte ciphertext][16-byte GCM MAC tag]
class VaultCipher {
  static final _algo = AesGcm.with256bits();

  final Uint8List _keyBytes;

  VaultCipher(this._keyBytes);

  SecretKey get _secretKey => SecretKey(_keyBytes);

  // ───────────────────────────── Encrypt ──────────────────────────────

  /// Encrypt a UTF-8 [plaintext] string.
  /// Returns the encrypted blob: IV + ciphertext + MAC.
  Future<Uint8List> encryptString(String plaintext) async {
    return encrypt(utf8.encode(plaintext));
  }

  /// Encrypt raw [bytes].
  Future<Uint8List> encrypt(List<int> bytes) async {
    final iv = CryptoUtils.randomBytes(AppConstants.ivLength);
    final box = await _algo.encrypt(
      bytes,
      secretKey: _secretKey,
      nonce: iv,
    );
    // Combine: IV | ciphertext | MAC tag
    return Uint8List.fromList([...iv, ...box.cipherText, ...box.mac.bytes]);
  }

  // ───────────────────────────── Decrypt ──────────────────────────────

  /// Decrypt a blob and return the UTF-8 string.
  Future<String> decryptToString(Uint8List blob) async {
    final bytes = await decrypt(blob);
    return utf8.decode(bytes);
  }

  /// Decrypt a blob and return raw bytes.
  Future<Uint8List> decrypt(Uint8List blob) async {
    if (blob.length < AppConstants.ivLength + 16) {
      throw const FormatException('Blob too short to be a valid ciphertext');
    }
    final iv         = blob.sublist(0, AppConstants.ivLength);
    final macOffset  = blob.length - 16;
    final cipherText = blob.sublist(AppConstants.ivLength, macOffset);
    final mac        = blob.sublist(macOffset);

    final box = SecretBox(cipherText, nonce: iv, mac: Mac(mac));
    final plaintext = await _algo.decrypt(box, secretKey: _secretKey);
    return Uint8List.fromList(plaintext);
  }

  // ───────────────────────────── Proof blob ───────────────────────────

  static const _proofPlaintext = 'budasswords-proof-v1';

  /// Create a small encrypted proof used to verify the master password.
  Future<Uint8List> createProof() => encryptString(_proofPlaintext);

  /// Returns true if the current key correctly decrypts [proofBlob].
  Future<bool> verifyProof(Uint8List proofBlob) async {
    try {
      final result = await decryptToString(proofBlob);
      return result == _proofPlaintext;
    } catch (_) {
      return false;
    }
  }

  // ───────────────────────────── Cleanup ──────────────────────────────

  /// Zero the in-memory key bytes (best-effort in Dart).
  void wipe() => CryptoUtils.wipe(_keyBytes);
}
