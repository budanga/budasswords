import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:budasswords/crypto/vault_cipher.dart';
import 'package:budasswords/crypto/key_derivation.dart';
import 'package:budasswords/crypto/crypto_utils.dart';
import 'package:budasswords/core/localization/app_strings.dart';
import 'package:budasswords/domain/models/user_session.dart';
import 'package:budasswords/providers/auth_provider.dart';
import 'package:budasswords/providers/admin_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VaultCipher & KeyDerivation', () {
    test('deriveKey produces consistent 32-byte key from password and salt', () async {
      final salt = KeyDerivation.generateSalt();
      expect(salt.length, 32);

      final key1 = await KeyDerivation.deriveKey(
        password: 'SuperSecretMasterPassword123!',
        salt: salt,
      );
      final key2 = await KeyDerivation.deriveKey(
        password: 'SuperSecretMasterPassword123!',
        salt: salt,
      );

      expect(key1.length, 32);
      expect(key1, equals(key2));
    });

    test('encrypt and decrypt round-trip with correct key', () async {
      final keyBytes = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final cipher = VaultCipher(keyBytes);

      const plaintext = 'MySecretPassword#2026';
      final encrypted = await cipher.encryptString(plaintext);

      expect(encrypted.length, greaterThan(28));

      final decrypted = await cipher.decryptToString(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('proof creation and verification passes with matching key and fails with wrong key', () async {
      final key1 = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final key2 = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

      final cipher1 = VaultCipher(key1);
      final cipher2 = VaultCipher(key2);

      final proof = await cipher1.createProof();

      expect(await cipher1.verifyProof(proof), isTrue);
      expect(await cipher2.verifyProof(proof), isFalse);
    });

    test('decrypting with wrong key fails gracefully and throws error', () async {
      final key1 = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final key2 = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));

      final cipher1 = VaultCipher(key1);
      final cipher2 = VaultCipher(key2);

      final encrypted = await cipher1.encryptString('sensitive data');

      expect(() => cipher2.decryptToString(encrypted), throwsA(anything));
    });

    test('CryptoUtils hex encoding and decoding', () {
      final original = Uint8List.fromList([0, 15, 16, 255, 128, 42]);
      final hex = CryptoUtils.toHex(original);
      final decoded = CryptoUtils.fromHex(hex);

      expect(decoded, equals(original));
    });
  });

  group('Localization & AppStrings', () {
    test('Spanish and English strings return appropriate language texts', () {
      final es = AppStrings.of(AppLocale.es);
      final en = AppStrings.of(AppLocale.en);

      expect(es.appTitle, equals('Budasswords'));
      expect(en.appTitle, equals('Budasswords'));

      expect(es.masterPassword, equals('Contraseña maestra'));
      expect(en.masterPassword, equals('Master password'));

      expect(es.allEntries, equals('Todas las entradas'));
      expect(en.allEntries, equals('All Entries'));

      expect(es.loginsAndAccounts, equals('Cuentas & logins'));
      expect(en.loginsAndAccounts, equals('Logins & Accounts'));

      expect(es.privateNotes, equals('Notas privadas'));
      expect(en.privateNotes, equals('Private Notes'));

      expect(es.paymentCards, equals('Tarjetas & pagos'));
      expect(en.paymentCards, equals('Payment Cards'));

      expect(es.languageSettingTitle, equals('Idioma / Language'));
      expect(en.languageSettingTitle, equals('Language / Idioma'));

      expect(es.settingsTitle, equals('Ajustes'));
      expect(en.settingsTitle, equals('Settings'));

      expect(es.expandPanel, equals('Expandir panel'));
      expect(en.expandPanel, equals('Expand panel'));
      expect(es.collapsePanel, equals('Minimizar panel'));
      expect(en.collapsePanel, equals('Collapse panel'));

      expect(es.cloudSyncTitle, equals('Sincronización en la nube'));
      expect(en.cloudSyncTitle, equals('Cloud sync'));
      expect(es.connectCloudTitle, equals('Vincular cuenta en la nube'));
      expect(en.connectCloudTitle, equals('Link cloud account'));
      expect(es.cloudDisconnected, equals('Modo local (desconectado)'));
      expect(en.cloudDisconnected, equals('Local mode (disconnected)'));
      expect(es.cloudConnectedAs('user@test.com'), equals('Conectado como user@test.com'));
      expect(en.cloudConnectedAs('user@test.com'), equals('Connected as user@test.com'));
    });

    test('AuthState getLocalizedError translates error codes correctly', () {
      final es = AppStrings.of(AppLocale.es);
      final en = AppStrings.of(AppLocale.en);

      const stateWrongPass = AuthState(
        status: AuthStatus.locked,
        errorCode: AuthErrorCode.incorrectPassword,
      );
      expect(stateWrongPass.getLocalizedError(es), equals('Contraseña maestra incorrecta'));
      expect(stateWrongPass.getLocalizedError(en), equals('Incorrect master password'));

      const stateLockout = AuthState(
        status: AuthStatus.locked,
        errorCode: AuthErrorCode.lockoutActive,
        lockoutSeconds: 45,
      );
      expect(stateLockout.getLocalizedError(es), equals('Demasiados intentos. Espera 45s.'));
      expect(stateLockout.getLocalizedError(en), equals('Too many attempts. Try again in 45s.'));
    });

    test('Supabase CSV buffer parser correctly extracts Uint8List', () {
      const sampleBuffer = '"{""type"":""Buffer"",""data"":[33,150,182,97,132,130]}"';
      String unquoted = sampleBuffer;
      if (unquoted.startsWith('"') && unquoted.endsWith('"')) {
        unquoted = unquoted.substring(1, unquoted.length - 1);
      }
      unquoted = unquoted.replaceAll('""', '"');
      final decoded = jsonDecode(unquoted) as Map<String, dynamic>;
      final dataList = (decoded['data'] as List<dynamic>).cast<int>();
      final bytes = Uint8List.fromList(dataList);

      expect(bytes.length, equals(6));
      expect(bytes[0], equals(33));
      expect(bytes[1], equals(150));
    });
  });

  group('Admin Authorization & State', () {
    test('UserSession isAdmin correctly identifies admin role', () {
      final adminSession = UserSession(
        userId: 'admin-123',
        email: 'lautaro_budin@hotmail.com',
        unlockedAt: DateTime.now(),
        role: 'admin',
      );
      final adminSessionCase = UserSession(
        userId: 'admin-123',
        email: 'admin_user@example.com',
        unlockedAt: DateTime.now(),
        role: 'ADMIN ',
      );
      final regularSession = UserSession(
        userId: 'user-456',
        email: 'regular_user@example.com',
        unlockedAt: DateTime.now(),
        role: 'user',
      );

      expect(adminSession.isAdmin, isTrue);
      expect(adminSessionCase.isAdmin, isTrue);
      expect(regularSession.isAdmin, isFalse);
    });

    test('AdminState filteredUsers filters accurately by email and uid', () {
      const u1 = AdminUserItem(uid: 'uid-1', email: 'lautaro_budin@hotmail.com', role: 'admin');
      const u2 = AdminUserItem(uid: 'uid-2', email: 'alice@gmail.com', role: 'user');
      const u3 = AdminUserItem(uid: 'uid-3', email: 'bob@proton.me', role: 'user');

      const state = AdminState(users: [u1, u2, u3]);

      expect(state.filteredUsers.length, equals(3));

      final filteredByEmail = state.copyWith(searchQuery: 'lautaro');
      expect(filteredByEmail.filteredUsers.length, equals(1));
      expect(filteredByEmail.filteredUsers.first.email, equals('lautaro_budin@hotmail.com'));

      final filteredByUid = state.copyWith(searchQuery: 'uid-2');
      expect(filteredByUid.filteredUsers.length, equals(1));
      expect(filteredByUid.filteredUsers.first.email, equals('alice@gmail.com'));
    });
  });
}



