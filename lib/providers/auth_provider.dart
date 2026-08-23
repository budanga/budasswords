import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:budasswords/core/constants/app_constants.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/crypto/key_derivation.dart';
import 'package:budasswords/crypto/vault_cipher.dart';
import 'package:budasswords/crypto/crypto_utils.dart';
import 'package:budasswords/domain/models/user_session.dart';
import 'package:budasswords/data/local/daos/vault_dao.dart';
import 'package:budasswords/data/remote/firebase_vault_api.dart';
import 'package:budasswords/providers/crypto_provider.dart';

// ──────────────────────────────────────────────────
// Auth state
// ──────────────────────────────────────────────────

enum AuthStatus { loading, setup, locked, unlocked }

enum AuthErrorCode {
  none,
  incorrectPassword,
  tooManyAttempts,
  lockoutActive,
  invalidCredentials,
  emailNotConfirmed,
  setupFailed,
  noVaultFound,
  unknown,
}

class AuthState {
  final AuthStatus status;
  final UserSession? session;
  final String? error;
  final AuthErrorCode? errorCode;
  final int? lockoutSeconds;

  const AuthState({
    required this.status,
    this.session,
    this.error,
    this.errorCode,
    this.lockoutSeconds,
  });

  String? getLocalizedError(AppStrings strings) {
    if (errorCode == null) return error;
    switch (errorCode!) {
      case AuthErrorCode.none:
        return null;
      case AuthErrorCode.incorrectPassword:
        return strings.incorrectPassword;
      case AuthErrorCode.tooManyAttempts:
        return strings.tooManyFailedAttempts;
      case AuthErrorCode.lockoutActive:
        return strings.lockoutCountdown(lockoutSeconds ?? 60);
      case AuthErrorCode.invalidCredentials:
        return strings.invalidCredentials;
      case AuthErrorCode.emailNotConfirmed:
        return strings.emailNotConfirmed;
      case AuthErrorCode.setupFailed:
        return strings.setupFailed;
      case AuthErrorCode.noVaultFound:
        return strings.noVaultFound;
      case AuthErrorCode.unknown:
        return error ?? strings.operationFailed;
    }
  }

  AuthState copyWith({
    AuthStatus? status,
    UserSession? session,
    String? error,
    AuthErrorCode? errorCode,
    int? lockoutSeconds,
  }) =>
      AuthState(
        status: status ?? this.status,
        session: session ?? this.session,
        error: error,
        errorCode: errorCode,
        lockoutSeconds: lockoutSeconds,
      );
}

