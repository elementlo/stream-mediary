import 'package:drift/drift.dart';

/// Persisted download task.
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get title => text()();
  IntColumn get status => integer()();
  TextColumn get headers => text().withDefault(const Constant('{}'))();
  TextColumn get customKey => text().nullable()();
  TextColumn get customIv => text().nullable()();
  TextColumn get variantJson => text().nullable()();
  TextColumn get playlistSnapshot => text().nullable()();
  TextColumn get saveDir => text()();
  TextColumn get outputPath => text().nullable()();
  IntColumn get totalSegments => integer().withDefault(const Constant(0))();
  IntColumn get doneSegments => integer().withDefault(const Constant(0))();
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();
  IntColumn get downloadedBytes =>
      integer().withDefault(const Constant(0))();
  TextColumn get errorMsg => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Persisted segment state for resume support.
class Segments extends Table {
  TextColumn get taskId => text()();
  IntColumn get seq => integer()();
  TextColumn get url => text()();
  IntColumn get status => integer().withDefault(const Constant(0))();
  IntColumn get byteSize => integer().withDefault(const Constant(0))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {taskId, seq};
}

/// Key-value settings store.
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
