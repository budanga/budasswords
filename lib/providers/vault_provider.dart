import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/vault_entry.dart';
import '../data/local/daos/vault_dao.dart';
import '../data/remote/supabase_vault_api.dart';
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
}

final vaultNotifierProvider =
    StateNotifierProvider<VaultNotifier, AsyncValue<void>>((ref) {
  final dao    = ref.watch(vaultDaoProvider);
  final api    = ref.watch(supabaseVaultApiProvider);
  final auth   = ref.watch(authProvider);
  final userId = auth.session?.userId ?? '';
  return VaultNotifier(dao, api, userId);
});
