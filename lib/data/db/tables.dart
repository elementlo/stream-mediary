import 'package:drift/drift.dart';

/// Persisted download task.
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get sourceUrl => text().nullable()();
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
  IntColumn get downloadedBytes => integer().withDefault(const Constant(0))();
  TextColumn get errorMsg => text().nullable()();
  IntColumn get playbackMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  IntColumn get queueOrder => integer().withDefault(const Constant(0))();
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

/// Cached message-board comments so the board renders instantly from disk
/// while a silent refresh runs in the background.
class BoardComments extends Table {
  TextColumn get objectId => text()();
  TextColumn get comment => text()();
  TextColumn get nick => text()();
  IntColumn get insertedAt => integer()();
  TextColumn get rid => text().nullable()();
  TextColumn get link => text().nullable()();
  TextColumn get avatar => text().nullable()();

  /// Province-level IP region shown next to the timestamp.
  TextColumn get addr => text().nullable()();

  /// Registered-user role (e.g. "administrator"); null for anonymous.
  TextColumn get type => text().nullable()();

  /// Admin-set badge text (e.g. "admin"); null for anonymous.
  TextColumn get label => text().nullable()();

  /// Sort order within the cached page set (server order, newest first).
  IntColumn get sortIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {objectId};
}
