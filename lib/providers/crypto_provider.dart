import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/database.dart';
import '../data/local/daos/vault_dao.dart';
import '../data/remote/supabase_vault_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

final supabaseVaultApiProvider = Provider<SupabaseVaultApi>((ref) {
  return SupabaseVaultApi(Supabase.instance.client);
});
