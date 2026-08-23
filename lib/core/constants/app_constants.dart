/// App-wide magic numbers and configuration defaults.
abstract class AppConstants {
  // Session
  static const autoLockMinutes      = 5;
  static const clipboardClearSeconds = 30;

  // Crypto
  static const argon2Memory      = 65536; // 64 MB
  static const argon2Iterations  = 3;
  static const argon2Parallelism = 2;
  static const aesKeyLength      = 32;   // 256-bit
  static const saltLength        = 32;
  static const ivLength          = 12;   // GCM nonce

  // Sync
  static const syncRetryDelayMs = 3000;
  static const maxSyncQueueSize = 200;

  // Secure-storage keys
  static const kSaltKey        = 'bud_salt';
  static const kProofBlobKey   = 'bud_proof';
  static const kBiometricKey   = 'bud_biometric_aes';
  static const kLockTimeoutKey = 'bud_lock_timeout';
  static const kPinnedKey      = 'bud_pinned_entries';
  static const kUserIdKey      = 'bud_user_id';
  static const kEmailKey       = 'bud_user_email';
  static const kRoleKey        = 'bud_user_role';
}

