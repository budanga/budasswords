import 'package:drift/drift.dart';

/// Queue of sync operations that need to be uploaded to Supabase.
class SyncQueue extends Table {
  IntColumn  get id        => integer().autoIncrement()();
  TextColumn get entryId   => text()();
  TextColumn get operation => text()(); // 'upsert' | 'delete'
  BlobColumn get payload   => blob()();
  IntColumn  get createdAt => integer()(); // Unix ms
}
