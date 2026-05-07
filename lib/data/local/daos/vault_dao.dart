import 'package:drift/drift.dart';
import 'package:budasswords/data/local/database.dart';
import 'package:budasswords/domain/models/vault_entry.dart';
import 'package:budasswords/crypto/vault_cipher.dart';

/// Data access object for [VaultEntries].
/// Encrypts on write, decrypts on read — cipher must be set after unlock.
class VaultDao {
  final AppDatabase _db;
  VaultCipher? _cipher;

  VaultDao(this._db);

  void setCipher(VaultCipher cipher) => _cipher = cipher;
  void clearCipher() => _cipher = null;

  VaultCipher get _c {
    if (_cipher == null) throw StateError('Vault is locked');
    return _cipher!;
  }

  // ─────────────────────────── Watch ────────────────────────────────

  Stream<List<VaultEntry>> watchAll(String userId) {
    return (_db.select(_db.vaultEntries)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .asyncMap((rows) async {
      final result = <VaultEntry>[];
      for (final row in rows) {
        result.add(await _decrypt(row));
      }
      return result;
    });
  }

  // ─────────────────────────── Write ────────────────────────────────

  Future<void> upsertEntry(VaultEntry entry) async {
    final now = entry.updatedAt.millisecondsSinceEpoch;
    final iv = Uint8List.fromList(
        List<int>.filled(0, 0)); // will be generated inside cipher

    final titleBlob = await _c.encryptString(entry.title);
    final urlBlob =
        entry.url != null ? await _c.encryptString(entry.url!) : null;
    final contentBlob = await _c.encryptString(entry.content);

    await _db.into(_db.vaultEntries).insertOnConflictUpdate(
          VaultEntriesCompanion(
            id: Value(entry.id),
            userId: Value(entry.userId),
            titleEnc: Value(titleBlob),
            urlEnc: Value(urlBlob),
            contentEnc: Value(contentBlob),
            iv: Value(iv), // IV is embedded in each blob
            createdAt: Value(entry.createdAt.millisecondsSinceEpoch),
            updatedAt: Value(now),
            deletedAt: Value(entry.deletedAt?.millisecondsSinceEpoch),
            serverRev: Value(entry.serverRev),
            isDirty: const Value(1),
          ),
        );
  }

  /// Inserts raw encrypted data from remote (Supabase).
  /// isDirty is set to 0 because it's already on the server.
  Future<void> upsertRaw(VaultEntriesCompanion companion) async {
    await _db.into(_db.vaultEntries).insertOnConflictUpdate(
          companion.copyWith(isDirty: const Value(0)),
        );
  }

  Future<void> markClean(String id) async {
    await (_db.update(_db.vaultEntries)..where((t) => t.id.equals(id)))
        .write(const VaultEntriesCompanion(isDirty: Value(0)));
  }

  Future<void> softDelete(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.vaultEntries)..where((t) => t.id.equals(id)))
        .write(VaultEntriesCompanion(
      deletedAt: Value(now),
      isDirty: const Value(1),
    ));
  }

  Future<List<VaultEntryData>> getDirtyEntries(String userId) {
    return (_db.select(_db.vaultEntries)
          ..where((t) => t.userId.equals(userId) & t.isDirty.equals(1)))
        .get();
  }

  // ─────────────────────────── Decrypt ──────────────────────────────

  Future<VaultEntry> _decrypt(VaultEntryData row) async {
    final title = await _c.decryptToString(row.titleEnc);
    final url =
        row.urlEnc != null ? await _c.decryptToString(row.urlEnc!) : null;
    final content = await _c.decryptToString(row.contentEnc);

    return VaultEntry(
      id: row.id,
      userId: row.userId,
      title: title,
      url: url,
      content: content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
      deletedAt: row.deletedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
          : null,
      serverRev: row.serverRev,
    );
  }
}