// ──────────────────────────────────────────────────
// Notifier
// ──────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _secureStorage;
  final VaultDao _vaultDao;
  final FirebaseVaultApi _remoteApi;

  VaultCipher? _cipher;
  Timer? _autolockTimer;
  int _timeoutMinutes = AppConstants.autoLockMinutes;

  int _failedUnlockAttempts = 0;
  DateTime? _lockoutUntil;

  AuthNotifier(this._secureStorage, this._vaultDao, [FirebaseVaultApi? remoteApi])
      : _remoteApi = remoteApi ?? FirebaseVaultApi(),
        super(const AuthState(status: AuthStatus.loading)) {
    _init();
  }

  // ── Autolock ──────────────────────────────────────

  void resetAutolock() {
    _autolockTimer?.cancel();
    if (state.status != AuthStatus.unlocked) return;

    _autolockTimer = Timer(Duration(minutes: _timeoutMinutes), () {
      lock();
    });
  }

  Future<void> updateTimeout(int minutes) async {
    _timeoutMinutes = minutes;
    await _secureStorage.write(
      key: AppConstants.kLockTimeoutKey,
      value: minutes.toString(),
    );
    resetAutolock();
  }

  int get timeoutMinutes => _timeoutMinutes;

  // ── Init ──────────────────────────────────────────

  Future<void> _init() async {
    // Check if first launch (no salt stored yet)
    final salt = await _secureStorage.read(key: AppConstants.kSaltKey);
    final timeoutStr =
        await _secureStorage.read(key: AppConstants.kLockTimeoutKey);
    if (timeoutStr != null) {
      _timeoutMinutes = int.tryParse(timeoutStr) ?? AppConstants.autoLockMinutes;
    }

    if (salt == null) {
      state = state.copyWith(status: AuthStatus.setup);
    } else {
      state = state.copyWith(status: AuthStatus.locked);
    }
  }

  // ── First-time setup ──────────────────────────────

  Future<bool> setup({
    required String email,
    required String password,
    required String masterPassword,
  }) async {
    try {
      // 1. Derive AES key and generate salt/proof first
      final salt = KeyDerivation.generateSalt();
      final keyBytes = await KeyDerivation.deriveKey(
        password: masterPassword,
        salt: salt,
      );
      _cipher = VaultCipher(keyBytes);
      final proof = await _cipher!.createProof();

      // 2. Create Firebase Auth account
      final userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCred.user;
      if (user == null) throw Exception('Sign-up failed');

      // 3. Save salt and proof to Firestore metadata document
      await _remoteApi.saveVaultMetadata(
        user.uid,
        saltHex: CryptoUtils.toHex(salt),
        proofHex: CryptoUtils.toHex(proof),
      );

      // Save user profile in Firestore users directory (preserving existing role or defaulting to 'user')
      try {
        await _remoteApi.saveUserProfile(user.uid, email: email);
      } catch (_) {}

      final profile = await _remoteApi.fetchUserProfile(user.uid);
      final role = profile?['role'] as String? ?? 'user';
      await _secureStorage.write(key: AppConstants.kRoleKey, value: role);

      // 4. Persist salt + proof + user info locally
      await _secureStorage.write(
        key: AppConstants.kSaltKey,
        value: CryptoUtils.toHex(salt),
      );
      await _secureStorage.write(
        key: AppConstants.kProofBlobKey,
        value: CryptoUtils.toHex(proof),
      );
      await _secureStorage.write(
        key: AppConstants.kUserIdKey,
        value: user.uid,
      );
      await _secureStorage.write(
        key: AppConstants.kEmailKey,
        value: email,
      );

      // 5. Clear any old data from previous accounts
      await _vaultDao.clearAll();

      // 6. Unlock DAO
      _vaultDao.setCipher(_cipher!);

      state = state.copyWith(
        status: AuthStatus.unlocked,
        session: UserSession(
          userId: user.uid,
          email: email,
          unlockedAt: DateTime.now(),
          role: role,
        ),
      );
      resetAutolock();
      return true;
    } catch (e) {
      AuthErrorCode code = AuthErrorCode.setupFailed;
      String message = 'Setup failed. Please check your details and try again.';

      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          message = 'An account with this email already exists.';
        } else if (e.code == 'weak-password') {
          message = 'Password should be at least 6 characters.';
        } else if (e.code == 'invalid-email') {
          message = 'Please enter a valid email address.';
        } else if (e.code == 'internal-error' || e.code == 'invalid-credential') {
          message = 'Registration failed. Please check your email and password format.';
        } else if (e.code == 'network-request-failed') {
          message = 'Network error. Please check your internet connection.';
        }
      }

      state = state.copyWith(
        status: AuthStatus.setup,
        error: message,
        errorCode: code,
      );
      return false;
    }
  }

  // ── Login to existing account ─────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCred.user;
      if (user == null) throw Exception('Login failed');

      // Persist user id and email
      await _secureStorage.write(
        key: AppConstants.kUserIdKey,
        value: user.uid,
      );
      await _secureStorage.write(
        key: AppConstants.kEmailKey,
        value: email,
      );

      // Save/update user profile in Firestore users directory (preserving existing role or defaulting to 'user')
      try {
        await _remoteApi.saveUserProfile(user.uid, email: email);
      } catch (_) {}

      final profile = await _remoteApi.fetchUserProfile(user.uid);
      final role = profile?['role'] as String? ?? 'user';
      await _secureStorage.write(key: AppConstants.kRoleKey, value: role);

      // Check if we need to pull salt/proof from Firestore
      final meta = await _remoteApi.fetchVaultMetadata(user.uid);
      if (meta != null) {
        final saltHex = meta['vault_salt'] as String?;
        final proofHex = meta['vault_proof'] as String?;

        if (saltHex != null && proofHex != null) {
          await _secureStorage.write(key: AppConstants.kSaltKey, value: saltHex);
          await _secureStorage.write(
              key: AppConstants.kProofBlobKey, value: proofHex);
        }
      }

      state = state.copyWith(status: AuthStatus.locked);
      return true;
    } catch (e) {
      String message = 'Authentication failed. Please check your credentials.';
      AuthErrorCode code = AuthErrorCode.invalidCredentials;

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
          case 'invalid-password':
          case 'INVALID_LOGIN_CREDENTIALS':
            message = 'Incorrect email or account password.';
            code = AuthErrorCode.invalidCredentials;
            break;
          case 'invalid-email':
            message = 'The email address is invalid.';
            code = AuthErrorCode.invalidCredentials;
            break;
          case 'user-disabled':
            message = 'This user account has been disabled.';
            code = AuthErrorCode.invalidCredentials;
            break;
          case 'too-many-requests':
            message = 'Too many failed attempts. Please try again later.';
            code = AuthErrorCode.tooManyAttempts;
            break;
          case 'network-request-failed':
            message = 'Network error. Please check your internet connection.';
            code = AuthErrorCode.unknown;
            break;
          case 'internal-error':
            message = 'Authentication failed. Check that your email and password are correct.';
            code = AuthErrorCode.invalidCredentials;
            break;
          default:
            message = 'Authentication failed. Please verify your email and password.';
            code = AuthErrorCode.invalidCredentials;
        }
      } else {
        message = 'Authentication failed. Please check your credentials.';
        code = AuthErrorCode.invalidCredentials;
      }

      state = state.copyWith(
        error: message,
        errorCode: code,
      );
      return false;
    }
  }

  /// Manually update vault salt and proof (used during legacy migration)
  Future<void> updateVaultMeta({
    required String saltHex,
    required String proofHex,
  }) async {
    await _secureStorage.write(key: AppConstants.kSaltKey, value: saltHex);
    await _secureStorage.write(key: AppConstants.kProofBlobKey, value: proofHex);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _remoteApi.saveVaultMetadata(
        user.uid,
        saltHex: saltHex,
        proofHex: proofHex,
      );
    }
  }

  // ── Unlock with master password ───────────────────

  Future<bool> unlock(String masterPassword) async {
    if (_lockoutUntil != null && DateTime.now().isBefore(_lockoutUntil!)) {
      final secondsLeft = _lockoutUntil!.difference(DateTime.now()).inSeconds;
      state = state.copyWith(
        status: AuthStatus.locked,
        error: 'Too many attempts. Try again in $secondsLeft seconds.',
        errorCode: AuthErrorCode.lockoutActive,
        lockoutSeconds: secondsLeft,
      );
      return false;
    }

    try {
      var saltHex = await _secureStorage.read(key: AppConstants.kSaltKey);
      var proofHex = await _secureStorage.read(key: AppConstants.kProofBlobKey);

      // If missing locally, try to fetch from Firestore metadata
      if (saltHex == null || proofHex == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final meta = await _remoteApi.fetchVaultMetadata(user.uid);
          if (meta != null) {
            saltHex = meta['vault_salt'] as String?;
            proofHex = meta['vault_proof'] as String?;

            if (saltHex != null && proofHex != null) {
              await _secureStorage.write(
                  key: AppConstants.kSaltKey, value: saltHex);
              await _secureStorage.write(
                  key: AppConstants.kProofBlobKey, value: proofHex);
            }
          }
        }
      }

      if (saltHex == null || proofHex == null) {
        throw Exception('No vault found. Please set up first.');
      }

      final salt = CryptoUtils.fromHex(saltHex);
      final proofBlob = CryptoUtils.fromHex(proofHex);

      final keyBytes = await KeyDerivation.deriveKey(
        password: masterPassword,
        salt: salt,
      );
      final candidate = VaultCipher(keyBytes);

      final valid = await candidate.verifyProof(proofBlob);
      if (!valid) {
        candidate.wipe();
        _failedUnlockAttempts++;
        if (_failedUnlockAttempts >= 5) {
          _lockoutUntil = DateTime.now().add(const Duration(minutes: 1));
          _failedUnlockAttempts = 0;
          state = state.copyWith(
            status: AuthStatus.locked,
            error: 'Too many failed attempts. Locked out for 1 minute.',
            errorCode: AuthErrorCode.tooManyAttempts,
          );
        } else {
          state = state.copyWith(
            status: AuthStatus.locked,
            error: 'Incorrect master password.',
            errorCode: AuthErrorCode.incorrectPassword,
          );
        }
        return false;
      }

      _failedUnlockAttempts = 0;
      _lockoutUntil = null;

      _cipher = candidate;
      _vaultDao.setCipher(_cipher!);

      final firebaseUser = FirebaseAuth.instance.currentUser;
      var userId = firebaseUser?.uid ?? await _secureStorage.read(key: AppConstants.kUserIdKey);
      final email = firebaseUser?.email ?? (await _secureStorage.read(key: AppConstants.kEmailKey) ?? '');

      if (userId == null || userId == 'offline') {
        userId = const Uuid().v4();
        await _secureStorage.write(key: AppConstants.kUserIdKey, value: userId);
      }

      var role = await _secureStorage.read(key: AppConstants.kRoleKey) ?? 'user';
      if (firebaseUser != null) {
        final profile = await _remoteApi.fetchUserProfile(firebaseUser.uid);
        if (profile != null && profile['role'] != null) {
          role = profile['role'] as String;
          await _secureStorage.write(key: AppConstants.kRoleKey, value: role);
        }
      }

      state = state.copyWith(
        status: AuthStatus.unlocked,
        session: UserSession(
          userId: userId,
          email: email,
          unlockedAt: DateTime.now(),
          role: role,
        ),
      );
      resetAutolock();
      return true;
    } catch (e) {
      String message = 'Unlock failed. Please try again.';
      if (e.toString().contains('No vault found')) {
        message = 'No vault found for this account. Please set up first.';
      } else {
        message = 'An unexpected error occurred during unlock.';
      }

      state = state.copyWith(
        status: AuthStatus.locked,
        error: message,
      );
      return false;
    }
  }

  // ── Lock ──────────────────────────────────────────

  void lock() {
    _cipher?.wipe();
    _cipher = null;
    _vaultDao.clearCipher();
    _autolockTimer?.cancel();
    state = const AuthState(status: AuthStatus.locked);
  }

  // ── Sign out ──────────────────────────────────────

  Future<void> signOut() async {
    lock();
    await FirebaseAuth.instance.signOut();
    await _secureStorage.delete(key: AppConstants.kSaltKey);
    await _secureStorage.delete(key: AppConstants.kProofBlobKey);
    await _secureStorage.delete(key: AppConstants.kUserIdKey);
    await _secureStorage.delete(key: AppConstants.kEmailKey);
    await _secureStorage.delete(key: AppConstants.kBiometricKey);
    await _secureStorage.delete(key: AppConstants.kPinnedKey);
    await _vaultDao.clearAll();
    state = const AuthState(status: AuthStatus.setup);
  }

  /// Clear transient error message.
  void clearError() => state = state.copyWith(error: null);
}

// ──────────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  const storage = FlutterSecureStorage();
  final dao = ref.watch(vaultDaoProvider);
  final api = ref.watch(firebaseVaultApiProvider);
  return AuthNotifier(storage, dao, api);
});

