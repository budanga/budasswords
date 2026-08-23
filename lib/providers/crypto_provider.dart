import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/local/daos/vault_dao.dart';
import '../data/remote/firebase_vault_api.dart';

// ──────────────────────────────────────────────────
// Infrastructure providers
// ──────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final vaultDaoProvider = Provider<VaultDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return VaultDao(db);
});

final firebaseVaultApiProvider = Provider<FirebaseVaultApi>((ref) {
  return FirebaseVaultApi();
});

