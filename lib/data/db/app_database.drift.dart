// dart format width=80
// ignore_for_file: type=lint
part of 'app_database.dart';

class $RunsTable extends Runs with TableInfo<$RunsTable, RunRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowRevisionMeta = const VerificationMeta(
    'rowRevision',
  );
  @override
  late final GeneratedColumn<int> rowRevision = GeneratedColumn<int>(
    'row_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gameIdMeta = const VerificationMeta('gameId');
  @override
  late final GeneratedColumn<String> gameId = GeneratedColumn<String>(
    'game_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyIdMeta = const VerificationMeta(
    'difficultyId',
  );
  @override
  late final GeneratedColumn<String> difficultyId = GeneratedColumn<String>(
    'difficulty_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clientRunKeyMeta = const VerificationMeta(
    'clientRunKey',
  );
  @override
  late final GeneratedColumn<String> clientRunKey = GeneratedColumn<String>(
    'client_run_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtUtcMsMeta = const VerificationMeta(
    'startedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> startedAtUtcMs = GeneratedColumn<int>(
    'started_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedOnDayMeta = const VerificationMeta(
    'playedOnDay',
  );
  @override
  late final GeneratedColumn<int> playedOnDay = GeneratedColumn<int>(
    'played_on_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricKindMeta = const VerificationMeta(
    'metricKind',
  );
  @override
  late final GeneratedColumn<String> metricKind = GeneratedColumn<String>(
    'metric_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metricValueMeta = const VerificationMeta(
    'metricValue',
  );
  @override
  late final GeneratedColumn<int> metricValue = GeneratedColumn<int>(
    'metric_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctCountMeta = const VerificationMeta(
    'correctCount',
  );
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
    'correct_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wrongCountMeta = const VerificationMeta(
    'wrongCount',
  );
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
    'wrong_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longestComboMeta = const VerificationMeta(
    'longestCombo',
  );
  @override
  late final GeneratedColumn<int> longestCombo = GeneratedColumn<int>(
    'longest_combo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalReactionMsMeta = const VerificationMeta(
    'totalReactionMs',
  );
  @override
  late final GeneratedColumn<int> totalReactionMs = GeneratedColumn<int>(
    'total_reaction_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    rowRevision,
    isDeleted,
    deletedAtUtcMs,
    gameId,
    difficultyId,
    clientRunKey,
    startedAtUtcMs,
    playedOnDay,
    durationMs,
    metricKind,
    metricValue,
    correctCount,
    wrongCount,
    longestCombo,
    totalReactionMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<RunRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    if (data.containsKey('row_revision')) {
      context.handle(
        _rowRevisionMeta,
        rowRevision.isAcceptableOrUnknown(
          data['row_revision']!,
          _rowRevisionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('game_id')) {
      context.handle(
        _gameIdMeta,
        gameId.isAcceptableOrUnknown(data['game_id']!, _gameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_gameIdMeta);
    }
    if (data.containsKey('difficulty_id')) {
      context.handle(
        _difficultyIdMeta,
        difficultyId.isAcceptableOrUnknown(
          data['difficulty_id']!,
          _difficultyIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_difficultyIdMeta);
    }
    if (data.containsKey('client_run_key')) {
      context.handle(
        _clientRunKeyMeta,
        clientRunKey.isAcceptableOrUnknown(
          data['client_run_key']!,
          _clientRunKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientRunKeyMeta);
    }
    if (data.containsKey('started_at_utc_ms')) {
      context.handle(
        _startedAtUtcMsMeta,
        startedAtUtcMs.isAcceptableOrUnknown(
          data['started_at_utc_ms']!,
          _startedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtUtcMsMeta);
    }
    if (data.containsKey('played_on_day')) {
      context.handle(
        _playedOnDayMeta,
        playedOnDay.isAcceptableOrUnknown(
          data['played_on_day']!,
          _playedOnDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playedOnDayMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('metric_kind')) {
      context.handle(
        _metricKindMeta,
        metricKind.isAcceptableOrUnknown(data['metric_kind']!, _metricKindMeta),
      );
    } else if (isInserting) {
      context.missing(_metricKindMeta);
    }
    if (data.containsKey('metric_value')) {
      context.handle(
        _metricValueMeta,
        metricValue.isAcceptableOrUnknown(
          data['metric_value']!,
          _metricValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metricValueMeta);
    }
    if (data.containsKey('correct_count')) {
      context.handle(
        _correctCountMeta,
        correctCount.isAcceptableOrUnknown(
          data['correct_count']!,
          _correctCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctCountMeta);
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
        _wrongCountMeta,
        wrongCount.isAcceptableOrUnknown(data['wrong_count']!, _wrongCountMeta),
      );
    } else if (isInserting) {
      context.missing(_wrongCountMeta);
    }
    if (data.containsKey('longest_combo')) {
      context.handle(
        _longestComboMeta,
        longestCombo.isAcceptableOrUnknown(
          data['longest_combo']!,
          _longestComboMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_longestComboMeta);
    }
    if (data.containsKey('total_reaction_ms')) {
      context.handle(
        _totalReactionMsMeta,
        totalReactionMs.isAcceptableOrUnknown(
          data['total_reaction_ms']!,
          _totalReactionMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalReactionMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
      rowRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_revision'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
      gameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}game_id'],
      )!,
      difficultyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty_id'],
      )!,
      clientRunKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_run_key'],
      )!,
      startedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_utc_ms'],
      )!,
      playedOnDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}played_on_day'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      metricKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metric_kind'],
      )!,
      metricValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}metric_value'],
      )!,
      correctCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count'],
      )!,
      wrongCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wrong_count'],
      )!,
      longestCombo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_combo'],
      )!,
      totalReactionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_reaction_ms'],
      )!,
    );
  }

  @override
  $RunsTable createAlias(String alias) {
    return $RunsTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class RunRow extends DataClass implements Insertable<RunRow> {
  /// The row's stable identity, minted by the `IdGenerator` seam.
  final String id;

  /// When the row was first written, as UTC epoch milliseconds.
  final int createdAtUtcMs;

  /// When the row was last written, as UTC epoch milliseconds.
  final int updatedAtUtcMs;

  /// Bumped by exactly one on every write, so a lost update is detectable.
  final int rowRevision;

  /// Whether the row is soft-deleted. `0` or `1`; STRICT has no BOOLEAN type,
  /// so the `CHECK` on the table is what makes this column boolean.
  final int isDeleted;

  /// When the row was soft-deleted, as UTC epoch milliseconds, or `NULL`.
  final int? deletedAtUtcMs;

  /// Which game, as an ASCII token such as `stroop_rush`.
  final String gameId;

  /// Which difficulty, as an ASCII token such as `classic`.
  final String difficultyId;

  /// The engine's idempotency key for this run.
  final String clientRunKey;

  /// When the run started, as UTC epoch milliseconds.
  final int startedAtUtcMs;

  /// The local civil day the run counts towards, as a serial day number.
  final int playedOnDay;

  /// Wall-clock length of the run, in milliseconds.
  final int durationMs;

  /// `points` or `duration` — mirrors `ScoreFormat.name` exactly.
  final String metricKind;

  /// The score, in the unit [metricKind] names.
  final int metricValue;

  /// How many answers were correct.
  final int correctCount;

  /// How many answers were wrong.
  final int wrongCount;

  /// The longest unbroken run of correct answers.
  final int longestCombo;

  /// The **sum** of every reaction time, in milliseconds.
  final int totalReactionMs;
  const RunRow({
    required this.id,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    required this.rowRevision,
    required this.isDeleted,
    this.deletedAtUtcMs,
    required this.gameId,
    required this.difficultyId,
    required this.clientRunKey,
    required this.startedAtUtcMs,
    required this.playedOnDay,
    required this.durationMs,
    required this.metricKind,
    required this.metricValue,
    required this.correctCount,
    required this.wrongCount,
    required this.longestCombo,
    required this.totalReactionMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    map['row_revision'] = Variable<int>(rowRevision);
    map['is_deleted'] = Variable<int>(isDeleted);
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    map['game_id'] = Variable<String>(gameId);
    map['difficulty_id'] = Variable<String>(difficultyId);
    map['client_run_key'] = Variable<String>(clientRunKey);
    map['started_at_utc_ms'] = Variable<int>(startedAtUtcMs);
    map['played_on_day'] = Variable<int>(playedOnDay);
    map['duration_ms'] = Variable<int>(durationMs);
    map['metric_kind'] = Variable<String>(metricKind);
    map['metric_value'] = Variable<int>(metricValue);
    map['correct_count'] = Variable<int>(correctCount);
    map['wrong_count'] = Variable<int>(wrongCount);
    map['longest_combo'] = Variable<int>(longestCombo);
    map['total_reaction_ms'] = Variable<int>(totalReactionMs);
    return map;
  }

  RunsCompanion toCompanion(bool nullToAbsent) {
    return RunsCompanion(
      id: Value(id),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
      rowRevision: Value(rowRevision),
      isDeleted: Value(isDeleted),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
      gameId: Value(gameId),
      difficultyId: Value(difficultyId),
      clientRunKey: Value(clientRunKey),
      startedAtUtcMs: Value(startedAtUtcMs),
      playedOnDay: Value(playedOnDay),
      durationMs: Value(durationMs),
      metricKind: Value(metricKind),
      metricValue: Value(metricValue),
      correctCount: Value(correctCount),
      wrongCount: Value(wrongCount),
      longestCombo: Value(longestCombo),
      totalReactionMs: Value(totalReactionMs),
    );
  }

  factory RunRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunRow(
      id: serializer.fromJson<String>(json['id']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
      rowRevision: serializer.fromJson<int>(json['rowRevision']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
      gameId: serializer.fromJson<String>(json['gameId']),
      difficultyId: serializer.fromJson<String>(json['difficultyId']),
      clientRunKey: serializer.fromJson<String>(json['clientRunKey']),
      startedAtUtcMs: serializer.fromJson<int>(json['startedAtUtcMs']),
      playedOnDay: serializer.fromJson<int>(json['playedOnDay']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      metricKind: serializer.fromJson<String>(json['metricKind']),
      metricValue: serializer.fromJson<int>(json['metricValue']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      longestCombo: serializer.fromJson<int>(json['longestCombo']),
      totalReactionMs: serializer.fromJson<int>(json['totalReactionMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
      'rowRevision': serializer.toJson<int>(rowRevision),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
      'gameId': serializer.toJson<String>(gameId),
      'difficultyId': serializer.toJson<String>(difficultyId),
      'clientRunKey': serializer.toJson<String>(clientRunKey),
      'startedAtUtcMs': serializer.toJson<int>(startedAtUtcMs),
      'playedOnDay': serializer.toJson<int>(playedOnDay),
      'durationMs': serializer.toJson<int>(durationMs),
      'metricKind': serializer.toJson<String>(metricKind),
      'metricValue': serializer.toJson<int>(metricValue),
      'correctCount': serializer.toJson<int>(correctCount),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'longestCombo': serializer.toJson<int>(longestCombo),
      'totalReactionMs': serializer.toJson<int>(totalReactionMs),
    };
  }

  RunRow copyWith({
    String? id,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
    int? rowRevision,
    int? isDeleted,
    Value<int?> deletedAtUtcMs = const Value.absent(),
    String? gameId,
    String? difficultyId,
    String? clientRunKey,
    int? startedAtUtcMs,
    int? playedOnDay,
    int? durationMs,
    String? metricKind,
    int? metricValue,
    int? correctCount,
    int? wrongCount,
    int? longestCombo,
    int? totalReactionMs,
  }) => RunRow(
    id: id ?? this.id,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
    rowRevision: rowRevision ?? this.rowRevision,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
    gameId: gameId ?? this.gameId,
    difficultyId: difficultyId ?? this.difficultyId,
    clientRunKey: clientRunKey ?? this.clientRunKey,
    startedAtUtcMs: startedAtUtcMs ?? this.startedAtUtcMs,
    playedOnDay: playedOnDay ?? this.playedOnDay,
    durationMs: durationMs ?? this.durationMs,
    metricKind: metricKind ?? this.metricKind,
    metricValue: metricValue ?? this.metricValue,
    correctCount: correctCount ?? this.correctCount,
    wrongCount: wrongCount ?? this.wrongCount,
    longestCombo: longestCombo ?? this.longestCombo,
    totalReactionMs: totalReactionMs ?? this.totalReactionMs,
  );
  RunRow copyWithCompanion(RunsCompanion data) {
    return RunRow(
      id: data.id.present ? data.id.value : this.id,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
      rowRevision: data.rowRevision.present
          ? data.rowRevision.value
          : this.rowRevision,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
      gameId: data.gameId.present ? data.gameId.value : this.gameId,
      difficultyId: data.difficultyId.present
          ? data.difficultyId.value
          : this.difficultyId,
      clientRunKey: data.clientRunKey.present
          ? data.clientRunKey.value
          : this.clientRunKey,
      startedAtUtcMs: data.startedAtUtcMs.present
          ? data.startedAtUtcMs.value
          : this.startedAtUtcMs,
      playedOnDay: data.playedOnDay.present
          ? data.playedOnDay.value
          : this.playedOnDay,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      metricKind: data.metricKind.present
          ? data.metricKind.value
          : this.metricKind,
      metricValue: data.metricValue.present
          ? data.metricValue.value
          : this.metricValue,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      wrongCount: data.wrongCount.present
          ? data.wrongCount.value
          : this.wrongCount,
      longestCombo: data.longestCombo.present
          ? data.longestCombo.value
          : this.longestCombo,
      totalReactionMs: data.totalReactionMs.present
          ? data.totalReactionMs.value
          : this.totalReactionMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunRow(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowRevision: $rowRevision, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('gameId: $gameId, ')
          ..write('difficultyId: $difficultyId, ')
          ..write('clientRunKey: $clientRunKey, ')
          ..write('startedAtUtcMs: $startedAtUtcMs, ')
          ..write('playedOnDay: $playedOnDay, ')
          ..write('durationMs: $durationMs, ')
          ..write('metricKind: $metricKind, ')
          ..write('metricValue: $metricValue, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('longestCombo: $longestCombo, ')
          ..write('totalReactionMs: $totalReactionMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    rowRevision,
    isDeleted,
    deletedAtUtcMs,
    gameId,
    difficultyId,
    clientRunKey,
    startedAtUtcMs,
    playedOnDay,
    durationMs,
    metricKind,
    metricValue,
    correctCount,
    wrongCount,
    longestCombo,
    totalReactionMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunRow &&
          other.id == this.id &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs &&
          other.rowRevision == this.rowRevision &&
          other.isDeleted == this.isDeleted &&
          other.deletedAtUtcMs == this.deletedAtUtcMs &&
          other.gameId == this.gameId &&
          other.difficultyId == this.difficultyId &&
          other.clientRunKey == this.clientRunKey &&
          other.startedAtUtcMs == this.startedAtUtcMs &&
          other.playedOnDay == this.playedOnDay &&
          other.durationMs == this.durationMs &&
          other.metricKind == this.metricKind &&
          other.metricValue == this.metricValue &&
          other.correctCount == this.correctCount &&
          other.wrongCount == this.wrongCount &&
          other.longestCombo == this.longestCombo &&
          other.totalReactionMs == this.totalReactionMs);
}

class RunsCompanion extends UpdateCompanion<RunRow> {
  final Value<String> id;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int> rowRevision;
  final Value<int> isDeleted;
  final Value<int?> deletedAtUtcMs;
  final Value<String> gameId;
  final Value<String> difficultyId;
  final Value<String> clientRunKey;
  final Value<int> startedAtUtcMs;
  final Value<int> playedOnDay;
  final Value<int> durationMs;
  final Value<String> metricKind;
  final Value<int> metricValue;
  final Value<int> correctCount;
  final Value<int> wrongCount;
  final Value<int> longestCombo;
  final Value<int> totalReactionMs;
  final Value<int> rowid;
  const RunsCompanion({
    this.id = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.rowRevision = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.gameId = const Value.absent(),
    this.difficultyId = const Value.absent(),
    this.clientRunKey = const Value.absent(),
    this.startedAtUtcMs = const Value.absent(),
    this.playedOnDay = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.metricKind = const Value.absent(),
    this.metricValue = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.longestCombo = const Value.absent(),
    this.totalReactionMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunsCompanion.insert({
    required String id,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.rowRevision = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    required String gameId,
    required String difficultyId,
    required String clientRunKey,
    required int startedAtUtcMs,
    required int playedOnDay,
    required int durationMs,
    required String metricKind,
    required int metricValue,
    required int correctCount,
    required int wrongCount,
    required int longestCombo,
    required int totalReactionMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs),
       gameId = Value(gameId),
       difficultyId = Value(difficultyId),
       clientRunKey = Value(clientRunKey),
       startedAtUtcMs = Value(startedAtUtcMs),
       playedOnDay = Value(playedOnDay),
       durationMs = Value(durationMs),
       metricKind = Value(metricKind),
       metricValue = Value(metricValue),
       correctCount = Value(correctCount),
       wrongCount = Value(wrongCount),
       longestCombo = Value(longestCombo),
       totalReactionMs = Value(totalReactionMs);
  static Insertable<RunRow> custom({
    Expression<String>? id,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? rowRevision,
    Expression<int>? isDeleted,
    Expression<int>? deletedAtUtcMs,
    Expression<String>? gameId,
    Expression<String>? difficultyId,
    Expression<String>? clientRunKey,
    Expression<int>? startedAtUtcMs,
    Expression<int>? playedOnDay,
    Expression<int>? durationMs,
    Expression<String>? metricKind,
    Expression<int>? metricValue,
    Expression<int>? correctCount,
    Expression<int>? wrongCount,
    Expression<int>? longestCombo,
    Expression<int>? totalReactionMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (rowRevision != null) 'row_revision': rowRevision,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (gameId != null) 'game_id': gameId,
      if (difficultyId != null) 'difficulty_id': difficultyId,
      if (clientRunKey != null) 'client_run_key': clientRunKey,
      if (startedAtUtcMs != null) 'started_at_utc_ms': startedAtUtcMs,
      if (playedOnDay != null) 'played_on_day': playedOnDay,
      if (durationMs != null) 'duration_ms': durationMs,
      if (metricKind != null) 'metric_kind': metricKind,
      if (metricValue != null) 'metric_value': metricValue,
      if (correctCount != null) 'correct_count': correctCount,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (longestCombo != null) 'longest_combo': longestCombo,
      if (totalReactionMs != null) 'total_reaction_ms': totalReactionMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunsCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int>? rowRevision,
    Value<int>? isDeleted,
    Value<int?>? deletedAtUtcMs,
    Value<String>? gameId,
    Value<String>? difficultyId,
    Value<String>? clientRunKey,
    Value<int>? startedAtUtcMs,
    Value<int>? playedOnDay,
    Value<int>? durationMs,
    Value<String>? metricKind,
    Value<int>? metricValue,
    Value<int>? correctCount,
    Value<int>? wrongCount,
    Value<int>? longestCombo,
    Value<int>? totalReactionMs,
    Value<int>? rowid,
  }) {
    return RunsCompanion(
      id: id ?? this.id,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      rowRevision: rowRevision ?? this.rowRevision,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      gameId: gameId ?? this.gameId,
      difficultyId: difficultyId ?? this.difficultyId,
      clientRunKey: clientRunKey ?? this.clientRunKey,
      startedAtUtcMs: startedAtUtcMs ?? this.startedAtUtcMs,
      playedOnDay: playedOnDay ?? this.playedOnDay,
      durationMs: durationMs ?? this.durationMs,
      metricKind: metricKind ?? this.metricKind,
      metricValue: metricValue ?? this.metricValue,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      longestCombo: longestCombo ?? this.longestCombo,
      totalReactionMs: totalReactionMs ?? this.totalReactionMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (rowRevision.present) {
      map['row_revision'] = Variable<int>(rowRevision.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (gameId.present) {
      map['game_id'] = Variable<String>(gameId.value);
    }
    if (difficultyId.present) {
      map['difficulty_id'] = Variable<String>(difficultyId.value);
    }
    if (clientRunKey.present) {
      map['client_run_key'] = Variable<String>(clientRunKey.value);
    }
    if (startedAtUtcMs.present) {
      map['started_at_utc_ms'] = Variable<int>(startedAtUtcMs.value);
    }
    if (playedOnDay.present) {
      map['played_on_day'] = Variable<int>(playedOnDay.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (metricKind.present) {
      map['metric_kind'] = Variable<String>(metricKind.value);
    }
    if (metricValue.present) {
      map['metric_value'] = Variable<int>(metricValue.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (longestCombo.present) {
      map['longest_combo'] = Variable<int>(longestCombo.value);
    }
    if (totalReactionMs.present) {
      map['total_reaction_ms'] = Variable<int>(totalReactionMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunsCompanion(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowRevision: $rowRevision, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('gameId: $gameId, ')
          ..write('difficultyId: $difficultyId, ')
          ..write('clientRunKey: $clientRunKey, ')
          ..write('startedAtUtcMs: $startedAtUtcMs, ')
          ..write('playedOnDay: $playedOnDay, ')
          ..write('durationMs: $durationMs, ')
          ..write('metricKind: $metricKind, ')
          ..write('metricValue: $metricValue, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('longestCombo: $longestCombo, ')
          ..write('totalReactionMs: $totalReactionMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMsMeta = const VerificationMeta(
    'createdAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> createdAtUtcMs = GeneratedColumn<int>(
    'created_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMsMeta = const VerificationMeta(
    'updatedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtUtcMs = GeneratedColumn<int>(
    'updated_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowRevisionMeta = const VerificationMeta(
    'rowRevision',
  );
  @override
  late final GeneratedColumn<int> rowRevision = GeneratedColumn<int>(
    'row_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deletedAtUtcMsMeta = const VerificationMeta(
    'deletedAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtUtcMs = GeneratedColumn<int>(
    'deleted_at_utc_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSoundEnabledMeta = const VerificationMeta(
    'isSoundEnabled',
  );
  @override
  late final GeneratedColumn<int> isSoundEnabled = GeneratedColumn<int>(
    'is_sound_enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isHapticsEnabledMeta = const VerificationMeta(
    'isHapticsEnabled',
  );
  @override
  late final GeneratedColumn<int> isHapticsEnabled = GeneratedColumn<int>(
    'is_haptics_enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReduceMotionEnabledMeta =
      const VerificationMeta('isReduceMotionEnabled');
  @override
  late final GeneratedColumn<int> isReduceMotionEnabled = GeneratedColumn<int>(
    'is_reduce_motion_enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isColourBlindPaletteMeta =
      const VerificationMeta('isColourBlindPalette');
  @override
  late final GeneratedColumn<int> isColourBlindPalette = GeneratedColumn<int>(
    'is_colour_blind_palette',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localeTagMeta = const VerificationMeta(
    'localeTag',
  );
  @override
  late final GeneratedColumn<String> localeTag = GeneratedColumn<String>(
    'locale_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    rowRevision,
    isDeleted,
    deletedAtUtcMs,
    isSoundEnabled,
    isHapticsEnabled,
    isReduceMotionEnabled,
    isColourBlindPalette,
    localeTag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at_utc_ms')) {
      context.handle(
        _createdAtUtcMsMeta,
        createdAtUtcMs.isAcceptableOrUnknown(
          data['created_at_utc_ms']!,
          _createdAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMsMeta);
    }
    if (data.containsKey('updated_at_utc_ms')) {
      context.handle(
        _updatedAtUtcMsMeta,
        updatedAtUtcMs.isAcceptableOrUnknown(
          data['updated_at_utc_ms']!,
          _updatedAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMsMeta);
    }
    if (data.containsKey('row_revision')) {
      context.handle(
        _rowRevisionMeta,
        rowRevision.isAcceptableOrUnknown(
          data['row_revision']!,
          _rowRevisionMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at_utc_ms')) {
      context.handle(
        _deletedAtUtcMsMeta,
        deletedAtUtcMs.isAcceptableOrUnknown(
          data['deleted_at_utc_ms']!,
          _deletedAtUtcMsMeta,
        ),
      );
    }
    if (data.containsKey('is_sound_enabled')) {
      context.handle(
        _isSoundEnabledMeta,
        isSoundEnabled.isAcceptableOrUnknown(
          data['is_sound_enabled']!,
          _isSoundEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isSoundEnabledMeta);
    }
    if (data.containsKey('is_haptics_enabled')) {
      context.handle(
        _isHapticsEnabledMeta,
        isHapticsEnabled.isAcceptableOrUnknown(
          data['is_haptics_enabled']!,
          _isHapticsEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isHapticsEnabledMeta);
    }
    if (data.containsKey('is_reduce_motion_enabled')) {
      context.handle(
        _isReduceMotionEnabledMeta,
        isReduceMotionEnabled.isAcceptableOrUnknown(
          data['is_reduce_motion_enabled']!,
          _isReduceMotionEnabledMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isReduceMotionEnabledMeta);
    }
    if (data.containsKey('is_colour_blind_palette')) {
      context.handle(
        _isColourBlindPaletteMeta,
        isColourBlindPalette.isAcceptableOrUnknown(
          data['is_colour_blind_palette']!,
          _isColourBlindPaletteMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isColourBlindPaletteMeta);
    }
    if (data.containsKey('locale_tag')) {
      context.handle(
        _localeTagMeta,
        localeTag.isAcceptableOrUnknown(data['locale_tag']!, _localeTagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_ms'],
      )!,
      updatedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_ms'],
      )!,
      rowRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_revision'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_utc_ms'],
      ),
      isSoundEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_sound_enabled'],
      )!,
      isHapticsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_haptics_enabled'],
      )!,
      isReduceMotionEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_reduce_motion_enabled'],
      )!,
      isColourBlindPalette: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_colour_blind_palette'],
      )!,
      localeTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale_tag'],
      ),
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  /// The row's stable identity, minted by the `IdGenerator` seam.
  final String id;

  /// When the row was first written, as UTC epoch milliseconds.
  final int createdAtUtcMs;

  /// When the row was last written, as UTC epoch milliseconds.
  final int updatedAtUtcMs;

  /// Bumped by exactly one on every write, so a lost update is detectable.
  final int rowRevision;

  /// Whether the row is soft-deleted. `0` or `1`; STRICT has no BOOLEAN type,
  /// so the `CHECK` on the table is what makes this column boolean.
  final int isDeleted;

  /// When the row was soft-deleted, as UTC epoch milliseconds, or `NULL`.
  final int? deletedAtUtcMs;

  /// Whether sound effects play. `0` or `1`.
  final int isSoundEnabled;

  /// Whether haptics fire. `0` or `1`.
  final int isHapticsEnabled;

  /// Whether motion is reduced. `0` or `1`.
  final int isReduceMotionEnabled;

  /// Whether the colour-blind-safe answer palette is in use. `0` or `1`.
  final int isColourBlindPalette;

  /// The user's explicit locale choice as a BCP-47 tag, or `NULL` to follow the
  /// system locale.
  final String? localeTag;
  const SettingsRow({
    required this.id,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
    required this.rowRevision,
    required this.isDeleted,
    this.deletedAtUtcMs,
    required this.isSoundEnabled,
    required this.isHapticsEnabled,
    required this.isReduceMotionEnabled,
    required this.isColourBlindPalette,
    this.localeTag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs);
    map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs);
    map['row_revision'] = Variable<int>(rowRevision);
    map['is_deleted'] = Variable<int>(isDeleted);
    if (!nullToAbsent || deletedAtUtcMs != null) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs);
    }
    map['is_sound_enabled'] = Variable<int>(isSoundEnabled);
    map['is_haptics_enabled'] = Variable<int>(isHapticsEnabled);
    map['is_reduce_motion_enabled'] = Variable<int>(isReduceMotionEnabled);
    map['is_colour_blind_palette'] = Variable<int>(isColourBlindPalette);
    if (!nullToAbsent || localeTag != null) {
      map['locale_tag'] = Variable<String>(localeTag);
    }
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      id: Value(id),
      createdAtUtcMs: Value(createdAtUtcMs),
      updatedAtUtcMs: Value(updatedAtUtcMs),
      rowRevision: Value(rowRevision),
      isDeleted: Value(isDeleted),
      deletedAtUtcMs: deletedAtUtcMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtUtcMs),
      isSoundEnabled: Value(isSoundEnabled),
      isHapticsEnabled: Value(isHapticsEnabled),
      isReduceMotionEnabled: Value(isReduceMotionEnabled),
      isColourBlindPalette: Value(isColourBlindPalette),
      localeTag: localeTag == null && nullToAbsent
          ? const Value.absent()
          : Value(localeTag),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<String>(json['id']),
      createdAtUtcMs: serializer.fromJson<int>(json['createdAtUtcMs']),
      updatedAtUtcMs: serializer.fromJson<int>(json['updatedAtUtcMs']),
      rowRevision: serializer.fromJson<int>(json['rowRevision']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      deletedAtUtcMs: serializer.fromJson<int?>(json['deletedAtUtcMs']),
      isSoundEnabled: serializer.fromJson<int>(json['isSoundEnabled']),
      isHapticsEnabled: serializer.fromJson<int>(json['isHapticsEnabled']),
      isReduceMotionEnabled: serializer.fromJson<int>(
        json['isReduceMotionEnabled'],
      ),
      isColourBlindPalette: serializer.fromJson<int>(
        json['isColourBlindPalette'],
      ),
      localeTag: serializer.fromJson<String?>(json['localeTag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAtUtcMs': serializer.toJson<int>(createdAtUtcMs),
      'updatedAtUtcMs': serializer.toJson<int>(updatedAtUtcMs),
      'rowRevision': serializer.toJson<int>(rowRevision),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'deletedAtUtcMs': serializer.toJson<int?>(deletedAtUtcMs),
      'isSoundEnabled': serializer.toJson<int>(isSoundEnabled),
      'isHapticsEnabled': serializer.toJson<int>(isHapticsEnabled),
      'isReduceMotionEnabled': serializer.toJson<int>(isReduceMotionEnabled),
      'isColourBlindPalette': serializer.toJson<int>(isColourBlindPalette),
      'localeTag': serializer.toJson<String?>(localeTag),
    };
  }

  SettingsRow copyWith({
    String? id,
    int? createdAtUtcMs,
    int? updatedAtUtcMs,
    int? rowRevision,
    int? isDeleted,
    Value<int?> deletedAtUtcMs = const Value.absent(),
    int? isSoundEnabled,
    int? isHapticsEnabled,
    int? isReduceMotionEnabled,
    int? isColourBlindPalette,
    Value<String?> localeTag = const Value.absent(),
  }) => SettingsRow(
    id: id ?? this.id,
    createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
    updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
    rowRevision: rowRevision ?? this.rowRevision,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAtUtcMs: deletedAtUtcMs.present
        ? deletedAtUtcMs.value
        : this.deletedAtUtcMs,
    isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
    isHapticsEnabled: isHapticsEnabled ?? this.isHapticsEnabled,
    isReduceMotionEnabled: isReduceMotionEnabled ?? this.isReduceMotionEnabled,
    isColourBlindPalette: isColourBlindPalette ?? this.isColourBlindPalette,
    localeTag: localeTag.present ? localeTag.value : this.localeTag,
  );
  SettingsRow copyWithCompanion(SettingsTableCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      createdAtUtcMs: data.createdAtUtcMs.present
          ? data.createdAtUtcMs.value
          : this.createdAtUtcMs,
      updatedAtUtcMs: data.updatedAtUtcMs.present
          ? data.updatedAtUtcMs.value
          : this.updatedAtUtcMs,
      rowRevision: data.rowRevision.present
          ? data.rowRevision.value
          : this.rowRevision,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAtUtcMs: data.deletedAtUtcMs.present
          ? data.deletedAtUtcMs.value
          : this.deletedAtUtcMs,
      isSoundEnabled: data.isSoundEnabled.present
          ? data.isSoundEnabled.value
          : this.isSoundEnabled,
      isHapticsEnabled: data.isHapticsEnabled.present
          ? data.isHapticsEnabled.value
          : this.isHapticsEnabled,
      isReduceMotionEnabled: data.isReduceMotionEnabled.present
          ? data.isReduceMotionEnabled.value
          : this.isReduceMotionEnabled,
      isColourBlindPalette: data.isColourBlindPalette.present
          ? data.isColourBlindPalette.value
          : this.isColourBlindPalette,
      localeTag: data.localeTag.present ? data.localeTag.value : this.localeTag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowRevision: $rowRevision, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('isSoundEnabled: $isSoundEnabled, ')
          ..write('isHapticsEnabled: $isHapticsEnabled, ')
          ..write('isReduceMotionEnabled: $isReduceMotionEnabled, ')
          ..write('isColourBlindPalette: $isColourBlindPalette, ')
          ..write('localeTag: $localeTag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAtUtcMs,
    updatedAtUtcMs,
    rowRevision,
    isDeleted,
    deletedAtUtcMs,
    isSoundEnabled,
    isHapticsEnabled,
    isReduceMotionEnabled,
    isColourBlindPalette,
    localeTag,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.createdAtUtcMs == this.createdAtUtcMs &&
          other.updatedAtUtcMs == this.updatedAtUtcMs &&
          other.rowRevision == this.rowRevision &&
          other.isDeleted == this.isDeleted &&
          other.deletedAtUtcMs == this.deletedAtUtcMs &&
          other.isSoundEnabled == this.isSoundEnabled &&
          other.isHapticsEnabled == this.isHapticsEnabled &&
          other.isReduceMotionEnabled == this.isReduceMotionEnabled &&
          other.isColourBlindPalette == this.isColourBlindPalette &&
          other.localeTag == this.localeTag);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsRow> {
  final Value<String> id;
  final Value<int> createdAtUtcMs;
  final Value<int> updatedAtUtcMs;
  final Value<int> rowRevision;
  final Value<int> isDeleted;
  final Value<int?> deletedAtUtcMs;
  final Value<int> isSoundEnabled;
  final Value<int> isHapticsEnabled;
  final Value<int> isReduceMotionEnabled;
  final Value<int> isColourBlindPalette;
  final Value<String?> localeTag;
  final Value<int> rowid;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.createdAtUtcMs = const Value.absent(),
    this.updatedAtUtcMs = const Value.absent(),
    this.rowRevision = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    this.isSoundEnabled = const Value.absent(),
    this.isHapticsEnabled = const Value.absent(),
    this.isReduceMotionEnabled = const Value.absent(),
    this.isColourBlindPalette = const Value.absent(),
    this.localeTag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    required String id,
    required int createdAtUtcMs,
    required int updatedAtUtcMs,
    this.rowRevision = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAtUtcMs = const Value.absent(),
    required int isSoundEnabled,
    required int isHapticsEnabled,
    required int isReduceMotionEnabled,
    required int isColourBlindPalette,
    this.localeTag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAtUtcMs = Value(createdAtUtcMs),
       updatedAtUtcMs = Value(updatedAtUtcMs),
       isSoundEnabled = Value(isSoundEnabled),
       isHapticsEnabled = Value(isHapticsEnabled),
       isReduceMotionEnabled = Value(isReduceMotionEnabled),
       isColourBlindPalette = Value(isColourBlindPalette);
  static Insertable<SettingsRow> custom({
    Expression<String>? id,
    Expression<int>? createdAtUtcMs,
    Expression<int>? updatedAtUtcMs,
    Expression<int>? rowRevision,
    Expression<int>? isDeleted,
    Expression<int>? deletedAtUtcMs,
    Expression<int>? isSoundEnabled,
    Expression<int>? isHapticsEnabled,
    Expression<int>? isReduceMotionEnabled,
    Expression<int>? isColourBlindPalette,
    Expression<String>? localeTag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAtUtcMs != null) 'created_at_utc_ms': createdAtUtcMs,
      if (updatedAtUtcMs != null) 'updated_at_utc_ms': updatedAtUtcMs,
      if (rowRevision != null) 'row_revision': rowRevision,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAtUtcMs != null) 'deleted_at_utc_ms': deletedAtUtcMs,
      if (isSoundEnabled != null) 'is_sound_enabled': isSoundEnabled,
      if (isHapticsEnabled != null) 'is_haptics_enabled': isHapticsEnabled,
      if (isReduceMotionEnabled != null)
        'is_reduce_motion_enabled': isReduceMotionEnabled,
      if (isColourBlindPalette != null)
        'is_colour_blind_palette': isColourBlindPalette,
      if (localeTag != null) 'locale_tag': localeTag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? createdAtUtcMs,
    Value<int>? updatedAtUtcMs,
    Value<int>? rowRevision,
    Value<int>? isDeleted,
    Value<int?>? deletedAtUtcMs,
    Value<int>? isSoundEnabled,
    Value<int>? isHapticsEnabled,
    Value<int>? isReduceMotionEnabled,
    Value<int>? isColourBlindPalette,
    Value<String?>? localeTag,
    Value<int>? rowid,
  }) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      createdAtUtcMs: createdAtUtcMs ?? this.createdAtUtcMs,
      updatedAtUtcMs: updatedAtUtcMs ?? this.updatedAtUtcMs,
      rowRevision: rowRevision ?? this.rowRevision,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAtUtcMs: deletedAtUtcMs ?? this.deletedAtUtcMs,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isHapticsEnabled: isHapticsEnabled ?? this.isHapticsEnabled,
      isReduceMotionEnabled:
          isReduceMotionEnabled ?? this.isReduceMotionEnabled,
      isColourBlindPalette: isColourBlindPalette ?? this.isColourBlindPalette,
      localeTag: localeTag ?? this.localeTag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAtUtcMs.present) {
      map['created_at_utc_ms'] = Variable<int>(createdAtUtcMs.value);
    }
    if (updatedAtUtcMs.present) {
      map['updated_at_utc_ms'] = Variable<int>(updatedAtUtcMs.value);
    }
    if (rowRevision.present) {
      map['row_revision'] = Variable<int>(rowRevision.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (deletedAtUtcMs.present) {
      map['deleted_at_utc_ms'] = Variable<int>(deletedAtUtcMs.value);
    }
    if (isSoundEnabled.present) {
      map['is_sound_enabled'] = Variable<int>(isSoundEnabled.value);
    }
    if (isHapticsEnabled.present) {
      map['is_haptics_enabled'] = Variable<int>(isHapticsEnabled.value);
    }
    if (isReduceMotionEnabled.present) {
      map['is_reduce_motion_enabled'] = Variable<int>(
        isReduceMotionEnabled.value,
      );
    }
    if (isColourBlindPalette.present) {
      map['is_colour_blind_palette'] = Variable<int>(
        isColourBlindPalette.value,
      );
    }
    if (localeTag.present) {
      map['locale_tag'] = Variable<String>(localeTag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('createdAtUtcMs: $createdAtUtcMs, ')
          ..write('updatedAtUtcMs: $updatedAtUtcMs, ')
          ..write('rowRevision: $rowRevision, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAtUtcMs: $deletedAtUtcMs, ')
          ..write('isSoundEnabled: $isSoundEnabled, ')
          ..write('isHapticsEnabled: $isHapticsEnabled, ')
          ..write('isReduceMotionEnabled: $isReduceMotionEnabled, ')
          ..write('isColourBlindPalette: $isColourBlindPalette, ')
          ..write('localeTag: $localeTag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RunsTable runs = $RunsTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final Index uxRunsClientKey = Index(
    'ux_runs_client_key',
    'CREATE UNIQUE INDEX ux_runs_client_key ON runs (client_run_key) WHERE is_deleted = 0',
  );
  late final Index idxRunsGameDifficultyTime = Index(
    'idx_runs_game_difficulty_time',
    'CREATE INDEX idx_runs_game_difficulty_time ON runs (game_id, difficulty_id, started_at_utc_ms)',
  );
  late final Index idxRunsDay = Index(
    'idx_runs_day',
    'CREATE INDEX idx_runs_day ON runs (played_on_day)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    runs,
    settingsTable,
    uxRunsClientKey,
    idxRunsGameDifficultyTime,
    idxRunsDay,
  ];
}

typedef $$RunsTableCreateCompanionBuilder =
    RunsCompanion Function({
      required String id,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int> rowRevision,
      Value<int> isDeleted,
      Value<int?> deletedAtUtcMs,
      required String gameId,
      required String difficultyId,
      required String clientRunKey,
      required int startedAtUtcMs,
      required int playedOnDay,
      required int durationMs,
      required String metricKind,
      required int metricValue,
      required int correctCount,
      required int wrongCount,
      required int longestCombo,
      required int totalReactionMs,
      Value<int> rowid,
    });
typedef $$RunsTableUpdateCompanionBuilder =
    RunsCompanion Function({
      Value<String> id,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int> rowRevision,
      Value<int> isDeleted,
      Value<int?> deletedAtUtcMs,
      Value<String> gameId,
      Value<String> difficultyId,
      Value<String> clientRunKey,
      Value<int> startedAtUtcMs,
      Value<int> playedOnDay,
      Value<int> durationMs,
      Value<String> metricKind,
      Value<int> metricValue,
      Value<int> correctCount,
      Value<int> wrongCount,
      Value<int> longestCombo,
      Value<int> totalReactionMs,
      Value<int> rowid,
    });

class $$RunsTableFilterComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableFilterComposer({
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

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficultyId => $composableBuilder(
    column: $table.difficultyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientRunKey => $composableBuilder(
    column: $table.clientRunKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtUtcMs => $composableBuilder(
    column: $table.startedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get playedOnDay => $composableBuilder(
    column: $table.playedOnDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metricKind => $composableBuilder(
    column: $table.metricKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get metricValue => $composableBuilder(
    column: $table.metricValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestCombo => $composableBuilder(
    column: $table.longestCombo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalReactionMs => $composableBuilder(
    column: $table.totalReactionMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RunsTableOrderingComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableOrderingComposer({
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

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gameId => $composableBuilder(
    column: $table.gameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficultyId => $composableBuilder(
    column: $table.difficultyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientRunKey => $composableBuilder(
    column: $table.clientRunKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtUtcMs => $composableBuilder(
    column: $table.startedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedOnDay => $composableBuilder(
    column: $table.playedOnDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metricKind => $composableBuilder(
    column: $table.metricKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get metricValue => $composableBuilder(
    column: $table.metricValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestCombo => $composableBuilder(
    column: $table.longestCombo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalReactionMs => $composableBuilder(
    column: $table.totalReactionMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RunsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gameId =>
      $composableBuilder(column: $table.gameId, builder: (column) => column);

  GeneratedColumn<String> get difficultyId => $composableBuilder(
    column: $table.difficultyId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientRunKey => $composableBuilder(
    column: $table.clientRunKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAtUtcMs => $composableBuilder(
    column: $table.startedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get playedOnDay => $composableBuilder(
    column: $table.playedOnDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metricKind => $composableBuilder(
    column: $table.metricKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get metricValue => $composableBuilder(
    column: $table.metricValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCount => $composableBuilder(
    column: $table.correctCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wrongCount => $composableBuilder(
    column: $table.wrongCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestCombo => $composableBuilder(
    column: $table.longestCombo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalReactionMs => $composableBuilder(
    column: $table.totalReactionMs,
    builder: (column) => column,
  );
}

class $$RunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunsTable,
          RunRow,
          $$RunsTableFilterComposer,
          $$RunsTableOrderingComposer,
          $$RunsTableAnnotationComposer,
          $$RunsTableCreateCompanionBuilder,
          $$RunsTableUpdateCompanionBuilder,
          (RunRow, BaseReferences<_$AppDatabase, $RunsTable, RunRow>),
          RunRow,
          PrefetchHooks Function()
        > {
  $$RunsTableTableManager(_$AppDatabase db, $RunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int> rowRevision = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<String> gameId = const Value.absent(),
                Value<String> difficultyId = const Value.absent(),
                Value<String> clientRunKey = const Value.absent(),
                Value<int> startedAtUtcMs = const Value.absent(),
                Value<int> playedOnDay = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<String> metricKind = const Value.absent(),
                Value<int> metricValue = const Value.absent(),
                Value<int> correctCount = const Value.absent(),
                Value<int> wrongCount = const Value.absent(),
                Value<int> longestCombo = const Value.absent(),
                Value<int> totalReactionMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowRevision: rowRevision,
                isDeleted: isDeleted,
                deletedAtUtcMs: deletedAtUtcMs,
                gameId: gameId,
                difficultyId: difficultyId,
                clientRunKey: clientRunKey,
                startedAtUtcMs: startedAtUtcMs,
                playedOnDay: playedOnDay,
                durationMs: durationMs,
                metricKind: metricKind,
                metricValue: metricValue,
                correctCount: correctCount,
                wrongCount: wrongCount,
                longestCombo: longestCombo,
                totalReactionMs: totalReactionMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int> rowRevision = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                required String gameId,
                required String difficultyId,
                required String clientRunKey,
                required int startedAtUtcMs,
                required int playedOnDay,
                required int durationMs,
                required String metricKind,
                required int metricValue,
                required int correctCount,
                required int wrongCount,
                required int longestCombo,
                required int totalReactionMs,
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion.insert(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowRevision: rowRevision,
                isDeleted: isDeleted,
                deletedAtUtcMs: deletedAtUtcMs,
                gameId: gameId,
                difficultyId: difficultyId,
                clientRunKey: clientRunKey,
                startedAtUtcMs: startedAtUtcMs,
                playedOnDay: playedOnDay,
                durationMs: durationMs,
                metricKind: metricKind,
                metricValue: metricValue,
                correctCount: correctCount,
                wrongCount: wrongCount,
                longestCombo: longestCombo,
                totalReactionMs: totalReactionMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunsTable,
      RunRow,
      $$RunsTableFilterComposer,
      $$RunsTableOrderingComposer,
      $$RunsTableAnnotationComposer,
      $$RunsTableCreateCompanionBuilder,
      $$RunsTableUpdateCompanionBuilder,
      (RunRow, BaseReferences<_$AppDatabase, $RunsTable, RunRow>),
      RunRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      required String id,
      required int createdAtUtcMs,
      required int updatedAtUtcMs,
      Value<int> rowRevision,
      Value<int> isDeleted,
      Value<int?> deletedAtUtcMs,
      required int isSoundEnabled,
      required int isHapticsEnabled,
      required int isReduceMotionEnabled,
      required int isColourBlindPalette,
      Value<String?> localeTag,
      Value<int> rowid,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<String> id,
      Value<int> createdAtUtcMs,
      Value<int> updatedAtUtcMs,
      Value<int> rowRevision,
      Value<int> isDeleted,
      Value<int?> deletedAtUtcMs,
      Value<int> isSoundEnabled,
      Value<int> isHapticsEnabled,
      Value<int> isReduceMotionEnabled,
      Value<int> isColourBlindPalette,
      Value<String?> localeTag,
      Value<int> rowid,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
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

  ColumnFilters<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isSoundEnabled => $composableBuilder(
    column: $table.isSoundEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isHapticsEnabled => $composableBuilder(
    column: $table.isHapticsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isReduceMotionEnabled => $composableBuilder(
    column: $table.isReduceMotionEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isColourBlindPalette => $composableBuilder(
    column: $table.isColourBlindPalette,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localeTag => $composableBuilder(
    column: $table.localeTag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
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

  ColumnOrderings<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isSoundEnabled => $composableBuilder(
    column: $table.isSoundEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isHapticsEnabled => $composableBuilder(
    column: $table.isHapticsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isReduceMotionEnabled => $composableBuilder(
    column: $table.isReduceMotionEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isColourBlindPalette => $composableBuilder(
    column: $table.isColourBlindPalette,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localeTag => $composableBuilder(
    column: $table.localeTag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMs => $composableBuilder(
    column: $table.createdAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMs => $composableBuilder(
    column: $table.updatedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowRevision => $composableBuilder(
    column: $table.rowRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get deletedAtUtcMs => $composableBuilder(
    column: $table.deletedAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isSoundEnabled => $composableBuilder(
    column: $table.isSoundEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isHapticsEnabled => $composableBuilder(
    column: $table.isHapticsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isReduceMotionEnabled => $composableBuilder(
    column: $table.isReduceMotionEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isColourBlindPalette => $composableBuilder(
    column: $table.isColourBlindPalette,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localeTag =>
      $composableBuilder(column: $table.localeTag, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTableTable,
          SettingsRow,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> createdAtUtcMs = const Value.absent(),
                Value<int> updatedAtUtcMs = const Value.absent(),
                Value<int> rowRevision = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                Value<int> isSoundEnabled = const Value.absent(),
                Value<int> isHapticsEnabled = const Value.absent(),
                Value<int> isReduceMotionEnabled = const Value.absent(),
                Value<int> isColourBlindPalette = const Value.absent(),
                Value<String?> localeTag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowRevision: rowRevision,
                isDeleted: isDeleted,
                deletedAtUtcMs: deletedAtUtcMs,
                isSoundEnabled: isSoundEnabled,
                isHapticsEnabled: isHapticsEnabled,
                isReduceMotionEnabled: isReduceMotionEnabled,
                isColourBlindPalette: isColourBlindPalette,
                localeTag: localeTag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int createdAtUtcMs,
                required int updatedAtUtcMs,
                Value<int> rowRevision = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int?> deletedAtUtcMs = const Value.absent(),
                required int isSoundEnabled,
                required int isHapticsEnabled,
                required int isReduceMotionEnabled,
                required int isColourBlindPalette,
                Value<String?> localeTag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsTableCompanion.insert(
                id: id,
                createdAtUtcMs: createdAtUtcMs,
                updatedAtUtcMs: updatedAtUtcMs,
                rowRevision: rowRevision,
                isDeleted: isDeleted,
                deletedAtUtcMs: deletedAtUtcMs,
                isSoundEnabled: isSoundEnabled,
                isHapticsEnabled: isHapticsEnabled,
                isReduceMotionEnabled: isReduceMotionEnabled,
                isColourBlindPalette: isColourBlindPalette,
                localeTag: localeTag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTableTable,
      SettingsRow,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RunsTableTableManager get runs => $$RunsTableTableManager(_db, _db.runs);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
