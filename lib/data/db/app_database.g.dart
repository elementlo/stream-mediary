// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headersMeta = const VerificationMeta(
    'headers',
  );
  @override
  late final GeneratedColumn<String> headers = GeneratedColumn<String>(
    'headers',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _customKeyMeta = const VerificationMeta(
    'customKey',
  );
  @override
  late final GeneratedColumn<String> customKey = GeneratedColumn<String>(
    'custom_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customIvMeta = const VerificationMeta(
    'customIv',
  );
  @override
  late final GeneratedColumn<String> customIv = GeneratedColumn<String>(
    'custom_iv',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantJsonMeta = const VerificationMeta(
    'variantJson',
  );
  @override
  late final GeneratedColumn<String> variantJson = GeneratedColumn<String>(
    'variant_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playlistSnapshotMeta = const VerificationMeta(
    'playlistSnapshot',
  );
  @override
  late final GeneratedColumn<String> playlistSnapshot = GeneratedColumn<String>(
    'playlist_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _saveDirMeta = const VerificationMeta(
    'saveDir',
  );
  @override
  late final GeneratedColumn<String> saveDir = GeneratedColumn<String>(
    'save_dir',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outputPathMeta = const VerificationMeta(
    'outputPath',
  );
  @override
  late final GeneratedColumn<String> outputPath = GeneratedColumn<String>(
    'output_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalSegmentsMeta = const VerificationMeta(
    'totalSegments',
  );
  @override
  late final GeneratedColumn<int> totalSegments = GeneratedColumn<int>(
    'total_segments',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _doneSegmentsMeta = const VerificationMeta(
    'doneSegments',
  );
  @override
  late final GeneratedColumn<int> doneSegments = GeneratedColumn<int>(
    'done_segments',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _downloadedBytesMeta = const VerificationMeta(
    'downloadedBytes',
  );
  @override
  late final GeneratedColumn<int> downloadedBytes = GeneratedColumn<int>(
    'downloaded_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMsgMeta = const VerificationMeta(
    'errorMsg',
  );
  @override
  late final GeneratedColumn<String> errorMsg = GeneratedColumn<String>(
    'error_msg',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    url,
    title,
    status,
    headers,
    customKey,
    customIv,
    variantJson,
    playlistSnapshot,
    saveDir,
    outputPath,
    totalSegments,
    doneSegments,
    totalBytes,
    downloadedBytes,
    errorMsg,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('headers')) {
      context.handle(
        _headersMeta,
        headers.isAcceptableOrUnknown(data['headers']!, _headersMeta),
      );
    }
    if (data.containsKey('custom_key')) {
      context.handle(
        _customKeyMeta,
        customKey.isAcceptableOrUnknown(data['custom_key']!, _customKeyMeta),
      );
    }
    if (data.containsKey('custom_iv')) {
      context.handle(
        _customIvMeta,
        customIv.isAcceptableOrUnknown(data['custom_iv']!, _customIvMeta),
      );
    }
    if (data.containsKey('variant_json')) {
      context.handle(
        _variantJsonMeta,
        variantJson.isAcceptableOrUnknown(
          data['variant_json']!,
          _variantJsonMeta,
        ),
      );
    }
    if (data.containsKey('playlist_snapshot')) {
      context.handle(
        _playlistSnapshotMeta,
        playlistSnapshot.isAcceptableOrUnknown(
          data['playlist_snapshot']!,
          _playlistSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('save_dir')) {
      context.handle(
        _saveDirMeta,
        saveDir.isAcceptableOrUnknown(data['save_dir']!, _saveDirMeta),
      );
    } else if (isInserting) {
      context.missing(_saveDirMeta);
    }
    if (data.containsKey('output_path')) {
      context.handle(
        _outputPathMeta,
        outputPath.isAcceptableOrUnknown(data['output_path']!, _outputPathMeta),
      );
    }
    if (data.containsKey('total_segments')) {
      context.handle(
        _totalSegmentsMeta,
        totalSegments.isAcceptableOrUnknown(
          data['total_segments']!,
          _totalSegmentsMeta,
        ),
      );
    }
    if (data.containsKey('done_segments')) {
      context.handle(
        _doneSegmentsMeta,
        doneSegments.isAcceptableOrUnknown(
          data['done_segments']!,
          _doneSegmentsMeta,
        ),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('downloaded_bytes')) {
      context.handle(
        _downloadedBytesMeta,
        downloadedBytes.isAcceptableOrUnknown(
          data['downloaded_bytes']!,
          _downloadedBytesMeta,
        ),
      );
    }
    if (data.containsKey('error_msg')) {
      context.handle(
        _errorMsgMeta,
        errorMsg.isAcceptableOrUnknown(data['error_msg']!, _errorMsgMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      headers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers'],
      )!,
      customKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_key'],
      ),
      customIv: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_iv'],
      ),
      variantJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_json'],
      ),
      playlistSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_snapshot'],
      ),
      saveDir: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}save_dir'],
      )!,
      outputPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}output_path'],
      ),
      totalSegments: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_segments'],
      )!,
      doneSegments: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}done_segments'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      downloadedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}downloaded_bytes'],
      )!,
      errorMsg: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_msg'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String url;
  final String title;
  final int status;
  final String headers;
  final String? customKey;
  final String? customIv;
  final String? variantJson;
  final String? playlistSnapshot;
  final String saveDir;
  final String? outputPath;
  final int totalSegments;
  final int doneSegments;
  final int totalBytes;
  final int downloadedBytes;
  final String? errorMsg;
  final int createdAt;
  final int updatedAt;
  const Task({
    required this.id,
    required this.url,
    required this.title,
    required this.status,
    required this.headers,
    this.customKey,
    this.customIv,
    this.variantJson,
    this.playlistSnapshot,
    required this.saveDir,
    this.outputPath,
    required this.totalSegments,
    required this.doneSegments,
    required this.totalBytes,
    required this.downloadedBytes,
    this.errorMsg,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['url'] = Variable<String>(url);
    map['title'] = Variable<String>(title);
    map['status'] = Variable<int>(status);
    map['headers'] = Variable<String>(headers);
    if (!nullToAbsent || customKey != null) {
      map['custom_key'] = Variable<String>(customKey);
    }
    if (!nullToAbsent || customIv != null) {
      map['custom_iv'] = Variable<String>(customIv);
    }
    if (!nullToAbsent || variantJson != null) {
      map['variant_json'] = Variable<String>(variantJson);
    }
    if (!nullToAbsent || playlistSnapshot != null) {
      map['playlist_snapshot'] = Variable<String>(playlistSnapshot);
    }
    map['save_dir'] = Variable<String>(saveDir);
    if (!nullToAbsent || outputPath != null) {
      map['output_path'] = Variable<String>(outputPath);
    }
    map['total_segments'] = Variable<int>(totalSegments);
    map['done_segments'] = Variable<int>(doneSegments);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['downloaded_bytes'] = Variable<int>(downloadedBytes);
    if (!nullToAbsent || errorMsg != null) {
      map['error_msg'] = Variable<String>(errorMsg);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      url: Value(url),
      title: Value(title),
      status: Value(status),
      headers: Value(headers),
      customKey: customKey == null && nullToAbsent
          ? const Value.absent()
          : Value(customKey),
      customIv: customIv == null && nullToAbsent
          ? const Value.absent()
          : Value(customIv),
      variantJson: variantJson == null && nullToAbsent
          ? const Value.absent()
          : Value(variantJson),
      playlistSnapshot: playlistSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(playlistSnapshot),
      saveDir: Value(saveDir),
      outputPath: outputPath == null && nullToAbsent
          ? const Value.absent()
          : Value(outputPath),
      totalSegments: Value(totalSegments),
      doneSegments: Value(doneSegments),
      totalBytes: Value(totalBytes),
      downloadedBytes: Value(downloadedBytes),
      errorMsg: errorMsg == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMsg),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      url: serializer.fromJson<String>(json['url']),
      title: serializer.fromJson<String>(json['title']),
      status: serializer.fromJson<int>(json['status']),
      headers: serializer.fromJson<String>(json['headers']),
      customKey: serializer.fromJson<String?>(json['customKey']),
      customIv: serializer.fromJson<String?>(json['customIv']),
      variantJson: serializer.fromJson<String?>(json['variantJson']),
      playlistSnapshot: serializer.fromJson<String?>(json['playlistSnapshot']),
      saveDir: serializer.fromJson<String>(json['saveDir']),
      outputPath: serializer.fromJson<String?>(json['outputPath']),
      totalSegments: serializer.fromJson<int>(json['totalSegments']),
      doneSegments: serializer.fromJson<int>(json['doneSegments']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      downloadedBytes: serializer.fromJson<int>(json['downloadedBytes']),
      errorMsg: serializer.fromJson<String?>(json['errorMsg']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'url': serializer.toJson<String>(url),
      'title': serializer.toJson<String>(title),
      'status': serializer.toJson<int>(status),
      'headers': serializer.toJson<String>(headers),
      'customKey': serializer.toJson<String?>(customKey),
      'customIv': serializer.toJson<String?>(customIv),
      'variantJson': serializer.toJson<String?>(variantJson),
      'playlistSnapshot': serializer.toJson<String?>(playlistSnapshot),
      'saveDir': serializer.toJson<String>(saveDir),
      'outputPath': serializer.toJson<String?>(outputPath),
      'totalSegments': serializer.toJson<int>(totalSegments),
      'doneSegments': serializer.toJson<int>(doneSegments),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'downloadedBytes': serializer.toJson<int>(downloadedBytes),
      'errorMsg': serializer.toJson<String?>(errorMsg),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Task copyWith({
    String? id,
    String? url,
    String? title,
    int? status,
    String? headers,
    Value<String?> customKey = const Value.absent(),
    Value<String?> customIv = const Value.absent(),
    Value<String?> variantJson = const Value.absent(),
    Value<String?> playlistSnapshot = const Value.absent(),
    String? saveDir,
    Value<String?> outputPath = const Value.absent(),
    int? totalSegments,
    int? doneSegments,
    int? totalBytes,
    int? downloadedBytes,
    Value<String?> errorMsg = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => Task(
    id: id ?? this.id,
    url: url ?? this.url,
    title: title ?? this.title,
    status: status ?? this.status,
    headers: headers ?? this.headers,
    customKey: customKey.present ? customKey.value : this.customKey,
    customIv: customIv.present ? customIv.value : this.customIv,
    variantJson: variantJson.present ? variantJson.value : this.variantJson,
    playlistSnapshot: playlistSnapshot.present
        ? playlistSnapshot.value
        : this.playlistSnapshot,
    saveDir: saveDir ?? this.saveDir,
    outputPath: outputPath.present ? outputPath.value : this.outputPath,
    totalSegments: totalSegments ?? this.totalSegments,
    doneSegments: doneSegments ?? this.doneSegments,
    totalBytes: totalBytes ?? this.totalBytes,
    downloadedBytes: downloadedBytes ?? this.downloadedBytes,
    errorMsg: errorMsg.present ? errorMsg.value : this.errorMsg,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      status: data.status.present ? data.status.value : this.status,
      headers: data.headers.present ? data.headers.value : this.headers,
      customKey: data.customKey.present ? data.customKey.value : this.customKey,
      customIv: data.customIv.present ? data.customIv.value : this.customIv,
      variantJson: data.variantJson.present
          ? data.variantJson.value
          : this.variantJson,
      playlistSnapshot: data.playlistSnapshot.present
          ? data.playlistSnapshot.value
          : this.playlistSnapshot,
      saveDir: data.saveDir.present ? data.saveDir.value : this.saveDir,
      outputPath: data.outputPath.present
          ? data.outputPath.value
          : this.outputPath,
      totalSegments: data.totalSegments.present
          ? data.totalSegments.value
          : this.totalSegments,
      doneSegments: data.doneSegments.present
          ? data.doneSegments.value
          : this.doneSegments,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      downloadedBytes: data.downloadedBytes.present
          ? data.downloadedBytes.value
          : this.downloadedBytes,
      errorMsg: data.errorMsg.present ? data.errorMsg.value : this.errorMsg,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('headers: $headers, ')
          ..write('customKey: $customKey, ')
          ..write('customIv: $customIv, ')
          ..write('variantJson: $variantJson, ')
          ..write('playlistSnapshot: $playlistSnapshot, ')
          ..write('saveDir: $saveDir, ')
          ..write('outputPath: $outputPath, ')
          ..write('totalSegments: $totalSegments, ')
          ..write('doneSegments: $doneSegments, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('errorMsg: $errorMsg, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    url,
    title,
    status,
    headers,
    customKey,
    customIv,
    variantJson,
    playlistSnapshot,
    saveDir,
    outputPath,
    totalSegments,
    doneSegments,
    totalBytes,
    downloadedBytes,
    errorMsg,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.url == this.url &&
          other.title == this.title &&
          other.status == this.status &&
          other.headers == this.headers &&
          other.customKey == this.customKey &&
          other.customIv == this.customIv &&
          other.variantJson == this.variantJson &&
          other.playlistSnapshot == this.playlistSnapshot &&
          other.saveDir == this.saveDir &&
          other.outputPath == this.outputPath &&
          other.totalSegments == this.totalSegments &&
          other.doneSegments == this.doneSegments &&
          other.totalBytes == this.totalBytes &&
          other.downloadedBytes == this.downloadedBytes &&
          other.errorMsg == this.errorMsg &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> url;
  final Value<String> title;
  final Value<int> status;
  final Value<String> headers;
  final Value<String?> customKey;
  final Value<String?> customIv;
  final Value<String?> variantJson;
  final Value<String?> playlistSnapshot;
  final Value<String> saveDir;
  final Value<String?> outputPath;
  final Value<int> totalSegments;
  final Value<int> doneSegments;
  final Value<int> totalBytes;
  final Value<int> downloadedBytes;
  final Value<String?> errorMsg;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.status = const Value.absent(),
    this.headers = const Value.absent(),
    this.customKey = const Value.absent(),
    this.customIv = const Value.absent(),
    this.variantJson = const Value.absent(),
    this.playlistSnapshot = const Value.absent(),
    this.saveDir = const Value.absent(),
    this.outputPath = const Value.absent(),
    this.totalSegments = const Value.absent(),
    this.doneSegments = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.errorMsg = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String url,
    required String title,
    required int status,
    this.headers = const Value.absent(),
    this.customKey = const Value.absent(),
    this.customIv = const Value.absent(),
    this.variantJson = const Value.absent(),
    this.playlistSnapshot = const Value.absent(),
    required String saveDir,
    this.outputPath = const Value.absent(),
    this.totalSegments = const Value.absent(),
    this.doneSegments = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.downloadedBytes = const Value.absent(),
    this.errorMsg = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       url = Value(url),
       title = Value(title),
       status = Value(status),
       saveDir = Value(saveDir),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? url,
    Expression<String>? title,
    Expression<int>? status,
    Expression<String>? headers,
    Expression<String>? customKey,
    Expression<String>? customIv,
    Expression<String>? variantJson,
    Expression<String>? playlistSnapshot,
    Expression<String>? saveDir,
    Expression<String>? outputPath,
    Expression<int>? totalSegments,
    Expression<int>? doneSegments,
    Expression<int>? totalBytes,
    Expression<int>? downloadedBytes,
    Expression<String>? errorMsg,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (status != null) 'status': status,
      if (headers != null) 'headers': headers,
      if (customKey != null) 'custom_key': customKey,
      if (customIv != null) 'custom_iv': customIv,
      if (variantJson != null) 'variant_json': variantJson,
      if (playlistSnapshot != null) 'playlist_snapshot': playlistSnapshot,
      if (saveDir != null) 'save_dir': saveDir,
      if (outputPath != null) 'output_path': outputPath,
      if (totalSegments != null) 'total_segments': totalSegments,
      if (doneSegments != null) 'done_segments': doneSegments,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (downloadedBytes != null) 'downloaded_bytes': downloadedBytes,
      if (errorMsg != null) 'error_msg': errorMsg,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? url,
    Value<String>? title,
    Value<int>? status,
    Value<String>? headers,
    Value<String?>? customKey,
    Value<String?>? customIv,
    Value<String?>? variantJson,
    Value<String?>? playlistSnapshot,
    Value<String>? saveDir,
    Value<String?>? outputPath,
    Value<int>? totalSegments,
    Value<int>? doneSegments,
    Value<int>? totalBytes,
    Value<int>? downloadedBytes,
    Value<String?>? errorMsg,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      status: status ?? this.status,
      headers: headers ?? this.headers,
      customKey: customKey ?? this.customKey,
      customIv: customIv ?? this.customIv,
      variantJson: variantJson ?? this.variantJson,
      playlistSnapshot: playlistSnapshot ?? this.playlistSnapshot,
      saveDir: saveDir ?? this.saveDir,
      outputPath: outputPath ?? this.outputPath,
      totalSegments: totalSegments ?? this.totalSegments,
      doneSegments: doneSegments ?? this.doneSegments,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      errorMsg: errorMsg ?? this.errorMsg,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (headers.present) {
      map['headers'] = Variable<String>(headers.value);
    }
    if (customKey.present) {
      map['custom_key'] = Variable<String>(customKey.value);
    }
    if (customIv.present) {
      map['custom_iv'] = Variable<String>(customIv.value);
    }
    if (variantJson.present) {
      map['variant_json'] = Variable<String>(variantJson.value);
    }
    if (playlistSnapshot.present) {
      map['playlist_snapshot'] = Variable<String>(playlistSnapshot.value);
    }
    if (saveDir.present) {
      map['save_dir'] = Variable<String>(saveDir.value);
    }
    if (outputPath.present) {
      map['output_path'] = Variable<String>(outputPath.value);
    }
    if (totalSegments.present) {
      map['total_segments'] = Variable<int>(totalSegments.value);
    }
    if (doneSegments.present) {
      map['done_segments'] = Variable<int>(doneSegments.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (downloadedBytes.present) {
      map['downloaded_bytes'] = Variable<int>(downloadedBytes.value);
    }
    if (errorMsg.present) {
      map['error_msg'] = Variable<String>(errorMsg.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('status: $status, ')
          ..write('headers: $headers, ')
          ..write('customKey: $customKey, ')
          ..write('customIv: $customIv, ')
          ..write('variantJson: $variantJson, ')
          ..write('playlistSnapshot: $playlistSnapshot, ')
          ..write('saveDir: $saveDir, ')
          ..write('outputPath: $outputPath, ')
          ..write('totalSegments: $totalSegments, ')
          ..write('doneSegments: $doneSegments, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('downloadedBytes: $downloadedBytes, ')
          ..write('errorMsg: $errorMsg, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SegmentsTable extends Segments with TableInfo<$SegmentsTable, Segment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SegmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    taskId,
    seq,
    url,
    status,
    byteSize,
    retryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'segments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Segment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, seq};
  @override
  Segment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Segment(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
    );
  }

  @override
  $SegmentsTable createAlias(String alias) {
    return $SegmentsTable(attachedDatabase, alias);
  }
}

class Segment extends DataClass implements Insertable<Segment> {
  final String taskId;
  final int seq;
  final String url;
  final int status;
  final int byteSize;
  final int retryCount;
  const Segment({
    required this.taskId,
    required this.seq,
    required this.url,
    required this.status,
    required this.byteSize,
    required this.retryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['seq'] = Variable<int>(seq);
    map['url'] = Variable<String>(url);
    map['status'] = Variable<int>(status);
    map['byte_size'] = Variable<int>(byteSize);
    map['retry_count'] = Variable<int>(retryCount);
    return map;
  }

  SegmentsCompanion toCompanion(bool nullToAbsent) {
    return SegmentsCompanion(
      taskId: Value(taskId),
      seq: Value(seq),
      url: Value(url),
      status: Value(status),
      byteSize: Value(byteSize),
      retryCount: Value(retryCount),
    );
  }

  factory Segment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Segment(
      taskId: serializer.fromJson<String>(json['taskId']),
      seq: serializer.fromJson<int>(json['seq']),
      url: serializer.fromJson<String>(json['url']),
      status: serializer.fromJson<int>(json['status']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'seq': serializer.toJson<int>(seq),
      'url': serializer.toJson<String>(url),
      'status': serializer.toJson<int>(status),
      'byteSize': serializer.toJson<int>(byteSize),
      'retryCount': serializer.toJson<int>(retryCount),
    };
  }

  Segment copyWith({
    String? taskId,
    int? seq,
    String? url,
    int? status,
    int? byteSize,
    int? retryCount,
  }) => Segment(
    taskId: taskId ?? this.taskId,
    seq: seq ?? this.seq,
    url: url ?? this.url,
    status: status ?? this.status,
    byteSize: byteSize ?? this.byteSize,
    retryCount: retryCount ?? this.retryCount,
  );
  Segment copyWithCompanion(SegmentsCompanion data) {
    return Segment(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      seq: data.seq.present ? data.seq.value : this.seq,
      url: data.url.present ? data.url.value : this.url,
      status: data.status.present ? data.status.value : this.status,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Segment(')
          ..write('taskId: $taskId, ')
          ..write('seq: $seq, ')
          ..write('url: $url, ')
          ..write('status: $status, ')
          ..write('byteSize: $byteSize, ')
          ..write('retryCount: $retryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(taskId, seq, url, status, byteSize, retryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Segment &&
          other.taskId == this.taskId &&
          other.seq == this.seq &&
          other.url == this.url &&
          other.status == this.status &&
          other.byteSize == this.byteSize &&
          other.retryCount == this.retryCount);
}

class SegmentsCompanion extends UpdateCompanion<Segment> {
  final Value<String> taskId;
  final Value<int> seq;
  final Value<String> url;
  final Value<int> status;
  final Value<int> byteSize;
  final Value<int> retryCount;
  final Value<int> rowid;
  const SegmentsCompanion({
    this.taskId = const Value.absent(),
    this.seq = const Value.absent(),
    this.url = const Value.absent(),
    this.status = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SegmentsCompanion.insert({
    required String taskId,
    required int seq,
    required String url,
    this.status = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       seq = Value(seq),
       url = Value(url);
  static Insertable<Segment> custom({
    Expression<String>? taskId,
    Expression<int>? seq,
    Expression<String>? url,
    Expression<int>? status,
    Expression<int>? byteSize,
    Expression<int>? retryCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (seq != null) 'seq': seq,
      if (url != null) 'url': url,
      if (status != null) 'status': status,
      if (byteSize != null) 'byte_size': byteSize,
      if (retryCount != null) 'retry_count': retryCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SegmentsCompanion copyWith({
    Value<String>? taskId,
    Value<int>? seq,
    Value<String>? url,
    Value<int>? status,
    Value<int>? byteSize,
    Value<int>? retryCount,
    Value<int>? rowid,
  }) {
    return SegmentsCompanion(
      taskId: taskId ?? this.taskId,
      seq: seq ?? this.seq,
      url: url ?? this.url,
      status: status ?? this.status,
      byteSize: byteSize ?? this.byteSize,
      retryCount: retryCount ?? this.retryCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SegmentsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('seq: $seq, ')
          ..write('url: $url, ')
          ..write('status: $status, ')
          ..write('byteSize: $byteSize, ')
          ..write('retryCount: $retryCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardCommentsTable extends BoardComments
    with TableInfo<$BoardCommentsTable, BoardComment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardCommentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _objectIdMeta = const VerificationMeta(
    'objectId',
  );
  @override
  late final GeneratedColumn<String> objectId = GeneratedColumn<String>(
    'object_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nickMeta = const VerificationMeta('nick');
  @override
  late final GeneratedColumn<String> nick = GeneratedColumn<String>(
    'nick',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _insertedAtMeta = const VerificationMeta(
    'insertedAt',
  );
  @override
  late final GeneratedColumn<int> insertedAt = GeneratedColumn<int>(
    'inserted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ridMeta = const VerificationMeta('rid');
  @override
  late final GeneratedColumn<String> rid = GeneratedColumn<String>(
    'rid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addrMeta = const VerificationMeta('addr');
  @override
  late final GeneratedColumn<String> addr = GeneratedColumn<String>(
    'addr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    objectId,
    comment,
    nick,
    insertedAt,
    rid,
    link,
    avatar,
    addr,
    type,
    label,
    sortIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_comments';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardComment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('object_id')) {
      context.handle(
        _objectIdMeta,
        objectId.isAcceptableOrUnknown(data['object_id']!, _objectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_objectIdMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    } else if (isInserting) {
      context.missing(_commentMeta);
    }
    if (data.containsKey('nick')) {
      context.handle(
        _nickMeta,
        nick.isAcceptableOrUnknown(data['nick']!, _nickMeta),
      );
    } else if (isInserting) {
      context.missing(_nickMeta);
    }
    if (data.containsKey('inserted_at')) {
      context.handle(
        _insertedAtMeta,
        insertedAt.isAcceptableOrUnknown(data['inserted_at']!, _insertedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_insertedAtMeta);
    }
    if (data.containsKey('rid')) {
      context.handle(
        _ridMeta,
        rid.isAcceptableOrUnknown(data['rid']!, _ridMeta),
      );
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('addr')) {
      context.handle(
        _addrMeta,
        addr.isAcceptableOrUnknown(data['addr']!, _addrMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {objectId};
  @override
  BoardComment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardComment(
      objectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_id'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      )!,
      nick: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nick'],
      )!,
      insertedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}inserted_at'],
      )!,
      rid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rid'],
      ),
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      ),
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      addr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}addr'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_index'],
      )!,
    );
  }

  @override
  $BoardCommentsTable createAlias(String alias) {
    return $BoardCommentsTable(attachedDatabase, alias);
  }
}

class BoardComment extends DataClass implements Insertable<BoardComment> {
  final String objectId;
  final String comment;
  final String nick;
  final int insertedAt;
  final String? rid;
  final String? link;
  final String? avatar;

  /// Province-level IP region shown next to the timestamp.
  final String? addr;

  /// Registered-user role (e.g. "administrator"); null for anonymous.
  final String? type;

  /// Admin-set badge text (e.g. "admin"); null for anonymous.
  final String? label;

  /// Sort order within the cached page set (server order, newest first).
  final int sortIndex;
  const BoardComment({
    required this.objectId,
    required this.comment,
    required this.nick,
    required this.insertedAt,
    this.rid,
    this.link,
    this.avatar,
    this.addr,
    this.type,
    this.label,
    required this.sortIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['object_id'] = Variable<String>(objectId);
    map['comment'] = Variable<String>(comment);
    map['nick'] = Variable<String>(nick);
    map['inserted_at'] = Variable<int>(insertedAt);
    if (!nullToAbsent || rid != null) {
      map['rid'] = Variable<String>(rid);
    }
    if (!nullToAbsent || link != null) {
      map['link'] = Variable<String>(link);
    }
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    if (!nullToAbsent || addr != null) {
      map['addr'] = Variable<String>(addr);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['sort_index'] = Variable<int>(sortIndex);
    return map;
  }

  BoardCommentsCompanion toCompanion(bool nullToAbsent) {
    return BoardCommentsCompanion(
      objectId: Value(objectId),
      comment: Value(comment),
      nick: Value(nick),
      insertedAt: Value(insertedAt),
      rid: rid == null && nullToAbsent ? const Value.absent() : Value(rid),
      link: link == null && nullToAbsent ? const Value.absent() : Value(link),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      addr: addr == null && nullToAbsent ? const Value.absent() : Value(addr),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      sortIndex: Value(sortIndex),
    );
  }

  factory BoardComment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardComment(
      objectId: serializer.fromJson<String>(json['objectId']),
      comment: serializer.fromJson<String>(json['comment']),
      nick: serializer.fromJson<String>(json['nick']),
      insertedAt: serializer.fromJson<int>(json['insertedAt']),
      rid: serializer.fromJson<String?>(json['rid']),
      link: serializer.fromJson<String?>(json['link']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      addr: serializer.fromJson<String?>(json['addr']),
      type: serializer.fromJson<String?>(json['type']),
      label: serializer.fromJson<String?>(json['label']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'objectId': serializer.toJson<String>(objectId),
      'comment': serializer.toJson<String>(comment),
      'nick': serializer.toJson<String>(nick),
      'insertedAt': serializer.toJson<int>(insertedAt),
      'rid': serializer.toJson<String?>(rid),
      'link': serializer.toJson<String?>(link),
      'avatar': serializer.toJson<String?>(avatar),
      'addr': serializer.toJson<String?>(addr),
      'type': serializer.toJson<String?>(type),
      'label': serializer.toJson<String?>(label),
      'sortIndex': serializer.toJson<int>(sortIndex),
    };
  }

  BoardComment copyWith({
    String? objectId,
    String? comment,
    String? nick,
    int? insertedAt,
    Value<String?> rid = const Value.absent(),
    Value<String?> link = const Value.absent(),
    Value<String?> avatar = const Value.absent(),
    Value<String?> addr = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<String?> label = const Value.absent(),
    int? sortIndex,
  }) => BoardComment(
    objectId: objectId ?? this.objectId,
    comment: comment ?? this.comment,
    nick: nick ?? this.nick,
    insertedAt: insertedAt ?? this.insertedAt,
    rid: rid.present ? rid.value : this.rid,
    link: link.present ? link.value : this.link,
    avatar: avatar.present ? avatar.value : this.avatar,
    addr: addr.present ? addr.value : this.addr,
    type: type.present ? type.value : this.type,
    label: label.present ? label.value : this.label,
    sortIndex: sortIndex ?? this.sortIndex,
  );
  BoardComment copyWithCompanion(BoardCommentsCompanion data) {
    return BoardComment(
      objectId: data.objectId.present ? data.objectId.value : this.objectId,
      comment: data.comment.present ? data.comment.value : this.comment,
      nick: data.nick.present ? data.nick.value : this.nick,
      insertedAt: data.insertedAt.present
          ? data.insertedAt.value
          : this.insertedAt,
      rid: data.rid.present ? data.rid.value : this.rid,
      link: data.link.present ? data.link.value : this.link,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      addr: data.addr.present ? data.addr.value : this.addr,
      type: data.type.present ? data.type.value : this.type,
      label: data.label.present ? data.label.value : this.label,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardComment(')
          ..write('objectId: $objectId, ')
          ..write('comment: $comment, ')
          ..write('nick: $nick, ')
          ..write('insertedAt: $insertedAt, ')
          ..write('rid: $rid, ')
          ..write('link: $link, ')
          ..write('avatar: $avatar, ')
          ..write('addr: $addr, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('sortIndex: $sortIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    objectId,
    comment,
    nick,
    insertedAt,
    rid,
    link,
    avatar,
    addr,
    type,
    label,
    sortIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardComment &&
          other.objectId == this.objectId &&
          other.comment == this.comment &&
          other.nick == this.nick &&
          other.insertedAt == this.insertedAt &&
          other.rid == this.rid &&
          other.link == this.link &&
          other.avatar == this.avatar &&
          other.addr == this.addr &&
          other.type == this.type &&
          other.label == this.label &&
          other.sortIndex == this.sortIndex);
}

class BoardCommentsCompanion extends UpdateCompanion<BoardComment> {
  final Value<String> objectId;
  final Value<String> comment;
  final Value<String> nick;
  final Value<int> insertedAt;
  final Value<String?> rid;
  final Value<String?> link;
  final Value<String?> avatar;
  final Value<String?> addr;
  final Value<String?> type;
  final Value<String?> label;
  final Value<int> sortIndex;
  final Value<int> rowid;
  const BoardCommentsCompanion({
    this.objectId = const Value.absent(),
    this.comment = const Value.absent(),
    this.nick = const Value.absent(),
    this.insertedAt = const Value.absent(),
    this.rid = const Value.absent(),
    this.link = const Value.absent(),
    this.avatar = const Value.absent(),
    this.addr = const Value.absent(),
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardCommentsCompanion.insert({
    required String objectId,
    required String comment,
    required String nick,
    required int insertedAt,
    this.rid = const Value.absent(),
    this.link = const Value.absent(),
    this.avatar = const Value.absent(),
    this.addr = const Value.absent(),
    this.type = const Value.absent(),
    this.label = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : objectId = Value(objectId),
       comment = Value(comment),
       nick = Value(nick),
       insertedAt = Value(insertedAt);
  static Insertable<BoardComment> custom({
    Expression<String>? objectId,
    Expression<String>? comment,
    Expression<String>? nick,
    Expression<int>? insertedAt,
    Expression<String>? rid,
    Expression<String>? link,
    Expression<String>? avatar,
    Expression<String>? addr,
    Expression<String>? type,
    Expression<String>? label,
    Expression<int>? sortIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (objectId != null) 'object_id': objectId,
      if (comment != null) 'comment': comment,
      if (nick != null) 'nick': nick,
      if (insertedAt != null) 'inserted_at': insertedAt,
      if (rid != null) 'rid': rid,
      if (link != null) 'link': link,
      if (avatar != null) 'avatar': avatar,
      if (addr != null) 'addr': addr,
      if (type != null) 'type': type,
      if (label != null) 'label': label,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardCommentsCompanion copyWith({
    Value<String>? objectId,
    Value<String>? comment,
    Value<String>? nick,
    Value<int>? insertedAt,
    Value<String?>? rid,
    Value<String?>? link,
    Value<String?>? avatar,
    Value<String?>? addr,
    Value<String?>? type,
    Value<String?>? label,
    Value<int>? sortIndex,
    Value<int>? rowid,
  }) {
    return BoardCommentsCompanion(
      objectId: objectId ?? this.objectId,
      comment: comment ?? this.comment,
      nick: nick ?? this.nick,
      insertedAt: insertedAt ?? this.insertedAt,
      rid: rid ?? this.rid,
      link: link ?? this.link,
      avatar: avatar ?? this.avatar,
      addr: addr ?? this.addr,
      type: type ?? this.type,
      label: label ?? this.label,
      sortIndex: sortIndex ?? this.sortIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (objectId.present) {
      map['object_id'] = Variable<String>(objectId.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (nick.present) {
      map['nick'] = Variable<String>(nick.value);
    }
    if (insertedAt.present) {
      map['inserted_at'] = Variable<int>(insertedAt.value);
    }
    if (rid.present) {
      map['rid'] = Variable<String>(rid.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (addr.present) {
      map['addr'] = Variable<String>(addr.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardCommentsCompanion(')
          ..write('objectId: $objectId, ')
          ..write('comment: $comment, ')
          ..write('nick: $nick, ')
          ..write('insertedAt: $insertedAt, ')
          ..write('rid: $rid, ')
          ..write('link: $link, ')
          ..write('avatar: $avatar, ')
          ..write('addr: $addr, ')
          ..write('type: $type, ')
          ..write('label: $label, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $SegmentsTable segments = $SegmentsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $BoardCommentsTable boardComments = $BoardCommentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    segments,
    settings,
    boardComments,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String url,
      required String title,
      required int status,
      Value<String> headers,
      Value<String?> customKey,
      Value<String?> customIv,
      Value<String?> variantJson,
      Value<String?> playlistSnapshot,
      required String saveDir,
      Value<String?> outputPath,
      Value<int> totalSegments,
      Value<int> doneSegments,
      Value<int> totalBytes,
      Value<int> downloadedBytes,
      Value<String?> errorMsg,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> url,
      Value<String> title,
      Value<int> status,
      Value<String> headers,
      Value<String?> customKey,
      Value<String?> customIv,
      Value<String?> variantJson,
      Value<String?> playlistSnapshot,
      Value<String> saveDir,
      Value<String?> outputPath,
      Value<int> totalSegments,
      Value<int> doneSegments,
      Value<int> totalBytes,
      Value<int> downloadedBytes,
      Value<String?> errorMsg,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customKey => $composableBuilder(
    column: $table.customKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customIv => $composableBuilder(
    column: $table.customIv,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantJson => $composableBuilder(
    column: $table.variantJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playlistSnapshot => $composableBuilder(
    column: $table.playlistSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saveDir => $composableBuilder(
    column: $table.saveDir,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSegments => $composableBuilder(
    column: $table.totalSegments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get doneSegments => $composableBuilder(
    column: $table.doneSegments,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMsg => $composableBuilder(
    column: $table.errorMsg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headers => $composableBuilder(
    column: $table.headers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customKey => $composableBuilder(
    column: $table.customKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customIv => $composableBuilder(
    column: $table.customIv,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantJson => $composableBuilder(
    column: $table.variantJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playlistSnapshot => $composableBuilder(
    column: $table.playlistSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saveDir => $composableBuilder(
    column: $table.saveDir,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSegments => $composableBuilder(
    column: $table.totalSegments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get doneSegments => $composableBuilder(
    column: $table.doneSegments,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMsg => $composableBuilder(
    column: $table.errorMsg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get headers =>
      $composableBuilder(column: $table.headers, builder: (column) => column);

  GeneratedColumn<String> get customKey =>
      $composableBuilder(column: $table.customKey, builder: (column) => column);

  GeneratedColumn<String> get customIv =>
      $composableBuilder(column: $table.customIv, builder: (column) => column);

  GeneratedColumn<String> get variantJson => $composableBuilder(
    column: $table.variantJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playlistSnapshot => $composableBuilder(
    column: $table.playlistSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saveDir =>
      $composableBuilder(column: $table.saveDir, builder: (column) => column);

  GeneratedColumn<String> get outputPath => $composableBuilder(
    column: $table.outputPath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalSegments => $composableBuilder(
    column: $table.totalSegments,
    builder: (column) => column,
  );

  GeneratedColumn<int> get doneSegments => $composableBuilder(
    column: $table.doneSegments,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get downloadedBytes => $composableBuilder(
    column: $table.downloadedBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMsg =>
      $composableBuilder(column: $table.errorMsg, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> headers = const Value.absent(),
                Value<String?> customKey = const Value.absent(),
                Value<String?> customIv = const Value.absent(),
                Value<String?> variantJson = const Value.absent(),
                Value<String?> playlistSnapshot = const Value.absent(),
                Value<String> saveDir = const Value.absent(),
                Value<String?> outputPath = const Value.absent(),
                Value<int> totalSegments = const Value.absent(),
                Value<int> doneSegments = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String?> errorMsg = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                url: url,
                title: title,
                status: status,
                headers: headers,
                customKey: customKey,
                customIv: customIv,
                variantJson: variantJson,
                playlistSnapshot: playlistSnapshot,
                saveDir: saveDir,
                outputPath: outputPath,
                totalSegments: totalSegments,
                doneSegments: doneSegments,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes,
                errorMsg: errorMsg,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String url,
                required String title,
                required int status,
                Value<String> headers = const Value.absent(),
                Value<String?> customKey = const Value.absent(),
                Value<String?> customIv = const Value.absent(),
                Value<String?> variantJson = const Value.absent(),
                Value<String?> playlistSnapshot = const Value.absent(),
                required String saveDir,
                Value<String?> outputPath = const Value.absent(),
                Value<int> totalSegments = const Value.absent(),
                Value<int> doneSegments = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<int> downloadedBytes = const Value.absent(),
                Value<String?> errorMsg = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                url: url,
                title: title,
                status: status,
                headers: headers,
                customKey: customKey,
                customIv: customIv,
                variantJson: variantJson,
                playlistSnapshot: playlistSnapshot,
                saveDir: saveDir,
                outputPath: outputPath,
                totalSegments: totalSegments,
                doneSegments: doneSegments,
                totalBytes: totalBytes,
                downloadedBytes: downloadedBytes,
                errorMsg: errorMsg,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$SegmentsTableCreateCompanionBuilder =
    SegmentsCompanion Function({
      required String taskId,
      required int seq,
      required String url,
      Value<int> status,
      Value<int> byteSize,
      Value<int> retryCount,
      Value<int> rowid,
    });
typedef $$SegmentsTableUpdateCompanionBuilder =
    SegmentsCompanion Function({
      Value<String> taskId,
      Value<int> seq,
      Value<String> url,
      Value<int> status,
      Value<int> byteSize,
      Value<int> retryCount,
      Value<int> rowid,
    });

class $$SegmentsTableFilterComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SegmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SegmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SegmentsTable> {
  $$SegmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );
}

class $$SegmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SegmentsTable,
          Segment,
          $$SegmentsTableFilterComposer,
          $$SegmentsTableOrderingComposer,
          $$SegmentsTableAnnotationComposer,
          $$SegmentsTableCreateCompanionBuilder,
          $$SegmentsTableUpdateCompanionBuilder,
          (Segment, BaseReferences<_$AppDatabase, $SegmentsTable, Segment>),
          Segment,
          PrefetchHooks Function()
        > {
  $$SegmentsTableTableManager(_$AppDatabase db, $SegmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SegmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SegmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SegmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SegmentsCompanion(
                taskId: taskId,
                seq: seq,
                url: url,
                status: status,
                byteSize: byteSize,
                retryCount: retryCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required int seq,
                required String url,
                Value<int> status = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SegmentsCompanion.insert(
                taskId: taskId,
                seq: seq,
                url: url,
                status: status,
                byteSize: byteSize,
                retryCount: retryCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SegmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SegmentsTable,
      Segment,
      $$SegmentsTableFilterComposer,
      $$SegmentsTableOrderingComposer,
      $$SegmentsTableAnnotationComposer,
      $$SegmentsTableCreateCompanionBuilder,
      $$SegmentsTableUpdateCompanionBuilder,
      (Segment, BaseReferences<_$AppDatabase, $SegmentsTable, Segment>),
      Segment,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$BoardCommentsTableCreateCompanionBuilder =
    BoardCommentsCompanion Function({
      required String objectId,
      required String comment,
      required String nick,
      required int insertedAt,
      Value<String?> rid,
      Value<String?> link,
      Value<String?> avatar,
      Value<String?> addr,
      Value<String?> type,
      Value<String?> label,
      Value<int> sortIndex,
      Value<int> rowid,
    });
typedef $$BoardCommentsTableUpdateCompanionBuilder =
    BoardCommentsCompanion Function({
      Value<String> objectId,
      Value<String> comment,
      Value<String> nick,
      Value<int> insertedAt,
      Value<String?> rid,
      Value<String?> link,
      Value<String?> avatar,
      Value<String?> addr,
      Value<String?> type,
      Value<String?> label,
      Value<int> sortIndex,
      Value<int> rowid,
    });

class $$BoardCommentsTableFilterComposer
    extends Composer<_$AppDatabase, $BoardCommentsTable> {
  $$BoardCommentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get objectId => $composableBuilder(
    column: $table.objectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nick => $composableBuilder(
    column: $table.nick,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get insertedAt => $composableBuilder(
    column: $table.insertedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rid => $composableBuilder(
    column: $table.rid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addr => $composableBuilder(
    column: $table.addr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoardCommentsTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardCommentsTable> {
  $$BoardCommentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get objectId => $composableBuilder(
    column: $table.objectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nick => $composableBuilder(
    column: $table.nick,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get insertedAt => $composableBuilder(
    column: $table.insertedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rid => $composableBuilder(
    column: $table.rid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addr => $composableBuilder(
    column: $table.addr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardCommentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardCommentsTable> {
  $$BoardCommentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get objectId =>
      $composableBuilder(column: $table.objectId, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<String> get nick =>
      $composableBuilder(column: $table.nick, builder: (column) => column);

  GeneratedColumn<int> get insertedAt => $composableBuilder(
    column: $table.insertedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rid =>
      $composableBuilder(column: $table.rid, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get addr =>
      $composableBuilder(column: $table.addr, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);
}

class $$BoardCommentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardCommentsTable,
          BoardComment,
          $$BoardCommentsTableFilterComposer,
          $$BoardCommentsTableOrderingComposer,
          $$BoardCommentsTableAnnotationComposer,
          $$BoardCommentsTableCreateCompanionBuilder,
          $$BoardCommentsTableUpdateCompanionBuilder,
          (
            BoardComment,
            BaseReferences<_$AppDatabase, $BoardCommentsTable, BoardComment>,
          ),
          BoardComment,
          PrefetchHooks Function()
        > {
  $$BoardCommentsTableTableManager(_$AppDatabase db, $BoardCommentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardCommentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardCommentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardCommentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> objectId = const Value.absent(),
                Value<String> comment = const Value.absent(),
                Value<String> nick = const Value.absent(),
                Value<int> insertedAt = const Value.absent(),
                Value<String?> rid = const Value.absent(),
                Value<String?> link = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> addr = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardCommentsCompanion(
                objectId: objectId,
                comment: comment,
                nick: nick,
                insertedAt: insertedAt,
                rid: rid,
                link: link,
                avatar: avatar,
                addr: addr,
                type: type,
                label: label,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String objectId,
                required String comment,
                required String nick,
                required int insertedAt,
                Value<String?> rid = const Value.absent(),
                Value<String?> link = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String?> addr = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardCommentsCompanion.insert(
                objectId: objectId,
                comment: comment,
                nick: nick,
                insertedAt: insertedAt,
                rid: rid,
                link: link,
                avatar: avatar,
                addr: addr,
                type: type,
                label: label,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoardCommentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardCommentsTable,
      BoardComment,
      $$BoardCommentsTableFilterComposer,
      $$BoardCommentsTableOrderingComposer,
      $$BoardCommentsTableAnnotationComposer,
      $$BoardCommentsTableCreateCompanionBuilder,
      $$BoardCommentsTableUpdateCompanionBuilder,
      (
        BoardComment,
        BaseReferences<_$AppDatabase, $BoardCommentsTable, BoardComment>,
      ),
      BoardComment,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$SegmentsTableTableManager get segments =>
      $$SegmentsTableTableManager(_db, _db.segments);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$BoardCommentsTableTableManager get boardComments =>
      $$BoardCommentsTableTableManager(_db, _db.boardComments);
}
