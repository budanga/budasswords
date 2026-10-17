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
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch()
        .asyncMap((rows) async {
      final result = <VaultEntry>[];
      for (final row in rows) {
        try {
          final entry = await _decrypt(row);
          if (userId.isNotEmpty && row.userId != userId) {
            // Auto-migrate legacy or offline entries to current user ID
            await (_db.update(_db.vaultEntries)..where((t) => t.id.equals(row.id)))
                .write(VaultEntriesCompanion(
              userId: Value(userId),
              isDirty: const Value(1),
            ));
          }
          result.add(entry);
        } catch (_) {
          // Skip entry if it cannot be decrypted with the current master key
        }
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
  /// A pending local edit is kept unless the remote copy is strictly newer.
  Future<void> upsertRaw(VaultEntriesCompanion companion) async {
    final local = await (_db.select(_db.vaultEntries)
          ..where((t) => t.id.equals(companion.id.value)))
        .getSingleOrNull();
    if (local != null &&
        local.isDirty == 1 &&
        local.updatedAt >= companion.updatedAt.value) {
      return;
    }
    await _db.into(_db.vaultEntries).insertOnConflictUpdate(
          companion.copyWith(isDirty: const Value(0)),
        );
  }

  Future<void> markClean(String id) async {
    await (_db.update(_db.vaultEntries)..where((t) => t.id.equals(id)))
        .write(const VaultEntriesCompanion(isDirty: Value(0)));
  }

  Future<void> softDelete(String id) async {
    await (_db.delete(_db.vaultEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> hardDelete(String id) async {
    await (_db.delete(_db.vaultEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Applies a deletion coming from the server; a pending local edit wins
  /// and will be re-uploaded on the next push.
  Future<void> deleteFromRemote(String id) async {
    await (_db.delete(_db.vaultEntries)
          ..where((t) => t.id.equals(id) & t.isDirty.equals(0)))
        .go();
  }

  Future<List<VaultEntryData>> getDirtyEntries(String userId) {
    return (_db.select(_db.vaultEntries)
          ..where((t) => (t.userId.equals(userId) | t.userId.equals('offline')) & t.isDirty.equals(1)))
        .get();
  }

  /// Migrates entries belonging to offline or another user ID to the new user ID and marks them dirty.
  Future<void> migrateUserId(String newUserId) async {
    await (_db.update(_db.vaultEntries)
          ..where((t) => t.userId.equals(newUserId).not() | t.userId.equals('offline')))
        .write(VaultEntriesCompanion(
      userId: Value(newUserId),
      isDirty: const Value(1),
    ));
  }

  /// Returns all active local entries for the specified user (including offline entries).
  Future<List<VaultEntryData>> getActiveEntries(String userId) {
    return (_db.select(_db.vaultEntries)
          ..where((t) => (t.userId.equals(userId) | t.userId.equals('offline')) & t.deletedAt.isNull()))
        .get();
  }

  /// Records a deletion operation in the sync queue for offline sync.
  Future<void> queueDelete(String id) async {
    await _db.into(_db.syncQueue).insert(
          SyncQueueCompanion.insert(
            entryId: id,
            operation: 'delete',
            payload: Uint8List(0),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
  }

  Future<List<SyncQueueData>> getPendingDeletes() {
    return (_db.select(_db.syncQueue)..where((t) => t.operation.equals('delete'))).get();
  }

  Future<void> clearPendingDelete(int id) async {
    await (_db.delete(_db.syncQueue)..where((t) => t.id.equals(id))).go();
  }

  /// Returns all active local entries regardless of dirty flag (for full cloud migration/sync).
  Future<List<VaultEntryData>> getAllActiveEntries() {
    return (_db.select(_db.vaultEntries)
          ..where((t) => t.deletedAt.isNull()))
        .get();
  }

  /// Clears all local vault and sync entries (used on logout/reset).
  Future<void> clearAll() async {
    await _db.delete(_db.vaultEntries).go();
    await _db.delete(_db.syncQueue).go();
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
