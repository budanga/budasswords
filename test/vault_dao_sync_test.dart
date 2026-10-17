import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:budasswords/crypto/crypto_utils.dart';
import 'package:budasswords/crypto/vault_cipher.dart';
import 'package:budasswords/data/local/database.dart';
import 'package:budasswords/data/local/daos/vault_dao.dart';
import 'package:budasswords/domain/models/vault_entry.dart';

void main() {
  late AppDatabase db;
  late VaultDao dao;
  late VaultCipher cipher;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = VaultDao(db);
    cipher = VaultCipher(CryptoUtils.randomBytes(32));
    dao.setCipher(cipher);
  });

  tearDown(() => db.close());

  final t0 = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  Future<VaultEntriesCompanion> remoteRow(String content, DateTime updatedAt) async {
    return VaultEntriesCompanion(
      id: const Value('e1'),
      userId: const Value('u1'),
      titleEnc: Value(await cipher.encryptString('title')),
      urlEnc: const Value(null),
      contentEnc: Value(await cipher.encryptString(content)),
      iv: Value(Uint8List(0)),
      createdAt: Value(t0.millisecondsSinceEpoch),
      updatedAt: Value(updatedAt.millisecondsSinceEpoch),
      deletedAt: const Value(null),
      serverRev: const Value(1),
    );
  }

  Future<VaultEntryData> localRow() =>
      (db.select(db.vaultEntries)..where((t) => t.id.equals('e1'))).getSingle();

  Future<void> editLocally(String content, DateTime updatedAt) => dao.upsertEntry(
        VaultEntry(
          id: 'e1',
          userId: 'u1',
          title: 'title',
          content: content,
          createdAt: t0,
          updatedAt: updatedAt,
        ),
      );

  group('VaultDao.upsertRaw (remote → local)', () {
    test('does not overwrite a pending offline edit with an older remote version', () async {
      await dao.upsertRaw(await remoteRow('v1', t0));
      await editLocally('offline edit', t0.add(const Duration(minutes: 5)));

      // Firestore listener / pull delivers the stale server copy.
      await dao.upsertRaw(await remoteRow('v1', t0));

      final row = await localRow();
      expect(await cipher.decryptToString(row.contentEnc), 'offline edit');
      expect(row.isDirty, 1, reason: 'edit must stay queued for upload');
    });

    test('applies a remote version newer than the pending local edit', () async {
      await editLocally('offline edit', t0);
      await dao.upsertRaw(await remoteRow('newer remote', t0.add(const Duration(minutes: 5))));

      final row = await localRow();
      expect(await cipher.decryptToString(row.contentEnc), 'newer remote');
      expect(row.isDirty, 0);
    });

    test('overwrites a clean local row with the remote version', () async {
      await dao.upsertRaw(await remoteRow('v1', t0));
      await dao.upsertRaw(await remoteRow('v2', t0));

      final row = await localRow();
      expect(await cipher.decryptToString(row.contentEnc), 'v2');
      expect(row.isDirty, 0);
    });
  });
}
