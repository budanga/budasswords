import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/vault_entry.dart';
import '../data/local/daos/vault_dao.dart';
import '../data/local/database.dart';
import '../data/remote/firebase_vault_api.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../crypto/crypto_utils.dart';
import 'package:drift/drift.dart';
import 'auth_provider.dart';
import 'crypto_provider.dart';
import 'pinned_provider.dart';

// ──────────────────────────────────────────────────
// Vault entries stream
// ──────────────────────────────────────────────────

final vaultEntriesProvider = StreamProvider<List<VaultEntry>>((ref) {
  final auth = ref.watch(authProvider);
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
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final entriesAsync = ref.watch(vaultEntriesProvider);
  final pinned = ref.watch(pinnedProvider);

  return entriesAsync.whenData((list) {
    var filtered = List<VaultEntry>.from(list);
    
    if (query.isNotEmpty) {
      filtered = filtered.where((e) {
        return e.title.toLowerCase().contains(query) ||
            (e.url?.toLowerCase().contains(query) ?? false) ||
            e.content.toLowerCase().contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      final aPinned = pinned[a.id];
      final bPinned = pinned[b.id];
      
      if (aPinned != null && bPinned != null) {
        return bPinned.compareTo(aPinned); // Most recently pinned first
      } else if (aPinned != null) {
        return -1;
      } else if (bPinned != null) {
        return 1;
      } else {
        int cmp = b.updatedAt.compareTo(a.updatedAt);
        if (cmp == 0) {
          cmp = b.createdAt.compareTo(a.createdAt);
        }
        if (cmp == 0) {
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        }
        return cmp;
      }
    });

    return filtered;
  });
});

// ──────────────────────────────────────────────────
// Vault actions notifier
// ──────────────────────────────────────────────────

class VaultNotifier extends StateNotifier<AsyncValue<void>> {
  final VaultDao _dao;
  final FirebaseVaultApi _api;
  final String _userId;

  StreamSubscription? _subscription;

  bool get _canSyncRemote {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.uid == _userId && _userId.isNotEmpty;
  }

  VaultNotifier(this._dao, this._api, this._userId)
      : super(const AsyncData(null)) {
    if (_canSyncRemote) {
      _subscription = _api.watchChanges(_userId, (remoteData) async {
        try {
          for (final row in remoteData) {
            final id = row['id'] as String;
            if (row['deleted_at'] != null) {
              await _dao.hardDelete(id);
              await _api.delete(_userId, id);
              continue;
            }
            final companion = VaultEntriesCompanion(
              id: Value(id),
              userId: Value(row['user_id'] as String),
              titleEnc: Value(_parseBlob(row['title_enc'])),
              urlEnc: Value(
                  row['url_enc'] != null ? _parseBlob(row['url_enc']) : null),
              contentEnc: Value(_parseBlob(row['content_enc'])),
              iv: Value(_parseBlob(row['iv'])),
              createdAt: Value(
                  DateTime.parse(row['created_at']).millisecondsSinceEpoch),
              updatedAt: Value(
                  DateTime.parse(row['updated_at']).millisecondsSinceEpoch),
              deletedAt: const Value(null),
              serverRev: Value(row['server_rev'] as int? ?? 1),
            );
            await _dao.upsertRaw(companion);
          }
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  static const _uuid = Uuid();

  Future<void> createEntry({
    required String title,
    String? url,
    required String content,
  }) async {
    state = const AsyncLoading();
    try {
      final entry = VaultEntry(
        id: _uuid.v4(),
        userId: _userId,
        title: title,
        url: url?.isEmpty == true ? null : url,
        content: content,
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
      await _dao.hardDelete(id);
      if (_canSyncRemote) {
        await _api.delete(_userId, id);
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> _syncEntry(VaultEntry entry) async {
    if (_canSyncRemote) {
      await pushDirtyToRemote();
      await pullFromRemote();
    }
  }

  Future<void> pushDirtyToRemote() async {
    if (!_canSyncRemote) return;
    try {
      final dirty = await _dao.getDirtyEntries(_userId);
      for (final row in dirty) {
        try {
          await _api.upsert({
            'id': row.id,
            'user_id': _userId,
            'title_enc': CryptoUtils.toHex(row.titleEnc),
            'url_enc': row.urlEnc != null
                ? CryptoUtils.toHex(row.urlEnc!)
                : null,
            'content_enc': CryptoUtils.toHex(row.contentEnc),
            'iv': CryptoUtils.toHex(row.iv),
            'created_at': DateTime.fromMillisecondsSinceEpoch(row.createdAt)
                .toIso8601String(),
            'updated_at': DateTime.fromMillisecondsSinceEpoch(row.updatedAt)
                .toIso8601String(),
            'deleted_at': row.deletedAt != null
                ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
                    .toIso8601String()
                : null,
            'server_rev': row.serverRev,
          });
          await _dao.markClean(row.id);
        } catch (_) {
          // Keep trying other rows
        }
      }
    } catch (_) {
      // Offline or sync error
    }
  }

  Future<void> pushAllToRemote() async {
    if (!_canSyncRemote) return;
    try {
      final all = await _dao.getAllActiveEntries();
      for (final row in all) {
        try {
          await _api.upsert({
            'id': row.id,
            'user_id': _userId,
            'title_enc': CryptoUtils.toHex(row.titleEnc),
            'url_enc': row.urlEnc != null
                ? CryptoUtils.toHex(row.urlEnc!)
                : null,
            'content_enc': CryptoUtils.toHex(row.contentEnc),
            'iv': CryptoUtils.toHex(row.iv),
            'created_at': DateTime.fromMillisecondsSinceEpoch(row.createdAt)
                .toIso8601String(),
            'updated_at': DateTime.fromMillisecondsSinceEpoch(row.updatedAt)
                .toIso8601String(),
            'deleted_at': row.deletedAt != null
                ? DateTime.fromMillisecondsSinceEpoch(row.deletedAt!)
                    .toIso8601String()
                : null,
            'server_rev': row.serverRev,
          });
          await _dao.markClean(row.id);
        } catch (_) {
          // Keep trying other rows
        }
      }
    } catch (_) {
      // Offline or sync error
    }
  }

  Future<void> pullFromRemote() async {
    if (!_canSyncRemote) {
      state = const AsyncData(null);
      return;
    }
    state = const AsyncLoading();
    try {
      final remoteData = await _api.fetchAll(_userId);
      for (final row in remoteData) {
        final id = row['id'] as String;
        if (row['deleted_at'] != null) {
          await _dao.hardDelete(id);
          await _api.delete(_userId, id);
          continue;
        }
        final companion = VaultEntriesCompanion(
          id: Value(id),
          userId: Value(row['user_id'] as String),
          titleEnc: Value(_parseBlob(row['title_enc'])),
          urlEnc:
              Value(row['url_enc'] != null ? _parseBlob(row['url_enc']) : null),
          contentEnc: Value(_parseBlob(row['content_enc'])),
          iv: Value(_parseBlob(row['iv'])),
          createdAt:
              Value(DateTime.parse(row['created_at']).millisecondsSinceEpoch),
          updatedAt:
              Value(DateTime.parse(row['updated_at']).millisecondsSinceEpoch),
          deletedAt: const Value(null),
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
  final dao = ref.watch(vaultDaoProvider);
  final api = ref.watch(firebaseVaultApiProvider);
  final auth = ref.watch(authProvider);
  final userId = auth.session?.userId ?? '';

  final notifier = VaultNotifier(dao, api, userId);

  // Trigger initial sync if unlocked and authenticated with Firebase
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (auth.status == AuthStatus.unlocked &&
      userId.isNotEmpty &&
      firebaseUser != null &&
      firebaseUser.uid == userId) {
    Future.microtask(() async {
      await notifier.pushDirtyToRemote();
      await notifier.pullFromRemote();
    });
  }

  return notifier;
});


