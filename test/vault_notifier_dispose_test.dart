import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budasswords/crypto/crypto_utils.dart';
import 'package:budasswords/crypto/vault_cipher.dart';
import 'package:budasswords/data/local/database.dart';
import 'package:budasswords/data/local/daos/vault_dao.dart';
import 'package:budasswords/data/remote/firebase_vault_api.dart';
import 'package:budasswords/providers/vault_provider.dart';

/// Remote API whose fetch only finishes when the test says so.
class _SlowApi extends Fake implements FirebaseVaultApi {
  final fetch = Completer<List<Map<String, dynamic>>>();

  @override
  Future<List<Map<String, dynamic>>> fetchAll(String userId, {DateTime? since}) => fetch.future;

  @override
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> watchChanges(
    String userId, {
    required void Function(List<Map<String, dynamic>> upserted, List<String> deletedIds) onChanges,
  }) =>
      const Stream<QuerySnapshot<Map<String, dynamic>>>.empty().listen(null);
}

void main() {
  late AppDatabase db;
  late VaultDao dao;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = VaultDao(db)..setCipher(VaultCipher(CryptoUtils.randomBytes(32)));
  });

  tearDown(() => db.close());

  test('a sync still running when the notifier is disposed finishes quietly', () async {
    final api = _SlowApi();
    final notifier = VaultNotifier(dao, api, 'u1', canSyncRemote: () => true);

    final pull = notifier.pullFromRemote();
    notifier.dispose(); // e.g. the vault locks or the provider rebuilds mid-sync
    api.fetch.complete(const []);

    await expectLater(pull, completes);
  });
}
