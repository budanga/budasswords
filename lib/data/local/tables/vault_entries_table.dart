import 'package:drift/drift.dart';

/// Drift table definition for local vault entry storage.
/// All sensitive columns are stored as encrypted blobs.
@DataClassName("VaultEntryData")
class VaultEntries extends Table {
  TextColumn get id          => text()();
  TextColumn get userId      => text()();
  BlobColumn get titleEnc    => blob()();
  BlobColumn get urlEnc      => blob().nullable()();
  BlobColumn get contentEnc  => blob()();
  BlobColumn get iv          => blob()();
  IntColumn  get createdAt   => integer()();  // Unix ms
  IntColumn  get updatedAt   => integer()();
  IntColumn  get deletedAt   => integer().nullable()();
  IntColumn  get serverRev   => integer().withDefault(const Constant(0))();
  IntColumn  get isDirty     => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
