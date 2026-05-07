import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/vault_entry.dart';
import '../data/local/daos/vault_dao.dart';
import '../data/local/database.dart';
import '../data/remote/supabase_vault_api.dart';
import '../crypto/crypto_utils.dart';
import 'package:drift/drift.dart';
import 'dart:typed_data';
import 'auth_provider.dart';
import 'crypto_provider.dart';

// ──────────────────────────────────────────────────
// Vault entries stream
// ──────────────────────────────────────────────────

final vaultEntriesProvider = StreamProvider<List<VaultEntry>>((ref) {
  final auth  = ref.watch(authProvider);
  if (auth.status != AuthStatus.unlocked || auth.session == null) {
    return const Stream.empty();
  }
  final dao = ref.watch(vaultDaoProvider);
  return dao.watchAll(auth.session!.userId);
});

// ──────────────────────────────────────────────────
// Search query
// ──────────────────────────────────────────────────

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredEntriesProvider = Provider<AsyncValue<List<VaultEntry>>>((ref) {
  final query   = ref.watch(searchQueryProvider).toLowerCase();
  final entries = ref.watch(vaultEntriesProvider);
  return entries.whenData((list) {
    if (query.isEmpty) return list;
    return list.where((e) {
      return e.title.toLowerCase().contains(query) ||
          (e.url?.toLowerCase().contains(query) ?? false) ||
          e.content.toLowerCase().contains(query);
    }).toList();
  });
});

// ──────────────────────────────────────────────────
// Vault actions notifier
// ──────────────────────────────────────────────────

class VaultNotifier extends StateNotifier<AsyncValue<void>> {
  final VaultDao _dao;
  final SupabaseVaultApi _api;
  final String _userId;

  VaultNotifier(this._dao, this._api, this._userId)
      : super(const AsyncData(null));

  static const _uuid = Uuid();

  Future<void> createEntry({
    required String title,
    String? url,
    required String content,
  }) async {
    state = const AsyncLoading();
    try {
      final entry = VaultEntry(
        id:        _uuid.v4(),
        userId:    _userId,
        title:     title,
        url:       url?.isEmpty == true ? null : url,
        content:   content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dao.upsertEntry(entry);
      await _syncEntry(entry);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateEntry(VaultEntry entry) async {
    state = const AsyncLoading();
    try {
      final updated = entry.copyWith(updatedAt: DateTime.now());
      await _dao.upsertEntry(updated);
      await _syncEntry(updated);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteEntry(String id) async {
    state = const AsyncLoading();
    try {
      await _dao.softDelete(id);
      await _api.softDelete(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _syncEntry(VaultEntry entry) async {
    try {
      // We upload the encrypted blobs from the local row
      final dirty = await _dao.getDirtyEntries(_userId);
      final row = dirty.where((r) => r.id == entry.id).firstOrNull;
      if (row == null) return;

      await _api.upsert({
        'id':          row.id,
        'user_id':     row.userId,
        'title_enc':   row.titleEnc,
        'url_enc':     row.urlEnc,
        'content_enc': row.contentEnc,
        'iv':          row.iv,
        'created_at':  DateTime.fromMillisecondsSinceEpoch(row.createdAt).toIso8601String(),
        'updated_at':  DateTime.fromMillisecondsSinceEpoch(row.updatedAt).toIso8601String(),
        'deleted_at':  row.deletedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!).toIso8601String()
            : null,
        'server_rev':  row.serverRev,
      });
      await _dao.markClean(row.id);
    } catch (_) {
      // Offline — will retry on next sync cycle
    }
  }

  Future<void> pullFromRemote() async {
    state = const AsyncLoading();
    try {
      final remoteData = await _api.fetchAll(_userId);
      for (final row in remoteData) {
        // Map Supabase Map to Drift Companion
        final companion = VaultEntriesCompanion(
          id: Value(row['id'] as String),
          userId: Value(row['user_id'] as String),
          titleEnc: Value(_parseBlob(row['title_enc'])),
          urlEnc: Value(row['url_enc'] != null
              ? _parseBlob(row['url_enc'])
              : null),
          contentEnc: Value(_parseBlob(row['content_enc'])),
          iv: Value(_parseBlob(row['iv'])),
          createdAt: Value(
              DateTime.parse(row['created_at']).millisecondsSinceEpoch),
          updatedAt: Value(
              DateTime.parse(row['updated_at']).millisecondsSinceEpoch),
          deletedAt: Value(row['deleted_at'] != null
              ? DateTime.parse(row['deleted_at']).millisecondsSinceEpoch
              : null),
          serverRev: Value(row['server_rev'] as int? ?? 1),
        );
        await _dao.upsertRaw(companion);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Uint8List _parseBlob(dynamic data) {
    if (data == null) return Uint8List(0);
    if (data is Uint8List) return data;
    if (data is List) return Uint8List.fromList(List<int>.from(data));
    if (data is String) {
      final hex = data.startsWith('\\x') ? data.substring(2) : data;
      return CryptoUtils.fromHex(hex);
    }
    return Uint8List(0);
  }
}

final vaultNotifierProvider =
    StateNotifierProvider<VaultNotifier, AsyncValue<void>>((ref) {
  final dao    = ref.watch(vaultDaoProvider);
  final api    = ref.watch(supabaseVaultApiProvider);
  final auth   = ref.watch(authProvider);
  final userId = auth.session?.userId ?? '';
  
  final notifier = VaultNotifier(dao, api, userId);
  
  // Trigger initial sync if unlocked
  if (auth.status == AuthStatus.unlocked && userId.isNotEmpty) {
    Future.microtask(() => notifier.pullFromRemote());
  }
  
  return notifier;
});
