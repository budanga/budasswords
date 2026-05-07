import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:budasswords/core/constants/app_constants.dart';
import 'package:budasswords/crypto/key_derivation.dart';
import 'package:budasswords/crypto/vault_cipher.dart';
import 'package:budasswords/crypto/crypto_utils.dart';
import 'package:budasswords/domain/models/user_session.dart';
import 'package:budasswords/data/local/daos/vault_dao.dart';
import 'package:budasswords/providers/crypto_provider.dart';

// ──────────────────────────────────────────────────
// Auth state
// ──────────────────────────────────────────────────

enum AuthStatus { loading, setup, locked, unlocked }

class AuthState {
  final AuthStatus status;
  final UserSession? session;
  final String? error;

  const AuthState({
    required this.status,
    this.session,
    this.error,
  });

  AuthState copyWith(
          {AuthStatus? status, UserSession? session, String? error}) =>
      AuthState(
        status: status ?? this.status,
        session: session ?? this.session,
        error: error,
      );
}

// ──────────────────────────────────────────────────
// Notifier
// ──────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _secureStorage;
  final VaultDao _vaultDao;

  VaultCipher? _cipher;

  AuthNotifier(this._secureStorage, this._vaultDao)
      : super(const AuthState(status: AuthStatus.loading)) {
    _init();
  }

  // ── Init ──────────────────────────────────────────

  Future<void> _init() async {
    // Check if first launch (no salt stored yet)
    final salt = await _secureStorage.read(key: AppConstants.kSaltKey);
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
      // 1. Create Supabase account
      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user == null) throw Exception('Sign-up failed');

      // 2. Derive AES key
      final salt = KeyDerivation.generateSalt();
      final keyBytes = await KeyDerivation.deriveKey(
        password: masterPassword,
        salt: salt,
      );
      _cipher = VaultCipher(keyBytes);

      // 3. Create proof blob so we can verify master pw later
      final proof = await _cipher!.createProof();

      // 4. Persist salt + proof locally
      await _secureStorage.write(
        key: AppConstants.kSaltKey,
        value: CryptoUtils.toHex(salt),
      );
      await _secureStorage.write(
        key: AppConstants.kProofBlobKey,
        value: CryptoUtils.toHex(proof),
      );

      // 5. Sync salt + proof to Supabase Metadata (for other devices)
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {
            'vault_salt': CryptoUtils.toHex(salt),
            'vault_proof': CryptoUtils.toHex(proof),
          },
        ),
      );

      // 6. Unlock DAO
      _vaultDao.setCipher(_cipher!);

      state = state.copyWith(
        status: AuthStatus.unlocked,
        session: UserSession(
          userId: res.user!.id,
          email: email,
          unlockedAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.locked,
        error: e.toString(),
      );
      return false;
    }
  }

  // ── Login to existing account ─────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) throw Exception('Login failed');

      // Check if we need to pull salt/proof from metadata
      final metadata = res.user!.userMetadata;
      final saltHex = metadata?['vault_salt'] as String?;
      final proofHex = metadata?['vault_proof'] as String?;

      if (saltHex != null && proofHex != null) {
        await _secureStorage.write(key: AppConstants.kSaltKey, value: saltHex);
        await _secureStorage.write(
            key: AppConstants.kProofBlobKey, value: proofHex);
      }

      state = state.copyWith(status: AuthStatus.locked);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.setup,
        error: e.toString(),
      );
      return false;
    }
  }

  // ── Unlock with master password ───────────────────

  Future<bool> unlock(String masterPassword) async {
    try {
      var saltHex = await _secureStorage.read(key: AppConstants.kSaltKey);
      var proofHex = await _secureStorage.read(key: AppConstants.kProofBlobKey);

      // If missing locally, try to fetch from Supabase metadata
      if (saltHex == null || proofHex == null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          saltHex = user.userMetadata?['vault_salt'] as String?;
          proofHex = user.userMetadata?['vault_proof'] as String?;

          if (saltHex != null && proofHex != null) {
            await _secureStorage.write(
                key: AppConstants.kSaltKey, value: saltHex);
            await _secureStorage.write(
                key: AppConstants.kProofBlobKey, value: proofHex);
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
        state = state.copyWith(
          status: AuthStatus.locked,
          error: 'Incorrect master password.',
        );
        return false;
      }

      // Sign in to Supabase (will refresh existing session)
      // NOTE: For a personal app, you may store Supabase creds in secure storage
      // or require email+password on first unlock after install.
      _cipher = candidate;
      _vaultDao.setCipher(_cipher!);

      final supaUser = Supabase.instance.client.auth.currentUser;
      state = state.copyWith(
        status: AuthStatus.unlocked,
        session: UserSession(
          userId: supaUser?.id ?? 'offline',
          email: supaUser?.email ?? '',
          unlockedAt: DateTime.now(),
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.locked,
        error: e.toString(),
      );
      return false;
    }
  }

  // ── Lock ──────────────────────────────────────────

  void lock() {
    _cipher?.wipe();
    _cipher = null;
    _vaultDao.clearCipher();
    state = const AuthState(status: AuthStatus.locked);
  }

  // ── Sign out ──────────────────────────────────────

  Future<void> signOut() async {
    lock();
    await Supabase.instance.client.auth.signOut();
    await _secureStorage.deleteAll();
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
  return AuthNotifier(storage, dao);
});
