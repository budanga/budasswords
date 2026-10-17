import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/vault_entries_table.dart';
import 'tables/sync_queue_table.dart';

part 'database.g.dart';

/// Drift database — generates DAOs and query classes via build_runner.
@DriftDatabase(tables: [VaultEntries, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Opens the database on a custom executor (e.g. in-memory for tests).
  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'budasswords.db'));
    return NativeDatabase.createInBackground(file);
  });
}
