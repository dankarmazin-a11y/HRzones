// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryMuscleMeta = const VerificationMeta('primaryMuscle');
  @override
  late final GeneratedColumn<String> primaryMuscle = GeneratedColumn<String>(
    'primary_muscle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondaryMusclesMeta = const VerificationMeta('secondaryMuscles');
  @override
  late final GeneratedColumn<String> secondaryMuscles = GeneratedColumn<String>(
    'secondary_muscles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta('equipment');
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('strength'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TrackingType, int> trackingType = GeneratedColumn<int>(
    'tracking_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<TrackingType>($ExercisesTable.$convertertrackingType);
  static const VerificationMeta _instructionsMeta = const VerificationMeta('instructions');
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta('isCustom');
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_custom" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _defaultRestSecondsMeta = const VerificationMeta('defaultRestSeconds');
  @override
  late final GeneratedColumn<int> defaultRestSeconds = GeneratedColumn<int>(
    'default_rest_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
  );
  static const VerificationMeta _popularityMeta = const VerificationMeta('popularity');
  @override
  late final GeneratedColumn<int> popularity = GeneratedColumn<int>(
    'popularity',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("hidden" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unilateralMeta = const VerificationMeta('unilateral');
  @override
  late final GeneratedColumn<bool> unilateral = GeneratedColumn<bool>(
    'unilateral',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("unilateral" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteAtMeta = const VerificationMeta('noteAt');
  @override
  late final GeneratedColumn<DateTime> noteAt = GeneratedColumn<DateTime>(
    'note_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    name,
    primaryMuscle,
    secondaryMuscles,
    equipment,
    category,
    trackingType,
    instructions,
    imagePath,
    isCustom,
    defaultRestSeconds,
    popularity,
    hidden,
    level,
    unilateral,
    note,
    noteAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(Insertable<Exercise> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('primary_muscle')) {
      context.handle(
        _primaryMuscleMeta,
        primaryMuscle.isAcceptableOrUnknown(data['primary_muscle']!, _primaryMuscleMeta),
      );
    } else if (isInserting) {
      context.missing(_primaryMuscleMeta);
    }
    if (data.containsKey('secondary_muscles')) {
      context.handle(
        _secondaryMusclesMeta,
        secondaryMuscles.isAcceptableOrUnknown(data['secondary_muscles']!, _secondaryMusclesMeta),
      );
    }
    if (data.containsKey('equipment')) {
      context.handle(_equipmentMeta, equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta));
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta, category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    }
    if (data.containsKey('instructions')) {
      context.handle(_instructionsMeta, instructions.isAcceptableOrUnknown(data['instructions']!, _instructionsMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta, imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('is_custom')) {
      context.handle(_isCustomMeta, isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta));
    }
    if (data.containsKey('default_rest_seconds')) {
      context.handle(
        _defaultRestSecondsMeta,
        defaultRestSeconds.isAcceptableOrUnknown(data['default_rest_seconds']!, _defaultRestSecondsMeta),
      );
    }
    if (data.containsKey('popularity')) {
      context.handle(_popularityMeta, popularity.isAcceptableOrUnknown(data['popularity']!, _popularityMeta));
    }
    if (data.containsKey('hidden')) {
      context.handle(_hiddenMeta, hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta));
    }
    if (data.containsKey('level')) {
      context.handle(_levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    }
    if (data.containsKey('unilateral')) {
      context.handle(_unilateralMeta, unilateral.isAcceptableOrUnknown(data['unilateral']!, _unilateralMeta));
    }
    if (data.containsKey('note')) {
      context.handle(_noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('note_at')) {
      context.handle(_noteAtMeta, noteAt.isAcceptableOrUnknown(data['note_at']!, _noteAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      primaryMuscle: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}primary_muscle'])!,
      secondaryMuscles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_muscles'],
      )!,
      equipment: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}equipment']),
      category: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      trackingType: $ExercisesTable.$convertertrackingType.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}tracking_type'])!,
      ),
      instructions: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}instructions'])!,
      imagePath: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      isCustom: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_custom'])!,
      defaultRestSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_rest_seconds'],
      )!,
      popularity: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}popularity']),
      hidden: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}hidden'])!,
      level: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}level']),
      unilateral: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}unilateral'])!,
      note: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}note']),
      noteAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}note_at']),
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TrackingType, int, int> $convertertrackingType = const EnumIndexConverter<TrackingType>(
    TrackingType.values,
  );
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final DateTime updatedAt;
  final String name;
  final String primaryMuscle;

  /// Comma-separated.
  final String secondaryMuscles;
  final String? equipment;
  final String category;
  final TrackingType trackingType;

  /// Steps separated by newlines.
  final String instructions;

  /// Relative path inside free-exercise-db, e.g. "Barbell_Squat/0.jpg".
  final String? imagePath;
  final bool isCustom;
  final int defaultRestSeconds;

  /// Lower = more popular (null = not ranked). Used to list the most popular
  /// exercises of a muscle group first.
  final int? popularity;

  /// Duplicates hidden from the list (kept so old workouts still show them).
  final bool hidden;

  /// "beginner" / "intermediate" / "expert" (from free-exercise-db).
  final String? level;

  /// Logged per side: every set is a left + right pair (user setting; the
  /// seed marks common one-sided exercises).
  final bool unilateral;

  /// The user's permanent note (shown as a sticky note in workouts).
  final String? note;
  final DateTime? noteAt;
  const Exercise({
    required this.id,
    required this.updatedAt,
    required this.name,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    this.equipment,
    required this.category,
    required this.trackingType,
    required this.instructions,
    this.imagePath,
    required this.isCustom,
    required this.defaultRestSeconds,
    this.popularity,
    required this.hidden,
    this.level,
    required this.unilateral,
    this.note,
    this.noteAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['primary_muscle'] = Variable<String>(primaryMuscle);
    map['secondary_muscles'] = Variable<String>(secondaryMuscles);
    if (!nullToAbsent || equipment != null) {
      map['equipment'] = Variable<String>(equipment);
    }
    map['category'] = Variable<String>(category);
    {
      map['tracking_type'] = Variable<int>($ExercisesTable.$convertertrackingType.toSql(trackingType));
    }
    map['instructions'] = Variable<String>(instructions);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_custom'] = Variable<bool>(isCustom);
    map['default_rest_seconds'] = Variable<int>(defaultRestSeconds);
    if (!nullToAbsent || popularity != null) {
      map['popularity'] = Variable<int>(popularity);
    }
    map['hidden'] = Variable<bool>(hidden);
    if (!nullToAbsent || level != null) {
      map['level'] = Variable<String>(level);
    }
    map['unilateral'] = Variable<bool>(unilateral);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || noteAt != null) {
      map['note_at'] = Variable<DateTime>(noteAt);
    }
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      name: Value(name),
      primaryMuscle: Value(primaryMuscle),
      secondaryMuscles: Value(secondaryMuscles),
      equipment: equipment == null && nullToAbsent ? const Value.absent() : Value(equipment),
      category: Value(category),
      trackingType: Value(trackingType),
      instructions: Value(instructions),
      imagePath: imagePath == null && nullToAbsent ? const Value.absent() : Value(imagePath),
      isCustom: Value(isCustom),
      defaultRestSeconds: Value(defaultRestSeconds),
      popularity: popularity == null && nullToAbsent ? const Value.absent() : Value(popularity),
      hidden: Value(hidden),
      level: level == null && nullToAbsent ? const Value.absent() : Value(level),
      unilateral: Value(unilateral),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      noteAt: noteAt == null && nullToAbsent ? const Value.absent() : Value(noteAt),
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      primaryMuscle: serializer.fromJson<String>(json['primaryMuscle']),
      secondaryMuscles: serializer.fromJson<String>(json['secondaryMuscles']),
      equipment: serializer.fromJson<String?>(json['equipment']),
      category: serializer.fromJson<String>(json['category']),
      trackingType: $ExercisesTable.$convertertrackingType.fromJson(serializer.fromJson<int>(json['trackingType'])),
      instructions: serializer.fromJson<String>(json['instructions']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      defaultRestSeconds: serializer.fromJson<int>(json['defaultRestSeconds']),
      popularity: serializer.fromJson<int?>(json['popularity']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      level: serializer.fromJson<String?>(json['level']),
      unilateral: serializer.fromJson<bool>(json['unilateral']),
      note: serializer.fromJson<String?>(json['note']),
      noteAt: serializer.fromJson<DateTime?>(json['noteAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'primaryMuscle': serializer.toJson<String>(primaryMuscle),
      'secondaryMuscles': serializer.toJson<String>(secondaryMuscles),
      'equipment': serializer.toJson<String?>(equipment),
      'category': serializer.toJson<String>(category),
      'trackingType': serializer.toJson<int>($ExercisesTable.$convertertrackingType.toJson(trackingType)),
      'instructions': serializer.toJson<String>(instructions),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isCustom': serializer.toJson<bool>(isCustom),
      'defaultRestSeconds': serializer.toJson<int>(defaultRestSeconds),
      'popularity': serializer.toJson<int?>(popularity),
      'hidden': serializer.toJson<bool>(hidden),
      'level': serializer.toJson<String?>(level),
      'unilateral': serializer.toJson<bool>(unilateral),
      'note': serializer.toJson<String?>(note),
      'noteAt': serializer.toJson<DateTime?>(noteAt),
    };
  }

  Exercise copyWith({
    String? id,
    DateTime? updatedAt,
    String? name,
    String? primaryMuscle,
    String? secondaryMuscles,
    Value<String?> equipment = const Value.absent(),
    String? category,
    TrackingType? trackingType,
    String? instructions,
    Value<String?> imagePath = const Value.absent(),
    bool? isCustom,
    int? defaultRestSeconds,
    Value<int?> popularity = const Value.absent(),
    bool? hidden,
    Value<String?> level = const Value.absent(),
    bool? unilateral,
    Value<String?> note = const Value.absent(),
    Value<DateTime?> noteAt = const Value.absent(),
  }) => Exercise(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    primaryMuscle: primaryMuscle ?? this.primaryMuscle,
    secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
    equipment: equipment.present ? equipment.value : this.equipment,
    category: category ?? this.category,
    trackingType: trackingType ?? this.trackingType,
    instructions: instructions ?? this.instructions,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    isCustom: isCustom ?? this.isCustom,
    defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
    popularity: popularity.present ? popularity.value : this.popularity,
    hidden: hidden ?? this.hidden,
    level: level.present ? level.value : this.level,
    unilateral: unilateral ?? this.unilateral,
    note: note.present ? note.value : this.note,
    noteAt: noteAt.present ? noteAt.value : this.noteAt,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      primaryMuscle: data.primaryMuscle.present ? data.primaryMuscle.value : this.primaryMuscle,
      secondaryMuscles: data.secondaryMuscles.present ? data.secondaryMuscles.value : this.secondaryMuscles,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      category: data.category.present ? data.category.value : this.category,
      trackingType: data.trackingType.present ? data.trackingType.value : this.trackingType,
      instructions: data.instructions.present ? data.instructions.value : this.instructions,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      defaultRestSeconds: data.defaultRestSeconds.present ? data.defaultRestSeconds.value : this.defaultRestSeconds,
      popularity: data.popularity.present ? data.popularity.value : this.popularity,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      level: data.level.present ? data.level.value : this.level,
      unilateral: data.unilateral.present ? data.unilateral.value : this.unilateral,
      note: data.note.present ? data.note.value : this.note,
      noteAt: data.noteAt.present ? data.noteAt.value : this.noteAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('primaryMuscle: $primaryMuscle, ')
          ..write('secondaryMuscles: $secondaryMuscles, ')
          ..write('equipment: $equipment, ')
          ..write('category: $category, ')
          ..write('trackingType: $trackingType, ')
          ..write('instructions: $instructions, ')
          ..write('imagePath: $imagePath, ')
          ..write('isCustom: $isCustom, ')
          ..write('defaultRestSeconds: $defaultRestSeconds, ')
          ..write('popularity: $popularity, ')
          ..write('hidden: $hidden, ')
          ..write('level: $level, ')
          ..write('unilateral: $unilateral, ')
          ..write('note: $note, ')
          ..write('noteAt: $noteAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    name,
    primaryMuscle,
    secondaryMuscles,
    equipment,
    category,
    trackingType,
    instructions,
    imagePath,
    isCustom,
    defaultRestSeconds,
    popularity,
    hidden,
    level,
    unilateral,
    note,
    noteAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.primaryMuscle == this.primaryMuscle &&
          other.secondaryMuscles == this.secondaryMuscles &&
          other.equipment == this.equipment &&
          other.category == this.category &&
          other.trackingType == this.trackingType &&
          other.instructions == this.instructions &&
          other.imagePath == this.imagePath &&
          other.isCustom == this.isCustom &&
          other.defaultRestSeconds == this.defaultRestSeconds &&
          other.popularity == this.popularity &&
          other.hidden == this.hidden &&
          other.level == this.level &&
          other.unilateral == this.unilateral &&
          other.note == this.note &&
          other.noteAt == this.noteAt);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String> primaryMuscle;
  final Value<String> secondaryMuscles;
  final Value<String?> equipment;
  final Value<String> category;
  final Value<TrackingType> trackingType;
  final Value<String> instructions;
  final Value<String?> imagePath;
  final Value<bool> isCustom;
  final Value<int> defaultRestSeconds;
  final Value<int?> popularity;
  final Value<bool> hidden;
  final Value<String?> level;
  final Value<bool> unilateral;
  final Value<String?> note;
  final Value<DateTime?> noteAt;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.primaryMuscle = const Value.absent(),
    this.secondaryMuscles = const Value.absent(),
    this.equipment = const Value.absent(),
    this.category = const Value.absent(),
    this.trackingType = const Value.absent(),
    this.instructions = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.defaultRestSeconds = const Value.absent(),
    this.popularity = const Value.absent(),
    this.hidden = const Value.absent(),
    this.level = const Value.absent(),
    this.unilateral = const Value.absent(),
    this.note = const Value.absent(),
    this.noteAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    required String primaryMuscle,
    this.secondaryMuscles = const Value.absent(),
    this.equipment = const Value.absent(),
    this.category = const Value.absent(),
    required TrackingType trackingType,
    this.instructions = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.defaultRestSeconds = const Value.absent(),
    this.popularity = const Value.absent(),
    this.hidden = const Value.absent(),
    this.level = const Value.absent(),
    this.unilateral = const Value.absent(),
    this.note = const Value.absent(),
    this.noteAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       primaryMuscle = Value(primaryMuscle),
       trackingType = Value(trackingType);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? primaryMuscle,
    Expression<String>? secondaryMuscles,
    Expression<String>? equipment,
    Expression<String>? category,
    Expression<int>? trackingType,
    Expression<String>? instructions,
    Expression<String>? imagePath,
    Expression<bool>? isCustom,
    Expression<int>? defaultRestSeconds,
    Expression<int>? popularity,
    Expression<bool>? hidden,
    Expression<String>? level,
    Expression<bool>? unilateral,
    Expression<String>? note,
    Expression<DateTime>? noteAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (primaryMuscle != null) 'primary_muscle': primaryMuscle,
      if (secondaryMuscles != null) 'secondary_muscles': secondaryMuscles,
      if (equipment != null) 'equipment': equipment,
      if (category != null) 'category': category,
      if (trackingType != null) 'tracking_type': trackingType,
      if (instructions != null) 'instructions': instructions,
      if (imagePath != null) 'image_path': imagePath,
      if (isCustom != null) 'is_custom': isCustom,
      if (defaultRestSeconds != null) 'default_rest_seconds': defaultRestSeconds,
      if (popularity != null) 'popularity': popularity,
      if (hidden != null) 'hidden': hidden,
      if (level != null) 'level': level,
      if (unilateral != null) 'unilateral': unilateral,
      if (note != null) 'note': note,
      if (noteAt != null) 'note_at': noteAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String>? primaryMuscle,
    Value<String>? secondaryMuscles,
    Value<String?>? equipment,
    Value<String>? category,
    Value<TrackingType>? trackingType,
    Value<String>? instructions,
    Value<String?>? imagePath,
    Value<bool>? isCustom,
    Value<int>? defaultRestSeconds,
    Value<int?>? popularity,
    Value<bool>? hidden,
    Value<String?>? level,
    Value<bool>? unilateral,
    Value<String?>? note,
    Value<DateTime?>? noteAt,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      equipment: equipment ?? this.equipment,
      category: category ?? this.category,
      trackingType: trackingType ?? this.trackingType,
      instructions: instructions ?? this.instructions,
      imagePath: imagePath ?? this.imagePath,
      isCustom: isCustom ?? this.isCustom,
      defaultRestSeconds: defaultRestSeconds ?? this.defaultRestSeconds,
      popularity: popularity ?? this.popularity,
      hidden: hidden ?? this.hidden,
      level: level ?? this.level,
      unilateral: unilateral ?? this.unilateral,
      note: note ?? this.note,
      noteAt: noteAt ?? this.noteAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (primaryMuscle.present) {
      map['primary_muscle'] = Variable<String>(primaryMuscle.value);
    }
    if (secondaryMuscles.present) {
      map['secondary_muscles'] = Variable<String>(secondaryMuscles.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (trackingType.present) {
      map['tracking_type'] = Variable<int>($ExercisesTable.$convertertrackingType.toSql(trackingType.value));
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (defaultRestSeconds.present) {
      map['default_rest_seconds'] = Variable<int>(defaultRestSeconds.value);
    }
    if (popularity.present) {
      map['popularity'] = Variable<int>(popularity.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (unilateral.present) {
      map['unilateral'] = Variable<bool>(unilateral.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (noteAt.present) {
      map['note_at'] = Variable<DateTime>(noteAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('primaryMuscle: $primaryMuscle, ')
          ..write('secondaryMuscles: $secondaryMuscles, ')
          ..write('equipment: $equipment, ')
          ..write('category: $category, ')
          ..write('trackingType: $trackingType, ')
          ..write('instructions: $instructions, ')
          ..write('imagePath: $imagePath, ')
          ..write('isCustom: $isCustom, ')
          ..write('defaultRestSeconds: $defaultRestSeconds, ')
          ..write('popularity: $popularity, ')
          ..write('hidden: $hidden, ')
          ..write('level: $level, ')
          ..write('unilateral: $unilateral, ')
          ..write('note: $note, ')
          ..write('noteAt: $noteAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates with TableInfo<$TemplatesTable, Template> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrPresetIdMeta = const VerificationMeta('hrPresetId');
  @override
  late final GeneratedColumn<String> hrPresetId = GeneratedColumn<String>(
    'hr_preset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, name, folder, hrPresetId, notes, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(Insertable<Template> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(_folderMeta, folder.isAcceptableOrUnknown(data['folder']!, _folderMeta));
    }
    if (data.containsKey('hr_preset_id')) {
      context.handle(_hrPresetIdMeta, hrPresetId.isAcceptableOrUnknown(data['hr_preset_id']!, _hrPresetIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Template map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Template(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      folder: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}folder']),
      hrPresetId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hr_preset_id']),
      notes: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class Template extends DataClass implements Insertable<Template> {
  final String id;
  final DateTime updatedAt;
  final String name;
  final String? folder;

  /// Heart-rate zone preset applied when the template is started.
  final String? hrPresetId;
  final String notes;
  final int position;
  const Template({
    required this.id,
    required this.updatedAt,
    required this.name,
    this.folder,
    this.hrPresetId,
    required this.notes,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || folder != null) {
      map['folder'] = Variable<String>(folder);
    }
    if (!nullToAbsent || hrPresetId != null) {
      map['hr_preset_id'] = Variable<String>(hrPresetId);
    }
    map['notes'] = Variable<String>(notes);
    map['position'] = Variable<int>(position);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      name: Value(name),
      folder: folder == null && nullToAbsent ? const Value.absent() : Value(folder),
      hrPresetId: hrPresetId == null && nullToAbsent ? const Value.absent() : Value(hrPresetId),
      notes: Value(notes),
      position: Value(position),
    );
  }

  factory Template.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Template(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      folder: serializer.fromJson<String?>(json['folder']),
      hrPresetId: serializer.fromJson<String?>(json['hrPresetId']),
      notes: serializer.fromJson<String>(json['notes']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'folder': serializer.toJson<String?>(folder),
      'hrPresetId': serializer.toJson<String?>(hrPresetId),
      'notes': serializer.toJson<String>(notes),
      'position': serializer.toJson<int>(position),
    };
  }

  Template copyWith({
    String? id,
    DateTime? updatedAt,
    String? name,
    Value<String?> folder = const Value.absent(),
    Value<String?> hrPresetId = const Value.absent(),
    String? notes,
    int? position,
  }) => Template(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    folder: folder.present ? folder.value : this.folder,
    hrPresetId: hrPresetId.present ? hrPresetId.value : this.hrPresetId,
    notes: notes ?? this.notes,
    position: position ?? this.position,
  );
  Template copyWithCompanion(TemplatesCompanion data) {
    return Template(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      folder: data.folder.present ? data.folder.value : this.folder,
      hrPresetId: data.hrPresetId.present ? data.hrPresetId.value : this.hrPresetId,
      notes: data.notes.present ? data.notes.value : this.notes,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Template(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('folder: $folder, ')
          ..write('hrPresetId: $hrPresetId, ')
          ..write('notes: $notes, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, name, folder, hrPresetId, notes, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Template &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.folder == this.folder &&
          other.hrPresetId == this.hrPresetId &&
          other.notes == this.notes &&
          other.position == this.position);
}

class TemplatesCompanion extends UpdateCompanion<Template> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String?> folder;
  final Value<String?> hrPresetId;
  final Value<String> notes;
  final Value<int> position;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.folder = const Value.absent(),
    this.hrPresetId = const Value.absent(),
    this.notes = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    this.folder = const Value.absent(),
    this.hrPresetId = const Value.absent(),
    this.notes = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Template> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? folder,
    Expression<String>? hrPresetId,
    Expression<String>? notes,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (folder != null) 'folder': folder,
      if (hrPresetId != null) 'hr_preset_id': hrPresetId,
      if (notes != null) 'notes': notes,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String?>? folder,
    Value<String?>? hrPresetId,
    Value<String>? notes,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      folder: folder ?? this.folder,
      hrPresetId: hrPresetId ?? this.hrPresetId,
      notes: notes ?? this.notes,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (hrPresetId.present) {
      map['hr_preset_id'] = Variable<String>(hrPresetId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('folder: $folder, ')
          ..write('hrPresetId: $hrPresetId, ')
          ..write('notes: $notes, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateExercisesTable extends TemplateExercises with TableInfo<$TemplateExercisesTable, TemplateExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES templates (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta('targetSets');
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta('restSeconds');
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
  );
  static const VerificationMeta _supersetGroupMeta = const VerificationMeta('supersetGroup');
  @override
  late final GeneratedColumn<int> supersetGroup = GeneratedColumn<int>(
    'superset_group',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subExerciseIdsMeta = const VerificationMeta('subExerciseIds');
  @override
  late final GeneratedColumn<String> subExerciseIds = GeneratedColumn<String>(
    'sub_exercise_ids',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _setsJsonMeta = const VerificationMeta('setsJson');
  @override
  late final GeneratedColumn<String> setsJson = GeneratedColumn<String>(
    'sets_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    templateId,
    exerciseId,
    position,
    targetSets,
    restSeconds,
    supersetGroup,
    subExerciseIds,
    setsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<TemplateExercise> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(_templateIdMeta, templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta));
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(_exerciseIdMeta, exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(_targetSetsMeta, targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta));
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(_restSecondsMeta, restSeconds.isAcceptableOrUnknown(data['rest_seconds']!, _restSecondsMeta));
    }
    if (data.containsKey('superset_group')) {
      context.handle(
        _supersetGroupMeta,
        supersetGroup.isAcceptableOrUnknown(data['superset_group']!, _supersetGroupMeta),
      );
    }
    if (data.containsKey('sub_exercise_ids')) {
      context.handle(
        _subExerciseIdsMeta,
        subExerciseIds.isAcceptableOrUnknown(data['sub_exercise_ids']!, _subExerciseIdsMeta),
      );
    }
    if (data.containsKey('sets_json')) {
      context.handle(_setsJsonMeta, setsJson.isAcceptableOrUnknown(data['sets_json']!, _setsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateExercise(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      templateId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}template_id'])!,
      exerciseId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      targetSets: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}target_sets'])!,
      restSeconds: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}rest_seconds'])!,
      supersetGroup: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}superset_group']),
      subExerciseIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_exercise_ids'],
      ),
      setsJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}sets_json']),
    );
  }

  @override
  $TemplateExercisesTable createAlias(String alias) {
    return $TemplateExercisesTable(attachedDatabase, alias);
  }
}

class TemplateExercise extends DataClass implements Insertable<TemplateExercise> {
  final String id;
  final DateTime updatedAt;
  final String templateId;
  final String exerciseId;
  final int position;
  final int targetSets;
  final int restSeconds;
  final int? supersetGroup;

  /// For the "Stretching" session slot: the stretches, comma-separated ids.
  final String? subExerciseIds;

  /// Target sets as JSON: [{"t": setType, "w": kg, "r": reps, "s": seconds}].
  final String? setsJson;
  const TemplateExercise({
    required this.id,
    required this.updatedAt,
    required this.templateId,
    required this.exerciseId,
    required this.position,
    required this.targetSets,
    required this.restSeconds,
    this.supersetGroup,
    this.subExerciseIds,
    this.setsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['template_id'] = Variable<String>(templateId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    map['target_sets'] = Variable<int>(targetSets);
    map['rest_seconds'] = Variable<int>(restSeconds);
    if (!nullToAbsent || supersetGroup != null) {
      map['superset_group'] = Variable<int>(supersetGroup);
    }
    if (!nullToAbsent || subExerciseIds != null) {
      map['sub_exercise_ids'] = Variable<String>(subExerciseIds);
    }
    if (!nullToAbsent || setsJson != null) {
      map['sets_json'] = Variable<String>(setsJson);
    }
    return map;
  }

  TemplateExercisesCompanion toCompanion(bool nullToAbsent) {
    return TemplateExercisesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      templateId: Value(templateId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      targetSets: Value(targetSets),
      restSeconds: Value(restSeconds),
      supersetGroup: supersetGroup == null && nullToAbsent ? const Value.absent() : Value(supersetGroup),
      subExerciseIds: subExerciseIds == null && nullToAbsent ? const Value.absent() : Value(subExerciseIds),
      setsJson: setsJson == null && nullToAbsent ? const Value.absent() : Value(setsJson),
    );
  }

  factory TemplateExercise.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateExercise(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      templateId: serializer.fromJson<String>(json['templateId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      targetSets: serializer.fromJson<int>(json['targetSets']),
      restSeconds: serializer.fromJson<int>(json['restSeconds']),
      supersetGroup: serializer.fromJson<int?>(json['supersetGroup']),
      subExerciseIds: serializer.fromJson<String?>(json['subExerciseIds']),
      setsJson: serializer.fromJson<String?>(json['setsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'templateId': serializer.toJson<String>(templateId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'targetSets': serializer.toJson<int>(targetSets),
      'restSeconds': serializer.toJson<int>(restSeconds),
      'supersetGroup': serializer.toJson<int?>(supersetGroup),
      'subExerciseIds': serializer.toJson<String?>(subExerciseIds),
      'setsJson': serializer.toJson<String?>(setsJson),
    };
  }

  TemplateExercise copyWith({
    String? id,
    DateTime? updatedAt,
    String? templateId,
    String? exerciseId,
    int? position,
    int? targetSets,
    int? restSeconds,
    Value<int?> supersetGroup = const Value.absent(),
    Value<String?> subExerciseIds = const Value.absent(),
    Value<String?> setsJson = const Value.absent(),
  }) => TemplateExercise(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    templateId: templateId ?? this.templateId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    targetSets: targetSets ?? this.targetSets,
    restSeconds: restSeconds ?? this.restSeconds,
    supersetGroup: supersetGroup.present ? supersetGroup.value : this.supersetGroup,
    subExerciseIds: subExerciseIds.present ? subExerciseIds.value : this.subExerciseIds,
    setsJson: setsJson.present ? setsJson.value : this.setsJson,
  );
  TemplateExercise copyWithCompanion(TemplateExercisesCompanion data) {
    return TemplateExercise(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      templateId: data.templateId.present ? data.templateId.value : this.templateId,
      exerciseId: data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      targetSets: data.targetSets.present ? data.targetSets.value : this.targetSets,
      restSeconds: data.restSeconds.present ? data.restSeconds.value : this.restSeconds,
      supersetGroup: data.supersetGroup.present ? data.supersetGroup.value : this.supersetGroup,
      subExerciseIds: data.subExerciseIds.present ? data.subExerciseIds.value : this.subExerciseIds,
      setsJson: data.setsJson.present ? data.setsJson.value : this.setsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercise(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('subExerciseIds: $subExerciseIds, ')
          ..write('setsJson: $setsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    templateId,
    exerciseId,
    position,
    targetSets,
    restSeconds,
    supersetGroup,
    subExerciseIds,
    setsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateExercise &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.templateId == this.templateId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.targetSets == this.targetSets &&
          other.restSeconds == this.restSeconds &&
          other.supersetGroup == this.supersetGroup &&
          other.subExerciseIds == this.subExerciseIds &&
          other.setsJson == this.setsJson);
}

class TemplateExercisesCompanion extends UpdateCompanion<TemplateExercise> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> templateId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<int> targetSets;
  final Value<int> restSeconds;
  final Value<int?> supersetGroup;
  final Value<String?> subExerciseIds;
  final Value<String?> setsJson;
  final Value<int> rowid;
  const TemplateExercisesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.templateId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.subExerciseIds = const Value.absent(),
    this.setsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateExercisesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String templateId,
    required String exerciseId,
    required int position,
    this.targetSets = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.subExerciseIds = const Value.absent(),
    this.setsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : templateId = Value(templateId),
       exerciseId = Value(exerciseId),
       position = Value(position);
  static Insertable<TemplateExercise> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? templateId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<int>? targetSets,
    Expression<int>? restSeconds,
    Expression<int>? supersetGroup,
    Expression<String>? subExerciseIds,
    Expression<String>? setsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (templateId != null) 'template_id': templateId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (targetSets != null) 'target_sets': targetSets,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (supersetGroup != null) 'superset_group': supersetGroup,
      if (subExerciseIds != null) 'sub_exercise_ids': subExerciseIds,
      if (setsJson != null) 'sets_json': setsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateExercisesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? templateId,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<int>? targetSets,
    Value<int>? restSeconds,
    Value<int?>? supersetGroup,
    Value<String?>? subExerciseIds,
    Value<String?>? setsJson,
    Value<int>? rowid,
  }) {
    return TemplateExercisesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      templateId: templateId ?? this.templateId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      targetSets: targetSets ?? this.targetSets,
      restSeconds: restSeconds ?? this.restSeconds,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      subExerciseIds: subExerciseIds ?? this.subExerciseIds,
      setsJson: setsJson ?? this.setsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (supersetGroup.present) {
      map['superset_group'] = Variable<int>(supersetGroup.value);
    }
    if (subExerciseIds.present) {
      map['sub_exercise_ids'] = Variable<String>(subExerciseIds.value);
    }
    if (setsJson.present) {
      map['sets_json'] = Variable<String>(setsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercisesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('subExerciseIds: $subExerciseIds, ')
          ..write('setsJson: $setsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WorkoutType, int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<WorkoutType>($WorkoutsTable.$convertertype);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hrPresetIdMeta = const VerificationMeta('hrPresetId');
  @override
  late final GeneratedColumn<String> hrPresetId = GeneratedColumn<String>(
    'hr_preset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<int> avgHr = GeneratedColumn<int>(
    'avg_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHrMeta = const VerificationMeta('maxHr');
  @override
  late final GeneratedColumn<int> maxHr = GeneratedColumn<int>(
    'max_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    type,
    name,
    startedAt,
    endedAt,
    templateId,
    hrPresetId,
    notes,
    avgHr,
    maxHr,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(Insertable<Workout> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta, endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(_templateIdMeta, templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta));
    }
    if (data.containsKey('hr_preset_id')) {
      context.handle(_hrPresetIdMeta, hrPresetId.isAcceptableOrUnknown(data['hr_preset_id']!, _hrPresetIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('avg_hr')) {
      context.handle(_avgHrMeta, avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta));
    }
    if (data.containsKey('max_hr')) {
      context.handle(_maxHrMeta, maxHr.isAcceptableOrUnknown(data['max_hr']!, _maxHrMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      type: $WorkoutsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}type'])!,
      ),
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      startedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      templateId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}template_id']),
      hrPresetId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hr_preset_id']),
      notes: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      avgHr: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}avg_hr']),
      maxHr: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}max_hr']),
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WorkoutType, int, int> $convertertype = const EnumIndexConverter<WorkoutType>(
    WorkoutType.values,
  );
}

class Workout extends DataClass implements Insertable<Workout> {
  final String id;
  final DateTime updatedAt;
  final WorkoutType type;
  final String name;
  final DateTime startedAt;

  /// Null while the workout is in progress.
  final DateTime? endedAt;
  final String? templateId;
  final String? hrPresetId;
  final String notes;
  final int? avgHr;
  final int? maxHr;
  const Workout({
    required this.id,
    required this.updatedAt,
    required this.type,
    required this.name,
    required this.startedAt,
    this.endedAt,
    this.templateId,
    this.hrPresetId,
    required this.notes,
    this.avgHr,
    this.maxHr,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['type'] = Variable<int>($WorkoutsTable.$convertertype.toSql(type));
    }
    map['name'] = Variable<String>(name);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    if (!nullToAbsent || hrPresetId != null) {
      map['hr_preset_id'] = Variable<String>(hrPresetId);
    }
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || avgHr != null) {
      map['avg_hr'] = Variable<int>(avgHr);
    }
    if (!nullToAbsent || maxHr != null) {
      map['max_hr'] = Variable<int>(maxHr);
    }
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      type: Value(type),
      name: Value(name),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent ? const Value.absent() : Value(endedAt),
      templateId: templateId == null && nullToAbsent ? const Value.absent() : Value(templateId),
      hrPresetId: hrPresetId == null && nullToAbsent ? const Value.absent() : Value(hrPresetId),
      notes: Value(notes),
      avgHr: avgHr == null && nullToAbsent ? const Value.absent() : Value(avgHr),
      maxHr: maxHr == null && nullToAbsent ? const Value.absent() : Value(maxHr),
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      type: $WorkoutsTable.$convertertype.fromJson(serializer.fromJson<int>(json['type'])),
      name: serializer.fromJson<String>(json['name']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      hrPresetId: serializer.fromJson<String?>(json['hrPresetId']),
      notes: serializer.fromJson<String>(json['notes']),
      avgHr: serializer.fromJson<int?>(json['avgHr']),
      maxHr: serializer.fromJson<int?>(json['maxHr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'type': serializer.toJson<int>($WorkoutsTable.$convertertype.toJson(type)),
      'name': serializer.toJson<String>(name),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'templateId': serializer.toJson<String?>(templateId),
      'hrPresetId': serializer.toJson<String?>(hrPresetId),
      'notes': serializer.toJson<String>(notes),
      'avgHr': serializer.toJson<int?>(avgHr),
      'maxHr': serializer.toJson<int?>(maxHr),
    };
  }

  Workout copyWith({
    String? id,
    DateTime? updatedAt,
    WorkoutType? type,
    String? name,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<String?> templateId = const Value.absent(),
    Value<String?> hrPresetId = const Value.absent(),
    String? notes,
    Value<int?> avgHr = const Value.absent(),
    Value<int?> maxHr = const Value.absent(),
  }) => Workout(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    type: type ?? this.type,
    name: name ?? this.name,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    templateId: templateId.present ? templateId.value : this.templateId,
    hrPresetId: hrPresetId.present ? hrPresetId.value : this.hrPresetId,
    notes: notes ?? this.notes,
    avgHr: avgHr.present ? avgHr.value : this.avgHr,
    maxHr: maxHr.present ? maxHr.value : this.maxHr,
  );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      type: data.type.present ? data.type.value : this.type,
      name: data.name.present ? data.name.value : this.name,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      templateId: data.templateId.present ? data.templateId.value : this.templateId,
      hrPresetId: data.hrPresetId.present ? data.hrPresetId.value : this.hrPresetId,
      notes: data.notes.present ? data.notes.value : this.notes,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      maxHr: data.maxHr.present ? data.maxHr.value : this.maxHr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('templateId: $templateId, ')
          ..write('hrPresetId: $hrPresetId, ')
          ..write('notes: $notes, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, type, name, startedAt, endedAt, templateId, hrPresetId, notes, avgHr, maxHr);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.type == this.type &&
          other.name == this.name &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.templateId == this.templateId &&
          other.hrPresetId == this.hrPresetId &&
          other.notes == this.notes &&
          other.avgHr == this.avgHr &&
          other.maxHr == this.maxHr);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<WorkoutType> type;
  final Value<String> name;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String?> templateId;
  final Value<String?> hrPresetId;
  final Value<String> notes;
  final Value<int?> avgHr;
  final Value<int?> maxHr;
  final Value<int> rowid;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.type = const Value.absent(),
    this.name = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.templateId = const Value.absent(),
    this.hrPresetId = const Value.absent(),
    this.notes = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required WorkoutType type,
    required String name,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.templateId = const Value.absent(),
    this.hrPresetId = const Value.absent(),
    this.notes = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : type = Value(type),
       name = Value(name),
       startedAt = Value(startedAt);
  static Insertable<Workout> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<int>? type,
    Expression<String>? name,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? templateId,
    Expression<String>? hrPresetId,
    Expression<String>? notes,
    Expression<int>? avgHr,
    Expression<int>? maxHr,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (templateId != null) 'template_id': templateId,
      if (hrPresetId != null) 'hr_preset_id': hrPresetId,
      if (notes != null) 'notes': notes,
      if (avgHr != null) 'avg_hr': avgHr,
      if (maxHr != null) 'max_hr': maxHr,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<WorkoutType>? type,
    Value<String>? name,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String?>? templateId,
    Value<String?>? hrPresetId,
    Value<String>? notes,
    Value<int?>? avgHr,
    Value<int?>? maxHr,
    Value<int>? rowid,
  }) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      templateId: templateId ?? this.templateId,
      hrPresetId: hrPresetId ?? this.hrPresetId,
      notes: notes ?? this.notes,
      avgHr: avgHr ?? this.avgHr,
      maxHr: maxHr ?? this.maxHr,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (type.present) {
      map['type'] = Variable<int>($WorkoutsTable.$convertertype.toSql(type.value));
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (hrPresetId.present) {
      map['hr_preset_id'] = Variable<String>(hrPresetId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<int>(avgHr.value);
    }
    if (maxHr.present) {
      map['max_hr'] = Variable<int>(maxHr.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('templateId: $templateId, ')
          ..write('hrPresetId: $hrPresetId, ')
          ..write('notes: $notes, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutExercisesTable extends WorkoutExercises with TableInfo<$WorkoutExercisesTable, WorkoutExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES workouts (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restSecondsMeta = const VerificationMeta('restSeconds');
  @override
  late final GeneratedColumn<int> restSeconds = GeneratedColumn<int>(
    'rest_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(90),
  );
  static const VerificationMeta _supersetGroupMeta = const VerificationMeta('supersetGroup');
  @override
  late final GeneratedColumn<int> supersetGroup = GeneratedColumn<int>(
    'superset_group',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    workoutId,
    exerciseId,
    position,
    restSeconds,
    supersetGroup,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_exercises';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutExercise> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta, workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(_exerciseIdMeta, exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('rest_seconds')) {
      context.handle(_restSecondsMeta, restSeconds.isAcceptableOrUnknown(data['rest_seconds']!, _restSecondsMeta));
    }
    if (data.containsKey('superset_group')) {
      context.handle(
        _supersetGroupMeta,
        supersetGroup.isAcceptableOrUnknown(data['superset_group']!, _supersetGroupMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutExercise(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      workoutId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}workout_id'])!,
      exerciseId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      restSeconds: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}rest_seconds'])!,
      supersetGroup: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}superset_group']),
      notes: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
    );
  }

  @override
  $WorkoutExercisesTable createAlias(String alias) {
    return $WorkoutExercisesTable(attachedDatabase, alias);
  }
}

class WorkoutExercise extends DataClass implements Insertable<WorkoutExercise> {
  final String id;
  final DateTime updatedAt;
  final String workoutId;
  final String exerciseId;
  final int position;
  final int restSeconds;
  final int? supersetGroup;
  final String notes;
  const WorkoutExercise({
    required this.id,
    required this.updatedAt,
    required this.workoutId,
    required this.exerciseId,
    required this.position,
    required this.restSeconds,
    this.supersetGroup,
    required this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workout_id'] = Variable<String>(workoutId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    map['rest_seconds'] = Variable<int>(restSeconds);
    if (!nullToAbsent || supersetGroup != null) {
      map['superset_group'] = Variable<int>(supersetGroup);
    }
    map['notes'] = Variable<String>(notes);
    return map;
  }

  WorkoutExercisesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutExercisesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      restSeconds: Value(restSeconds),
      supersetGroup: supersetGroup == null && nullToAbsent ? const Value.absent() : Value(supersetGroup),
      notes: Value(notes),
    );
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutExercise(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      restSeconds: serializer.fromJson<int>(json['restSeconds']),
      supersetGroup: serializer.fromJson<int?>(json['supersetGroup']),
      notes: serializer.fromJson<String>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workoutId': serializer.toJson<String>(workoutId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'restSeconds': serializer.toJson<int>(restSeconds),
      'supersetGroup': serializer.toJson<int?>(supersetGroup),
      'notes': serializer.toJson<String>(notes),
    };
  }

  WorkoutExercise copyWith({
    String? id,
    DateTime? updatedAt,
    String? workoutId,
    String? exerciseId,
    int? position,
    int? restSeconds,
    Value<int?> supersetGroup = const Value.absent(),
    String? notes,
  }) => WorkoutExercise(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    workoutId: workoutId ?? this.workoutId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    restSeconds: restSeconds ?? this.restSeconds,
    supersetGroup: supersetGroup.present ? supersetGroup.value : this.supersetGroup,
    notes: notes ?? this.notes,
  );
  WorkoutExercise copyWithCompanion(WorkoutExercisesCompanion data) {
    return WorkoutExercise(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      exerciseId: data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      restSeconds: data.restSeconds.present ? data.restSeconds.value : this.restSeconds,
      supersetGroup: data.supersetGroup.present ? data.supersetGroup.value : this.supersetGroup,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExercise(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, workoutId, exerciseId, position, restSeconds, supersetGroup, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutExercise &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.workoutId == this.workoutId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.restSeconds == this.restSeconds &&
          other.supersetGroup == this.supersetGroup &&
          other.notes == this.notes);
}

class WorkoutExercisesCompanion extends UpdateCompanion<WorkoutExercise> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> workoutId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<int> restSeconds;
  final Value<int?> supersetGroup;
  final Value<String> notes;
  final Value<int> rowid;
  const WorkoutExercisesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.restSeconds = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutExercisesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workoutId,
    required String exerciseId,
    required int position,
    this.restSeconds = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workoutId = Value(workoutId),
       exerciseId = Value(exerciseId),
       position = Value(position);
  static Insertable<WorkoutExercise> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? workoutId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<int>? restSeconds,
    Expression<int>? supersetGroup,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workoutId != null) 'workout_id': workoutId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (restSeconds != null) 'rest_seconds': restSeconds,
      if (supersetGroup != null) 'superset_group': supersetGroup,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutExercisesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? workoutId,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<int>? restSeconds,
    Value<int?>? supersetGroup,
    Value<String>? notes,
    Value<int>? rowid,
  }) {
    return WorkoutExercisesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      restSeconds: restSeconds ?? this.restSeconds,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (restSeconds.present) {
      map['rest_seconds'] = Variable<int>(restSeconds.value);
    }
    if (supersetGroup.present) {
      map['superset_group'] = Variable<int>(supersetGroup.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutExercisesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workoutId: $workoutId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('restSeconds: $restSeconds, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSetsTable extends WorkoutSets with TableInfo<$WorkoutSetsTable, WorkoutSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES workouts (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _workoutExerciseIdMeta = const VerificationMeta('workoutExerciseId');
  @override
  late final GeneratedColumn<String> workoutExerciseId = GeneratedColumn<String>(
    'workout_exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES workout_exercises (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES exercises (id)'),
  );
  static const VerificationMeta _setIndexMeta = const VerificationMeta('setIndex');
  @override
  late final GeneratedColumn<int> setIndex = GeneratedColumn<int>(
    'set_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SetType, int> setType = GeneratedColumn<int>(
    'set_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  ).withConverter<SetType>($WorkoutSetsTable.$convertersetType);
  static const VerificationMeta _weightKgMeta = const VerificationMeta('weightKg');
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta('durationS');
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta('distanceM');
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rpeMeta = const VerificationMeta('rpe');
  @override
  late final GeneratedColumn<double> rpe = GeneratedColumn<double>(
    'rpe',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subExerciseIdMeta = const VerificationMeta('subExerciseId');
  @override
  late final GeneratedColumn<String> subExerciseId = GeneratedColumn<String>(
    'sub_exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Side?, int> side = GeneratedColumn<int>(
    'side',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<Side?>($WorkoutSetsTable.$convertersiden);
  static const VerificationMeta _maxHrMeta = const VerificationMeta('maxHr');
  @override
  late final GeneratedColumn<int> maxHr = GeneratedColumn<int>(
    'max_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    workoutId,
    workoutExerciseId,
    exerciseId,
    setIndex,
    setType,
    weightKg,
    reps,
    durationS,
    distanceM,
    rpe,
    subExerciseId,
    side,
    maxHr,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sets';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutSet> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta, workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('workout_exercise_id')) {
      context.handle(
        _workoutExerciseIdMeta,
        workoutExerciseId.isAcceptableOrUnknown(data['workout_exercise_id']!, _workoutExerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutExerciseIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(_exerciseIdMeta, exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('set_index')) {
      context.handle(_setIndexMeta, setIndex.isAcceptableOrUnknown(data['set_index']!, _setIndexMeta));
    } else if (isInserting) {
      context.missing(_setIndexMeta);
    }
    if (data.containsKey('weight_kg')) {
      context.handle(_weightKgMeta, weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta));
    }
    if (data.containsKey('reps')) {
      context.handle(_repsMeta, reps.isAcceptableOrUnknown(data['reps']!, _repsMeta));
    }
    if (data.containsKey('duration_s')) {
      context.handle(_durationSMeta, durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta));
    }
    if (data.containsKey('distance_m')) {
      context.handle(_distanceMMeta, distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta));
    }
    if (data.containsKey('rpe')) {
      context.handle(_rpeMeta, rpe.isAcceptableOrUnknown(data['rpe']!, _rpeMeta));
    }
    if (data.containsKey('sub_exercise_id')) {
      context.handle(
        _subExerciseIdMeta,
        subExerciseId.isAcceptableOrUnknown(data['sub_exercise_id']!, _subExerciseIdMeta),
      );
    }
    if (data.containsKey('max_hr')) {
      context.handle(_maxHrMeta, maxHr.isAcceptableOrUnknown(data['max_hr']!, _maxHrMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(_completedAtMeta, completedAt.isAcceptableOrUnknown(data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSet(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      workoutId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}workout_id'])!,
      workoutExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workout_exercise_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      setIndex: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}set_index'])!,
      setType: $WorkoutSetsTable.$convertersetType.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}set_type'])!,
      ),
      weightKg: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}weight_kg']),
      reps: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}reps']),
      durationS: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_s']),
      distanceM: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}distance_m']),
      rpe: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}rpe']),
      subExerciseId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}sub_exercise_id']),
      side: $WorkoutSetsTable.$convertersiden.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}side']),
      ),
      maxHr: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}max_hr']),
      completedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $WorkoutSetsTable createAlias(String alias) {
    return $WorkoutSetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SetType, int, int> $convertersetType = const EnumIndexConverter<SetType>(SetType.values);
  static JsonTypeConverter2<Side, int, int> $converterside = const EnumIndexConverter<Side>(Side.values);
  static JsonTypeConverter2<Side?, int?, int?> $convertersiden = JsonTypeConverter2.asNullable($converterside);
}

class WorkoutSet extends DataClass implements Insertable<WorkoutSet> {
  final String id;
  final DateTime updatedAt;
  final String workoutId;
  final String workoutExerciseId;
  final String exerciseId;
  final int setIndex;
  final SetType setType;
  final double? weightKg;
  final int? reps;
  final int? durationS;
  final double? distanceM;
  final double? rpe;

  /// In a "Stretching" session: which stretch this row is.
  final String? subExerciseId;

  /// Left / right for one-sided exercises (null = both sides / not split).
  final Side? side;
  final int? maxHr;

  /// Null = not completed (not counted in stats).
  final DateTime? completedAt;
  const WorkoutSet({
    required this.id,
    required this.updatedAt,
    required this.workoutId,
    required this.workoutExerciseId,
    required this.exerciseId,
    required this.setIndex,
    required this.setType,
    this.weightKg,
    this.reps,
    this.durationS,
    this.distanceM,
    this.rpe,
    this.subExerciseId,
    this.side,
    this.maxHr,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['workout_id'] = Variable<String>(workoutId);
    map['workout_exercise_id'] = Variable<String>(workoutExerciseId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['set_index'] = Variable<int>(setIndex);
    {
      map['set_type'] = Variable<int>($WorkoutSetsTable.$convertersetType.toSql(setType));
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || durationS != null) {
      map['duration_s'] = Variable<int>(durationS);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    if (!nullToAbsent || rpe != null) {
      map['rpe'] = Variable<double>(rpe);
    }
    if (!nullToAbsent || subExerciseId != null) {
      map['sub_exercise_id'] = Variable<String>(subExerciseId);
    }
    if (!nullToAbsent || side != null) {
      map['side'] = Variable<int>($WorkoutSetsTable.$convertersiden.toSql(side));
    }
    if (!nullToAbsent || maxHr != null) {
      map['max_hr'] = Variable<int>(maxHr);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  WorkoutSetsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSetsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      workoutId: Value(workoutId),
      workoutExerciseId: Value(workoutExerciseId),
      exerciseId: Value(exerciseId),
      setIndex: Value(setIndex),
      setType: Value(setType),
      weightKg: weightKg == null && nullToAbsent ? const Value.absent() : Value(weightKg),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      durationS: durationS == null && nullToAbsent ? const Value.absent() : Value(durationS),
      distanceM: distanceM == null && nullToAbsent ? const Value.absent() : Value(distanceM),
      rpe: rpe == null && nullToAbsent ? const Value.absent() : Value(rpe),
      subExerciseId: subExerciseId == null && nullToAbsent ? const Value.absent() : Value(subExerciseId),
      side: side == null && nullToAbsent ? const Value.absent() : Value(side),
      maxHr: maxHr == null && nullToAbsent ? const Value.absent() : Value(maxHr),
      completedAt: completedAt == null && nullToAbsent ? const Value.absent() : Value(completedAt),
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSet(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      workoutExerciseId: serializer.fromJson<String>(json['workoutExerciseId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      setIndex: serializer.fromJson<int>(json['setIndex']),
      setType: $WorkoutSetsTable.$convertersetType.fromJson(serializer.fromJson<int>(json['setType'])),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      reps: serializer.fromJson<int?>(json['reps']),
      durationS: serializer.fromJson<int?>(json['durationS']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
      rpe: serializer.fromJson<double?>(json['rpe']),
      subExerciseId: serializer.fromJson<String?>(json['subExerciseId']),
      side: $WorkoutSetsTable.$convertersiden.fromJson(serializer.fromJson<int?>(json['side'])),
      maxHr: serializer.fromJson<int?>(json['maxHr']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'workoutId': serializer.toJson<String>(workoutId),
      'workoutExerciseId': serializer.toJson<String>(workoutExerciseId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'setIndex': serializer.toJson<int>(setIndex),
      'setType': serializer.toJson<int>($WorkoutSetsTable.$convertersetType.toJson(setType)),
      'weightKg': serializer.toJson<double?>(weightKg),
      'reps': serializer.toJson<int?>(reps),
      'durationS': serializer.toJson<int?>(durationS),
      'distanceM': serializer.toJson<double?>(distanceM),
      'rpe': serializer.toJson<double?>(rpe),
      'subExerciseId': serializer.toJson<String?>(subExerciseId),
      'side': serializer.toJson<int?>($WorkoutSetsTable.$convertersiden.toJson(side)),
      'maxHr': serializer.toJson<int?>(maxHr),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  WorkoutSet copyWith({
    String? id,
    DateTime? updatedAt,
    String? workoutId,
    String? workoutExerciseId,
    String? exerciseId,
    int? setIndex,
    SetType? setType,
    Value<double?> weightKg = const Value.absent(),
    Value<int?> reps = const Value.absent(),
    Value<int?> durationS = const Value.absent(),
    Value<double?> distanceM = const Value.absent(),
    Value<double?> rpe = const Value.absent(),
    Value<String?> subExerciseId = const Value.absent(),
    Value<Side?> side = const Value.absent(),
    Value<int?> maxHr = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => WorkoutSet(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    workoutId: workoutId ?? this.workoutId,
    workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
    exerciseId: exerciseId ?? this.exerciseId,
    setIndex: setIndex ?? this.setIndex,
    setType: setType ?? this.setType,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    reps: reps.present ? reps.value : this.reps,
    durationS: durationS.present ? durationS.value : this.durationS,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
    rpe: rpe.present ? rpe.value : this.rpe,
    subExerciseId: subExerciseId.present ? subExerciseId.value : this.subExerciseId,
    side: side.present ? side.value : this.side,
    maxHr: maxHr.present ? maxHr.value : this.maxHr,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  WorkoutSet copyWithCompanion(WorkoutSetsCompanion data) {
    return WorkoutSet(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      workoutExerciseId: data.workoutExerciseId.present ? data.workoutExerciseId.value : this.workoutExerciseId,
      exerciseId: data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      setIndex: data.setIndex.present ? data.setIndex.value : this.setIndex,
      setType: data.setType.present ? data.setType.value : this.setType,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      reps: data.reps.present ? data.reps.value : this.reps,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      rpe: data.rpe.present ? data.rpe.value : this.rpe,
      subExerciseId: data.subExerciseId.present ? data.subExerciseId.value : this.subExerciseId,
      side: data.side.present ? data.side.value : this.side,
      maxHr: data.maxHr.present ? data.maxHr.value : this.maxHr,
      completedAt: data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSet(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workoutId: $workoutId, ')
          ..write('workoutExerciseId: $workoutExerciseId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('setType: $setType, ')
          ..write('weightKg: $weightKg, ')
          ..write('reps: $reps, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('rpe: $rpe, ')
          ..write('subExerciseId: $subExerciseId, ')
          ..write('side: $side, ')
          ..write('maxHr: $maxHr, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    workoutId,
    workoutExerciseId,
    exerciseId,
    setIndex,
    setType,
    weightKg,
    reps,
    durationS,
    distanceM,
    rpe,
    subExerciseId,
    side,
    maxHr,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSet &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.workoutId == this.workoutId &&
          other.workoutExerciseId == this.workoutExerciseId &&
          other.exerciseId == this.exerciseId &&
          other.setIndex == this.setIndex &&
          other.setType == this.setType &&
          other.weightKg == this.weightKg &&
          other.reps == this.reps &&
          other.durationS == this.durationS &&
          other.distanceM == this.distanceM &&
          other.rpe == this.rpe &&
          other.subExerciseId == this.subExerciseId &&
          other.side == this.side &&
          other.maxHr == this.maxHr &&
          other.completedAt == this.completedAt);
}

class WorkoutSetsCompanion extends UpdateCompanion<WorkoutSet> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> workoutId;
  final Value<String> workoutExerciseId;
  final Value<String> exerciseId;
  final Value<int> setIndex;
  final Value<SetType> setType;
  final Value<double?> weightKg;
  final Value<int?> reps;
  final Value<int?> durationS;
  final Value<double?> distanceM;
  final Value<double?> rpe;
  final Value<String?> subExerciseId;
  final Value<Side?> side;
  final Value<int?> maxHr;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const WorkoutSetsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.workoutExerciseId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.setIndex = const Value.absent(),
    this.setType = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reps = const Value.absent(),
    this.durationS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.rpe = const Value.absent(),
    this.subExerciseId = const Value.absent(),
    this.side = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSetsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String workoutId,
    required String workoutExerciseId,
    required String exerciseId,
    required int setIndex,
    this.setType = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.reps = const Value.absent(),
    this.durationS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.rpe = const Value.absent(),
    this.subExerciseId = const Value.absent(),
    this.side = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workoutId = Value(workoutId),
       workoutExerciseId = Value(workoutExerciseId),
       exerciseId = Value(exerciseId),
       setIndex = Value(setIndex);
  static Insertable<WorkoutSet> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? workoutId,
    Expression<String>? workoutExerciseId,
    Expression<String>? exerciseId,
    Expression<int>? setIndex,
    Expression<int>? setType,
    Expression<double>? weightKg,
    Expression<int>? reps,
    Expression<int>? durationS,
    Expression<double>? distanceM,
    Expression<double>? rpe,
    Expression<String>? subExerciseId,
    Expression<int>? side,
    Expression<int>? maxHr,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (workoutId != null) 'workout_id': workoutId,
      if (workoutExerciseId != null) 'workout_exercise_id': workoutExerciseId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (setIndex != null) 'set_index': setIndex,
      if (setType != null) 'set_type': setType,
      if (weightKg != null) 'weight_kg': weightKg,
      if (reps != null) 'reps': reps,
      if (durationS != null) 'duration_s': durationS,
      if (distanceM != null) 'distance_m': distanceM,
      if (rpe != null) 'rpe': rpe,
      if (subExerciseId != null) 'sub_exercise_id': subExerciseId,
      if (side != null) 'side': side,
      if (maxHr != null) 'max_hr': maxHr,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSetsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? workoutId,
    Value<String>? workoutExerciseId,
    Value<String>? exerciseId,
    Value<int>? setIndex,
    Value<SetType>? setType,
    Value<double?>? weightKg,
    Value<int?>? reps,
    Value<int?>? durationS,
    Value<double?>? distanceM,
    Value<double?>? rpe,
    Value<String?>? subExerciseId,
    Value<Side?>? side,
    Value<int?>? maxHr,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return WorkoutSetsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      workoutId: workoutId ?? this.workoutId,
      workoutExerciseId: workoutExerciseId ?? this.workoutExerciseId,
      exerciseId: exerciseId ?? this.exerciseId,
      setIndex: setIndex ?? this.setIndex,
      setType: setType ?? this.setType,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      durationS: durationS ?? this.durationS,
      distanceM: distanceM ?? this.distanceM,
      rpe: rpe ?? this.rpe,
      subExerciseId: subExerciseId ?? this.subExerciseId,
      side: side ?? this.side,
      maxHr: maxHr ?? this.maxHr,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (workoutExerciseId.present) {
      map['workout_exercise_id'] = Variable<String>(workoutExerciseId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (setIndex.present) {
      map['set_index'] = Variable<int>(setIndex.value);
    }
    if (setType.present) {
      map['set_type'] = Variable<int>($WorkoutSetsTable.$convertersetType.toSql(setType.value));
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (rpe.present) {
      map['rpe'] = Variable<double>(rpe.value);
    }
    if (subExerciseId.present) {
      map['sub_exercise_id'] = Variable<String>(subExerciseId.value);
    }
    if (side.present) {
      map['side'] = Variable<int>($WorkoutSetsTable.$convertersiden.toSql(side.value));
    }
    if (maxHr.present) {
      map['max_hr'] = Variable<int>(maxHr.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSetsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('workoutId: $workoutId, ')
          ..write('workoutExerciseId: $workoutExerciseId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('setIndex: $setIndex, ')
          ..write('setType: $setType, ')
          ..write('weightKg: $weightKg, ')
          ..write('reps: $reps, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('rpe: $rpe, ')
          ..write('subExerciseId: $subExerciseId, ')
          ..write('side: $side, ')
          ..write('maxHr: $maxHr, ')
          ..write('completedAt: $completedAt, ')
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
  VerificationContext validateIntegrity(Insertable<Setting> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
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
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
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

  factory Setting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(key: serializer.fromJson<String>(json['key']), value: serializer.fromJson<String>(json['value']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'key': serializer.toJson<String>(key), 'value': serializer.toJson<String>(value)};
  }

  Setting copyWith({String? key, String? value}) => Setting(key: key ?? this.key, value: value ?? this.value);
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
      identical(this, other) || (other is Setting && other.key == this.key && other.value == this.value);
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
  SettingsCompanion.insert({required String key, required String value, this.rowid = const Value.absent()})
    : key = Value(key),
      value = Value(value);
  static Insertable<Setting> custom({Expression<String>? key, Expression<String>? value, Expression<int>? rowid}) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return SettingsCompanion(key: key ?? this.key, value: value ?? this.value, rowid: rowid ?? this.rowid);
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

class $BodyMeasurementsTable extends BodyMeasurements with TableInfo<$BodyMeasurementsTable, BodyMeasurement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyMeasurementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, date, kind, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_measurements';
  @override
  VerificationContext validateIntegrity(Insertable<BodyMeasurement> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('date')) {
      context.handle(_dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(_kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyMeasurement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyMeasurement(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      date: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      kind: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $BodyMeasurementsTable createAlias(String alias) {
    return $BodyMeasurementsTable(attachedDatabase, alias);
  }
}

class BodyMeasurement extends DataClass implements Insertable<BodyMeasurement> {
  final String id;
  final DateTime updatedAt;
  final DateTime date;

  /// Key from `measurementKinds` (e.g. "weight", "waist") or a custom name.
  final String kind;
  final double value;
  const BodyMeasurement({
    required this.id,
    required this.updatedAt,
    required this.date,
    required this.kind,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['date'] = Variable<DateTime>(date);
    map['kind'] = Variable<String>(kind);
    map['value'] = Variable<double>(value);
    return map;
  }

  BodyMeasurementsCompanion toCompanion(bool nullToAbsent) {
    return BodyMeasurementsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      date: Value(date),
      kind: Value(kind),
      value: Value(value),
    );
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyMeasurement(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      date: serializer.fromJson<DateTime>(json['date']),
      kind: serializer.fromJson<String>(json['kind']),
      value: serializer.fromJson<double>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'date': serializer.toJson<DateTime>(date),
      'kind': serializer.toJson<String>(kind),
      'value': serializer.toJson<double>(value),
    };
  }

  BodyMeasurement copyWith({String? id, DateTime? updatedAt, DateTime? date, String? kind, double? value}) =>
      BodyMeasurement(
        id: id ?? this.id,
        updatedAt: updatedAt ?? this.updatedAt,
        date: date ?? this.date,
        kind: kind ?? this.kind,
        value: value ?? this.value,
      );
  BodyMeasurement copyWithCompanion(BodyMeasurementsCompanion data) {
    return BodyMeasurement(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      date: data.date.present ? data.date.value : this.date,
      kind: data.kind.present ? data.kind.value : this.kind,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurement(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, date, kind, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyMeasurement &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.date == this.date &&
          other.kind == this.kind &&
          other.value == this.value);
}

class BodyMeasurementsCompanion extends UpdateCompanion<BodyMeasurement> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime> date;
  final Value<String> kind;
  final Value<double> value;
  final Value<int> rowid;
  const BodyMeasurementsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.date = const Value.absent(),
    this.kind = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyMeasurementsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required DateTime date,
    required String kind,
    required double value,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       kind = Value(kind),
       value = Value(value);
  static Insertable<BodyMeasurement> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? date,
    Expression<String>? kind,
    Expression<double>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (date != null) 'date': date,
      if (kind != null) 'kind': kind,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyMeasurementsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime>? date,
    Value<String>? kind,
    Value<double>? value,
    Value<int>? rowid,
  }) {
    return BodyMeasurementsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      date: date ?? this.date,
      kind: kind ?? this.kind,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyMeasurementsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('date: $date, ')
          ..write('kind: $kind, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  @override
  late final GeneratedColumnWithTypeConverter<GoalType, int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<GoalType>($GoalsTable.$convertertype);
  static const VerificationMeta _targetMeta = const VerificationMeta('target');
  @override
  late final GeneratedColumn<double> target = GeneratedColumn<double>(
    'target',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startValueMeta = const VerificationMeta('startValue');
  @override
  late final GeneratedColumn<double> startValue = GeneratedColumn<double>(
    'start_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _measurementKindMeta = const VerificationMeta('measurementKind');
  @override
  late final GeneratedColumn<String> measurementKind = GeneratedColumn<String>(
    'measurement_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta('deadline');
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _achievedAtMeta = const VerificationMeta('achievedAt');
  @override
  late final GeneratedColumn<DateTime> achievedAt = GeneratedColumn<DateTime>(
    'achieved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta('distanceM');
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    type,
    target,
    startValue,
    exerciseId,
    measurementKind,
    deadline,
    createdAt,
    achievedAt,
    distanceM,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(Insertable<Goal> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('target')) {
      context.handle(_targetMeta, target.isAcceptableOrUnknown(data['target']!, _targetMeta));
    } else if (isInserting) {
      context.missing(_targetMeta);
    }
    if (data.containsKey('start_value')) {
      context.handle(_startValueMeta, startValue.isAcceptableOrUnknown(data['start_value']!, _startValueMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(_exerciseIdMeta, exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta));
    }
    if (data.containsKey('measurement_kind')) {
      context.handle(
        _measurementKindMeta,
        measurementKind.isAcceptableOrUnknown(data['measurement_kind']!, _measurementKindMeta),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(_deadlineMeta, deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('achieved_at')) {
      context.handle(_achievedAtMeta, achievedAt.isAcceptableOrUnknown(data['achieved_at']!, _achievedAtMeta));
    }
    if (data.containsKey('distance_m')) {
      context.handle(_distanceMMeta, distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      type: $GoalsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}type'])!,
      ),
      target: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}target'])!,
      startValue: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}start_value']),
      exerciseId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}exercise_id']),
      measurementKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_kind'],
      ),
      deadline: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deadline']),
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      achievedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}achieved_at']),
      distanceM: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}distance_m']),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GoalType, int, int> $convertertype = const EnumIndexConverter<GoalType>(GoalType.values);
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final DateTime updatedAt;
  final GoalType type;
  final double target;

  /// Where the user started (for measurement goals: weight 85 → 80).
  final double? startValue;
  final String? exerciseId;
  final String? measurementKind;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? achievedAt;

  /// Run time goals: the distance in metres ("5 km under 25 min").
  final double? distanceM;
  const Goal({
    required this.id,
    required this.updatedAt,
    required this.type,
    required this.target,
    this.startValue,
    this.exerciseId,
    this.measurementKind,
    this.deadline,
    required this.createdAt,
    this.achievedAt,
    this.distanceM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['type'] = Variable<int>($GoalsTable.$convertertype.toSql(type));
    }
    map['target'] = Variable<double>(target);
    if (!nullToAbsent || startValue != null) {
      map['start_value'] = Variable<double>(startValue);
    }
    if (!nullToAbsent || exerciseId != null) {
      map['exercise_id'] = Variable<String>(exerciseId);
    }
    if (!nullToAbsent || measurementKind != null) {
      map['measurement_kind'] = Variable<String>(measurementKind);
    }
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || achievedAt != null) {
      map['achieved_at'] = Variable<DateTime>(achievedAt);
    }
    if (!nullToAbsent || distanceM != null) {
      map['distance_m'] = Variable<double>(distanceM);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      type: Value(type),
      target: Value(target),
      startValue: startValue == null && nullToAbsent ? const Value.absent() : Value(startValue),
      exerciseId: exerciseId == null && nullToAbsent ? const Value.absent() : Value(exerciseId),
      measurementKind: measurementKind == null && nullToAbsent ? const Value.absent() : Value(measurementKind),
      deadline: deadline == null && nullToAbsent ? const Value.absent() : Value(deadline),
      createdAt: Value(createdAt),
      achievedAt: achievedAt == null && nullToAbsent ? const Value.absent() : Value(achievedAt),
      distanceM: distanceM == null && nullToAbsent ? const Value.absent() : Value(distanceM),
    );
  }

  factory Goal.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      type: $GoalsTable.$convertertype.fromJson(serializer.fromJson<int>(json['type'])),
      target: serializer.fromJson<double>(json['target']),
      startValue: serializer.fromJson<double?>(json['startValue']),
      exerciseId: serializer.fromJson<String?>(json['exerciseId']),
      measurementKind: serializer.fromJson<String?>(json['measurementKind']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      achievedAt: serializer.fromJson<DateTime?>(json['achievedAt']),
      distanceM: serializer.fromJson<double?>(json['distanceM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'type': serializer.toJson<int>($GoalsTable.$convertertype.toJson(type)),
      'target': serializer.toJson<double>(target),
      'startValue': serializer.toJson<double?>(startValue),
      'exerciseId': serializer.toJson<String?>(exerciseId),
      'measurementKind': serializer.toJson<String?>(measurementKind),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'achievedAt': serializer.toJson<DateTime?>(achievedAt),
      'distanceM': serializer.toJson<double?>(distanceM),
    };
  }

  Goal copyWith({
    String? id,
    DateTime? updatedAt,
    GoalType? type,
    double? target,
    Value<double?> startValue = const Value.absent(),
    Value<String?> exerciseId = const Value.absent(),
    Value<String?> measurementKind = const Value.absent(),
    Value<DateTime?> deadline = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> achievedAt = const Value.absent(),
    Value<double?> distanceM = const Value.absent(),
  }) => Goal(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    type: type ?? this.type,
    target: target ?? this.target,
    startValue: startValue.present ? startValue.value : this.startValue,
    exerciseId: exerciseId.present ? exerciseId.value : this.exerciseId,
    measurementKind: measurementKind.present ? measurementKind.value : this.measurementKind,
    deadline: deadline.present ? deadline.value : this.deadline,
    createdAt: createdAt ?? this.createdAt,
    achievedAt: achievedAt.present ? achievedAt.value : this.achievedAt,
    distanceM: distanceM.present ? distanceM.value : this.distanceM,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      type: data.type.present ? data.type.value : this.type,
      target: data.target.present ? data.target.value : this.target,
      startValue: data.startValue.present ? data.startValue.value : this.startValue,
      exerciseId: data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      measurementKind: data.measurementKind.present ? data.measurementKind.value : this.measurementKind,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      achievedAt: data.achievedAt.present ? data.achievedAt.value : this.achievedAt,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('target: $target, ')
          ..write('startValue: $startValue, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('measurementKind: $measurementKind, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('distanceM: $distanceM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    type,
    target,
    startValue,
    exerciseId,
    measurementKind,
    deadline,
    createdAt,
    achievedAt,
    distanceM,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.type == this.type &&
          other.target == this.target &&
          other.startValue == this.startValue &&
          other.exerciseId == this.exerciseId &&
          other.measurementKind == this.measurementKind &&
          other.deadline == this.deadline &&
          other.createdAt == this.createdAt &&
          other.achievedAt == this.achievedAt &&
          other.distanceM == this.distanceM);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<GoalType> type;
  final Value<double> target;
  final Value<double?> startValue;
  final Value<String?> exerciseId;
  final Value<String?> measurementKind;
  final Value<DateTime?> deadline;
  final Value<DateTime> createdAt;
  final Value<DateTime?> achievedAt;
  final Value<double?> distanceM;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.type = const Value.absent(),
    this.target = const Value.absent(),
    this.startValue = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.measurementKind = const Value.absent(),
    this.deadline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required GoalType type,
    required double target,
    this.startValue = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.measurementKind = const Value.absent(),
    this.deadline = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : type = Value(type),
       target = Value(target);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<int>? type,
    Expression<double>? target,
    Expression<double>? startValue,
    Expression<String>? exerciseId,
    Expression<String>? measurementKind,
    Expression<DateTime>? deadline,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? achievedAt,
    Expression<double>? distanceM,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (type != null) 'type': type,
      if (target != null) 'target': target,
      if (startValue != null) 'start_value': startValue,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (measurementKind != null) 'measurement_kind': measurementKind,
      if (deadline != null) 'deadline': deadline,
      if (createdAt != null) 'created_at': createdAt,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (distanceM != null) 'distance_m': distanceM,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<GoalType>? type,
    Value<double>? target,
    Value<double?>? startValue,
    Value<String?>? exerciseId,
    Value<String?>? measurementKind,
    Value<DateTime?>? deadline,
    Value<DateTime>? createdAt,
    Value<DateTime?>? achievedAt,
    Value<double?>? distanceM,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      target: target ?? this.target,
      startValue: startValue ?? this.startValue,
      exerciseId: exerciseId ?? this.exerciseId,
      measurementKind: measurementKind ?? this.measurementKind,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      achievedAt: achievedAt ?? this.achievedAt,
      distanceM: distanceM ?? this.distanceM,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (type.present) {
      map['type'] = Variable<int>($GoalsTable.$convertertype.toSql(type.value));
    }
    if (target.present) {
      map['target'] = Variable<double>(target.value);
    }
    if (startValue.present) {
      map['start_value'] = Variable<double>(startValue.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (measurementKind.present) {
      map['measurement_kind'] = Variable<String>(measurementKind.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<DateTime>(achievedAt.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('type: $type, ')
          ..write('target: $target, ')
          ..write('startValue: $startValue, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('measurementKind: $measurementKind, ')
          ..write('deadline: $deadline, ')
          ..write('createdAt: $createdAt, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('distanceM: $distanceM, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HrPresetsTable extends HrPresets with TableInfo<$HrPresetsTable, HrPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HrPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minBpmMeta = const VerificationMeta('minBpm');
  @override
  late final GeneratedColumn<int> minBpm = GeneratedColumn<int>(
    'min_bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxBpmMeta = const VerificationMeta('maxBpm');
  @override
  late final GeneratedColumn<int> maxBpm = GeneratedColumn<int>(
    'max_bpm',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PresetUse, int> use = GeneratedColumn<int>(
    'use',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<PresetUse>($HrPresetsTable.$converteruse);
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, name, minBpm, maxBpm, use];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hr_presets';
  @override
  VerificationContext validateIntegrity(Insertable<HrPreset> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('min_bpm')) {
      context.handle(_minBpmMeta, minBpm.isAcceptableOrUnknown(data['min_bpm']!, _minBpmMeta));
    } else if (isInserting) {
      context.missing(_minBpmMeta);
    }
    if (data.containsKey('max_bpm')) {
      context.handle(_maxBpmMeta, maxBpm.isAcceptableOrUnknown(data['max_bpm']!, _maxBpmMeta));
    } else if (isInserting) {
      context.missing(_maxBpmMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HrPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HrPreset(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      minBpm: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}min_bpm'])!,
      maxBpm: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}max_bpm'])!,
      use: $HrPresetsTable.$converteruse.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}use'])!,
      ),
    );
  }

  @override
  $HrPresetsTable createAlias(String alias) {
    return $HrPresetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PresetUse, int, int> $converteruse = const EnumIndexConverter<PresetUse>(PresetUse.values);
}

class HrPreset extends DataClass implements Insertable<HrPreset> {
  final String id;
  final DateTime updatedAt;
  final String name;
  final int minBpm;
  final int maxBpm;
  final PresetUse use;
  const HrPreset({
    required this.id,
    required this.updatedAt,
    required this.name,
    required this.minBpm,
    required this.maxBpm,
    required this.use,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['min_bpm'] = Variable<int>(minBpm);
    map['max_bpm'] = Variable<int>(maxBpm);
    {
      map['use'] = Variable<int>($HrPresetsTable.$converteruse.toSql(use));
    }
    return map;
  }

  HrPresetsCompanion toCompanion(bool nullToAbsent) {
    return HrPresetsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      name: Value(name),
      minBpm: Value(minBpm),
      maxBpm: Value(maxBpm),
      use: Value(use),
    );
  }

  factory HrPreset.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HrPreset(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      minBpm: serializer.fromJson<int>(json['minBpm']),
      maxBpm: serializer.fromJson<int>(json['maxBpm']),
      use: $HrPresetsTable.$converteruse.fromJson(serializer.fromJson<int>(json['use'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'minBpm': serializer.toJson<int>(minBpm),
      'maxBpm': serializer.toJson<int>(maxBpm),
      'use': serializer.toJson<int>($HrPresetsTable.$converteruse.toJson(use)),
    };
  }

  HrPreset copyWith({String? id, DateTime? updatedAt, String? name, int? minBpm, int? maxBpm, PresetUse? use}) =>
      HrPreset(
        id: id ?? this.id,
        updatedAt: updatedAt ?? this.updatedAt,
        name: name ?? this.name,
        minBpm: minBpm ?? this.minBpm,
        maxBpm: maxBpm ?? this.maxBpm,
        use: use ?? this.use,
      );
  HrPreset copyWithCompanion(HrPresetsCompanion data) {
    return HrPreset(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      minBpm: data.minBpm.present ? data.minBpm.value : this.minBpm,
      maxBpm: data.maxBpm.present ? data.maxBpm.value : this.maxBpm,
      use: data.use.present ? data.use.value : this.use,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HrPreset(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('minBpm: $minBpm, ')
          ..write('maxBpm: $maxBpm, ')
          ..write('use: $use')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, name, minBpm, maxBpm, use);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HrPreset &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.minBpm == this.minBpm &&
          other.maxBpm == this.maxBpm &&
          other.use == this.use);
}

class HrPresetsCompanion extends UpdateCompanion<HrPreset> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<int> minBpm;
  final Value<int> maxBpm;
  final Value<PresetUse> use;
  final Value<int> rowid;
  const HrPresetsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.minBpm = const Value.absent(),
    this.maxBpm = const Value.absent(),
    this.use = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HrPresetsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    required int minBpm,
    required int maxBpm,
    this.use = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       minBpm = Value(minBpm),
       maxBpm = Value(maxBpm);
  static Insertable<HrPreset> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<int>? minBpm,
    Expression<int>? maxBpm,
    Expression<int>? use,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (minBpm != null) 'min_bpm': minBpm,
      if (maxBpm != null) 'max_bpm': maxBpm,
      if (use != null) 'use': use,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HrPresetsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<int>? minBpm,
    Value<int>? maxBpm,
    Value<PresetUse>? use,
    Value<int>? rowid,
  }) {
    return HrPresetsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      minBpm: minBpm ?? this.minBpm,
      maxBpm: maxBpm ?? this.maxBpm,
      use: use ?? this.use,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (minBpm.present) {
      map['min_bpm'] = Variable<int>(minBpm.value);
    }
    if (maxBpm.present) {
      map['max_bpm'] = Variable<int>(maxBpm.value);
    }
    if (use.present) {
      map['use'] = Variable<int>($HrPresetsTable.$converteruse.toSql(use.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HrPresetsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('minBpm: $minBpm, ')
          ..write('maxBpm: $maxBpm, ')
          ..write('use: $use, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IntervalPresetsTable extends IntervalPresets with TableInfo<$IntervalPresetsTable, IntervalPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntervalPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentsJsonMeta = const VerificationMeta('segmentsJson');
  @override
  late final GeneratedColumn<String> segmentsJson = GeneratedColumn<String>(
    'segments_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundsMeta = const VerificationMeta('rounds');
  @override
  late final GeneratedColumn<int> rounds = GeneratedColumn<int>(
    'rounds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, name, segmentsJson, rounds, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'interval_presets';
  @override
  VerificationContext validateIntegrity(Insertable<IntervalPreset> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('segments_json')) {
      context.handle(_segmentsJsonMeta, segmentsJson.isAcceptableOrUnknown(data['segments_json']!, _segmentsJsonMeta));
    } else if (isInserting) {
      context.missing(_segmentsJsonMeta);
    }
    if (data.containsKey('rounds')) {
      context.handle(_roundsMeta, rounds.isAcceptableOrUnknown(data['rounds']!, _roundsMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntervalPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntervalPreset(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      segmentsJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}segments_json'])!,
      rounds: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}rounds'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $IntervalPresetsTable createAlias(String alias) {
    return $IntervalPresetsTable(attachedDatabase, alias);
  }
}

class IntervalPreset extends DataClass implements Insertable<IntervalPreset> {
  final String id;
  final DateTime updatedAt;
  final String name;

  /// [{"l": label, "s": seconds, "w": isWork}]
  final String segmentsJson;
  final int rounds;
  final int position;
  const IntervalPreset({
    required this.id,
    required this.updatedAt,
    required this.name,
    required this.segmentsJson,
    required this.rounds,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['segments_json'] = Variable<String>(segmentsJson);
    map['rounds'] = Variable<int>(rounds);
    map['position'] = Variable<int>(position);
    return map;
  }

  IntervalPresetsCompanion toCompanion(bool nullToAbsent) {
    return IntervalPresetsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      name: Value(name),
      segmentsJson: Value(segmentsJson),
      rounds: Value(rounds),
      position: Value(position),
    );
  }

  factory IntervalPreset.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntervalPreset(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      segmentsJson: serializer.fromJson<String>(json['segmentsJson']),
      rounds: serializer.fromJson<int>(json['rounds']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'segmentsJson': serializer.toJson<String>(segmentsJson),
      'rounds': serializer.toJson<int>(rounds),
      'position': serializer.toJson<int>(position),
    };
  }

  IntervalPreset copyWith({
    String? id,
    DateTime? updatedAt,
    String? name,
    String? segmentsJson,
    int? rounds,
    int? position,
  }) => IntervalPreset(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    segmentsJson: segmentsJson ?? this.segmentsJson,
    rounds: rounds ?? this.rounds,
    position: position ?? this.position,
  );
  IntervalPreset copyWithCompanion(IntervalPresetsCompanion data) {
    return IntervalPreset(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      segmentsJson: data.segmentsJson.present ? data.segmentsJson.value : this.segmentsJson,
      rounds: data.rounds.present ? data.rounds.value : this.rounds,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntervalPreset(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('rounds: $rounds, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, name, segmentsJson, rounds, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntervalPreset &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.segmentsJson == this.segmentsJson &&
          other.rounds == this.rounds &&
          other.position == this.position);
}

class IntervalPresetsCompanion extends UpdateCompanion<IntervalPreset> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String> segmentsJson;
  final Value<int> rounds;
  final Value<int> position;
  final Value<int> rowid;
  const IntervalPresetsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.segmentsJson = const Value.absent(),
    this.rounds = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IntervalPresetsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    required String segmentsJson,
    this.rounds = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       segmentsJson = Value(segmentsJson);
  static Insertable<IntervalPreset> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? segmentsJson,
    Expression<int>? rounds,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (segmentsJson != null) 'segments_json': segmentsJson,
      if (rounds != null) 'rounds': rounds,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IntervalPresetsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String>? segmentsJson,
    Value<int>? rounds,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return IntervalPresetsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      segmentsJson: segmentsJson ?? this.segmentsJson,
      rounds: rounds ?? this.rounds,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (segmentsJson.present) {
      map['segments_json'] = Variable<String>(segmentsJson.value);
    }
    if (rounds.present) {
      map['rounds'] = Variable<int>(rounds.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntervalPresetsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('segmentsJson: $segmentsJson, ')
          ..write('rounds: $rounds, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunsTable extends Runs with TableInfo<$RunsTable, Run> {
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
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Run'),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedAtMeta = const VerificationMeta('pausedAt');
  @override
  late final GeneratedColumn<DateTime> pausedAt = GeneratedColumn<DateTime>(
    'paused_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedSMeta = const VerificationMeta('pausedS');
  @override
  late final GeneratedColumn<int> pausedS = GeneratedColumn<int>(
    'paused_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta('durationS');
  @override
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta('distanceM');
  @override
  late final GeneratedColumn<double> distanceM = GeneratedColumn<double>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hrPresetIdMeta = const VerificationMeta('hrPresetId');
  @override
  late final GeneratedColumn<String> hrPresetId = GeneratedColumn<String>(
    'hr_preset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgHrMeta = const VerificationMeta('avgHr');
  @override
  late final GeneratedColumn<int> avgHr = GeneratedColumn<int>(
    'avg_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maxHrMeta = const VerificationMeta('maxHr');
  @override
  late final GeneratedColumn<int> maxHr = GeneratedColumn<int>(
    'max_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _bestsJsonMeta = const VerificationMeta('bestsJson');
  @override
  late final GeneratedColumn<String> bestsJson = GeneratedColumn<String>(
    'bests_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RunKind, int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  ).withConverter<RunKind>($RunsTable.$converterkind);
  static const VerificationMeta _effortMeta = const VerificationMeta('effort');
  @override
  late final GeneratedColumn<int> effort = GeneratedColumn<int>(
    'effort',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weatherMeta = const VerificationMeta('weather');
  @override
  late final GeneratedColumn<String> weather = GeneratedColumn<String>(
    'weather',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shoeIdMeta = const VerificationMeta('shoeId');
  @override
  late final GeneratedColumn<String> shoeId = GeneratedColumn<String>(
    'shoe_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avgCadenceMeta = const VerificationMeta('avgCadence');
  @override
  late final GeneratedColumn<int> avgCadence = GeneratedColumn<int>(
    'avg_cadence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elevGainMMeta = const VerificationMeta('elevGainM');
  @override
  late final GeneratedColumn<double> elevGainM = GeneratedColumn<double>(
    'elev_gain_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elevLossMMeta = const VerificationMeta('elevLossM');
  @override
  late final GeneratedColumn<double> elevLossM = GeneratedColumn<double>(
    'elev_loss_m',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lapsJsonMeta = const VerificationMeta('lapsJson');
  @override
  late final GeneratedColumn<String> lapsJson = GeneratedColumn<String>(
    'laps_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    name,
    startedAt,
    endedAt,
    pausedAt,
    pausedS,
    durationS,
    distanceM,
    hrPresetId,
    avgHr,
    maxHr,
    notes,
    bestsJson,
    kind,
    effort,
    weather,
    shoeId,
    steps,
    avgCadence,
    elevGainM,
    elevLossM,
    planId,
    lapsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'runs';
  @override
  VerificationContext validateIntegrity(Insertable<Run> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta, startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta, endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('paused_at')) {
      context.handle(_pausedAtMeta, pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta));
    }
    if (data.containsKey('paused_s')) {
      context.handle(_pausedSMeta, pausedS.isAcceptableOrUnknown(data['paused_s']!, _pausedSMeta));
    }
    if (data.containsKey('duration_s')) {
      context.handle(_durationSMeta, durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta));
    }
    if (data.containsKey('distance_m')) {
      context.handle(_distanceMMeta, distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta));
    }
    if (data.containsKey('hr_preset_id')) {
      context.handle(_hrPresetIdMeta, hrPresetId.isAcceptableOrUnknown(data['hr_preset_id']!, _hrPresetIdMeta));
    }
    if (data.containsKey('avg_hr')) {
      context.handle(_avgHrMeta, avgHr.isAcceptableOrUnknown(data['avg_hr']!, _avgHrMeta));
    }
    if (data.containsKey('max_hr')) {
      context.handle(_maxHrMeta, maxHr.isAcceptableOrUnknown(data['max_hr']!, _maxHrMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('bests_json')) {
      context.handle(_bestsJsonMeta, bestsJson.isAcceptableOrUnknown(data['bests_json']!, _bestsJsonMeta));
    }
    if (data.containsKey('effort')) {
      context.handle(_effortMeta, effort.isAcceptableOrUnknown(data['effort']!, _effortMeta));
    }
    if (data.containsKey('weather')) {
      context.handle(_weatherMeta, weather.isAcceptableOrUnknown(data['weather']!, _weatherMeta));
    }
    if (data.containsKey('shoe_id')) {
      context.handle(_shoeIdMeta, shoeId.isAcceptableOrUnknown(data['shoe_id']!, _shoeIdMeta));
    }
    if (data.containsKey('steps')) {
      context.handle(_stepsMeta, steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta));
    }
    if (data.containsKey('avg_cadence')) {
      context.handle(_avgCadenceMeta, avgCadence.isAcceptableOrUnknown(data['avg_cadence']!, _avgCadenceMeta));
    }
    if (data.containsKey('elev_gain_m')) {
      context.handle(_elevGainMMeta, elevGainM.isAcceptableOrUnknown(data['elev_gain_m']!, _elevGainMMeta));
    }
    if (data.containsKey('elev_loss_m')) {
      context.handle(_elevLossMMeta, elevLossM.isAcceptableOrUnknown(data['elev_loss_m']!, _elevLossMMeta));
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta, planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    }
    if (data.containsKey('laps_json')) {
      context.handle(_lapsJsonMeta, lapsJson.isAcceptableOrUnknown(data['laps_json']!, _lapsJsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Run map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Run(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      startedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}ended_at']),
      pausedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}paused_at']),
      pausedS: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}paused_s'])!,
      durationS: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}duration_s'])!,
      distanceM: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}distance_m'])!,
      hrPresetId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}hr_preset_id']),
      avgHr: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}avg_hr']),
      maxHr: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}max_hr']),
      notes: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}notes'])!,
      bestsJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}bests_json']),
      kind: $RunsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}kind'])!,
      ),
      effort: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}effort']),
      weather: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}weather']),
      shoeId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}shoe_id']),
      steps: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}steps']),
      avgCadence: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}avg_cadence']),
      elevGainM: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}elev_gain_m']),
      elevLossM: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}elev_loss_m']),
      planId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}plan_id']),
      lapsJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}laps_json']),
    );
  }

  @override
  $RunsTable createAlias(String alias) {
    return $RunsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RunKind, int, int> $converterkind = const EnumIndexConverter<RunKind>(RunKind.values);
}

class Run extends DataClass implements Insertable<Run> {
  final String id;
  final DateTime updatedAt;
  final String name;
  final DateTime startedAt;

  /// Null while the run is being recorded.
  final DateTime? endedAt;

  /// Set while paused: when the pause started.
  final DateTime? pausedAt;

  /// Seconds spent in earlier (finished) pauses.
  final int pausedS;

  /// Moving time in seconds (kept up to date while recording).
  final int durationS;
  final double distanceM;
  final String? hrPresetId;
  final int? avgHr;
  final int? maxHr;
  final String notes;

  /// Fastest time per record distance inside this run, JSON {"1000": 251.3,
  /// "5000": …} (seconds). Null = not worked out yet (computed on demand).
  final String? bestsJson;

  /// Outdoor (GPS) or treadmill (distance typed in at the end).
  final RunKind kind;

  /// How hard it felt, 1–10 (null = not rated).
  final int? effort;

  /// Weather tags, comma-separated ("sunny,windy").
  final String? weather;

  /// The shoes worn (null = not set).
  final String? shoeId;

  /// Steps counted by the phone (null = not available).
  final int? steps;

  /// Average cadence, steps per minute of moving time.
  final int? avgCadence;

  /// Climb / descent in metres measured by the barometer during the run
  /// (null = no barometer: computed from the GPS height instead).
  final double? elevGainM;
  final double? elevLossM;

  /// The planned run followed (null = free run) and its laps (JSON).
  final String? planId;
  final String? lapsJson;
  const Run({
    required this.id,
    required this.updatedAt,
    required this.name,
    required this.startedAt,
    this.endedAt,
    this.pausedAt,
    required this.pausedS,
    required this.durationS,
    required this.distanceM,
    this.hrPresetId,
    this.avgHr,
    this.maxHr,
    required this.notes,
    this.bestsJson,
    required this.kind,
    this.effort,
    this.weather,
    this.shoeId,
    this.steps,
    this.avgCadence,
    this.elevGainM,
    this.elevLossM,
    this.planId,
    this.lapsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<DateTime>(pausedAt);
    }
    map['paused_s'] = Variable<int>(pausedS);
    map['duration_s'] = Variable<int>(durationS);
    map['distance_m'] = Variable<double>(distanceM);
    if (!nullToAbsent || hrPresetId != null) {
      map['hr_preset_id'] = Variable<String>(hrPresetId);
    }
    if (!nullToAbsent || avgHr != null) {
      map['avg_hr'] = Variable<int>(avgHr);
    }
    if (!nullToAbsent || maxHr != null) {
      map['max_hr'] = Variable<int>(maxHr);
    }
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || bestsJson != null) {
      map['bests_json'] = Variable<String>(bestsJson);
    }
    {
      map['kind'] = Variable<int>($RunsTable.$converterkind.toSql(kind));
    }
    if (!nullToAbsent || effort != null) {
      map['effort'] = Variable<int>(effort);
    }
    if (!nullToAbsent || weather != null) {
      map['weather'] = Variable<String>(weather);
    }
    if (!nullToAbsent || shoeId != null) {
      map['shoe_id'] = Variable<String>(shoeId);
    }
    if (!nullToAbsent || steps != null) {
      map['steps'] = Variable<int>(steps);
    }
    if (!nullToAbsent || avgCadence != null) {
      map['avg_cadence'] = Variable<int>(avgCadence);
    }
    if (!nullToAbsent || elevGainM != null) {
      map['elev_gain_m'] = Variable<double>(elevGainM);
    }
    if (!nullToAbsent || elevLossM != null) {
      map['elev_loss_m'] = Variable<double>(elevLossM);
    }
    if (!nullToAbsent || planId != null) {
      map['plan_id'] = Variable<String>(planId);
    }
    if (!nullToAbsent || lapsJson != null) {
      map['laps_json'] = Variable<String>(lapsJson);
    }
    return map;
  }

  RunsCompanion toCompanion(bool nullToAbsent) {
    return RunsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      name: Value(name),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent ? const Value.absent() : Value(endedAt),
      pausedAt: pausedAt == null && nullToAbsent ? const Value.absent() : Value(pausedAt),
      pausedS: Value(pausedS),
      durationS: Value(durationS),
      distanceM: Value(distanceM),
      hrPresetId: hrPresetId == null && nullToAbsent ? const Value.absent() : Value(hrPresetId),
      avgHr: avgHr == null && nullToAbsent ? const Value.absent() : Value(avgHr),
      maxHr: maxHr == null && nullToAbsent ? const Value.absent() : Value(maxHr),
      notes: Value(notes),
      bestsJson: bestsJson == null && nullToAbsent ? const Value.absent() : Value(bestsJson),
      kind: Value(kind),
      effort: effort == null && nullToAbsent ? const Value.absent() : Value(effort),
      weather: weather == null && nullToAbsent ? const Value.absent() : Value(weather),
      shoeId: shoeId == null && nullToAbsent ? const Value.absent() : Value(shoeId),
      steps: steps == null && nullToAbsent ? const Value.absent() : Value(steps),
      avgCadence: avgCadence == null && nullToAbsent ? const Value.absent() : Value(avgCadence),
      elevGainM: elevGainM == null && nullToAbsent ? const Value.absent() : Value(elevGainM),
      elevLossM: elevLossM == null && nullToAbsent ? const Value.absent() : Value(elevLossM),
      planId: planId == null && nullToAbsent ? const Value.absent() : Value(planId),
      lapsJson: lapsJson == null && nullToAbsent ? const Value.absent() : Value(lapsJson),
    );
  }

  factory Run.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Run(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      pausedAt: serializer.fromJson<DateTime?>(json['pausedAt']),
      pausedS: serializer.fromJson<int>(json['pausedS']),
      durationS: serializer.fromJson<int>(json['durationS']),
      distanceM: serializer.fromJson<double>(json['distanceM']),
      hrPresetId: serializer.fromJson<String?>(json['hrPresetId']),
      avgHr: serializer.fromJson<int?>(json['avgHr']),
      maxHr: serializer.fromJson<int?>(json['maxHr']),
      notes: serializer.fromJson<String>(json['notes']),
      bestsJson: serializer.fromJson<String?>(json['bestsJson']),
      kind: $RunsTable.$converterkind.fromJson(serializer.fromJson<int>(json['kind'])),
      effort: serializer.fromJson<int?>(json['effort']),
      weather: serializer.fromJson<String?>(json['weather']),
      shoeId: serializer.fromJson<String?>(json['shoeId']),
      steps: serializer.fromJson<int?>(json['steps']),
      avgCadence: serializer.fromJson<int?>(json['avgCadence']),
      elevGainM: serializer.fromJson<double?>(json['elevGainM']),
      elevLossM: serializer.fromJson<double?>(json['elevLossM']),
      planId: serializer.fromJson<String?>(json['planId']),
      lapsJson: serializer.fromJson<String?>(json['lapsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'pausedAt': serializer.toJson<DateTime?>(pausedAt),
      'pausedS': serializer.toJson<int>(pausedS),
      'durationS': serializer.toJson<int>(durationS),
      'distanceM': serializer.toJson<double>(distanceM),
      'hrPresetId': serializer.toJson<String?>(hrPresetId),
      'avgHr': serializer.toJson<int?>(avgHr),
      'maxHr': serializer.toJson<int?>(maxHr),
      'notes': serializer.toJson<String>(notes),
      'bestsJson': serializer.toJson<String?>(bestsJson),
      'kind': serializer.toJson<int>($RunsTable.$converterkind.toJson(kind)),
      'effort': serializer.toJson<int?>(effort),
      'weather': serializer.toJson<String?>(weather),
      'shoeId': serializer.toJson<String?>(shoeId),
      'steps': serializer.toJson<int?>(steps),
      'avgCadence': serializer.toJson<int?>(avgCadence),
      'elevGainM': serializer.toJson<double?>(elevGainM),
      'elevLossM': serializer.toJson<double?>(elevLossM),
      'planId': serializer.toJson<String?>(planId),
      'lapsJson': serializer.toJson<String?>(lapsJson),
    };
  }

  Run copyWith({
    String? id,
    DateTime? updatedAt,
    String? name,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    Value<DateTime?> pausedAt = const Value.absent(),
    int? pausedS,
    int? durationS,
    double? distanceM,
    Value<String?> hrPresetId = const Value.absent(),
    Value<int?> avgHr = const Value.absent(),
    Value<int?> maxHr = const Value.absent(),
    String? notes,
    Value<String?> bestsJson = const Value.absent(),
    RunKind? kind,
    Value<int?> effort = const Value.absent(),
    Value<String?> weather = const Value.absent(),
    Value<String?> shoeId = const Value.absent(),
    Value<int?> steps = const Value.absent(),
    Value<int?> avgCadence = const Value.absent(),
    Value<double?> elevGainM = const Value.absent(),
    Value<double?> elevLossM = const Value.absent(),
    Value<String?> planId = const Value.absent(),
    Value<String?> lapsJson = const Value.absent(),
  }) => Run(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
    pausedS: pausedS ?? this.pausedS,
    durationS: durationS ?? this.durationS,
    distanceM: distanceM ?? this.distanceM,
    hrPresetId: hrPresetId.present ? hrPresetId.value : this.hrPresetId,
    avgHr: avgHr.present ? avgHr.value : this.avgHr,
    maxHr: maxHr.present ? maxHr.value : this.maxHr,
    notes: notes ?? this.notes,
    bestsJson: bestsJson.present ? bestsJson.value : this.bestsJson,
    kind: kind ?? this.kind,
    effort: effort.present ? effort.value : this.effort,
    weather: weather.present ? weather.value : this.weather,
    shoeId: shoeId.present ? shoeId.value : this.shoeId,
    steps: steps.present ? steps.value : this.steps,
    avgCadence: avgCadence.present ? avgCadence.value : this.avgCadence,
    elevGainM: elevGainM.present ? elevGainM.value : this.elevGainM,
    elevLossM: elevLossM.present ? elevLossM.value : this.elevLossM,
    planId: planId.present ? planId.value : this.planId,
    lapsJson: lapsJson.present ? lapsJson.value : this.lapsJson,
  );
  Run copyWithCompanion(RunsCompanion data) {
    return Run(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
      pausedS: data.pausedS.present ? data.pausedS.value : this.pausedS,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      hrPresetId: data.hrPresetId.present ? data.hrPresetId.value : this.hrPresetId,
      avgHr: data.avgHr.present ? data.avgHr.value : this.avgHr,
      maxHr: data.maxHr.present ? data.maxHr.value : this.maxHr,
      notes: data.notes.present ? data.notes.value : this.notes,
      bestsJson: data.bestsJson.present ? data.bestsJson.value : this.bestsJson,
      kind: data.kind.present ? data.kind.value : this.kind,
      effort: data.effort.present ? data.effort.value : this.effort,
      weather: data.weather.present ? data.weather.value : this.weather,
      shoeId: data.shoeId.present ? data.shoeId.value : this.shoeId,
      steps: data.steps.present ? data.steps.value : this.steps,
      avgCadence: data.avgCadence.present ? data.avgCadence.value : this.avgCadence,
      elevGainM: data.elevGainM.present ? data.elevGainM.value : this.elevGainM,
      elevLossM: data.elevLossM.present ? data.elevLossM.value : this.elevLossM,
      planId: data.planId.present ? data.planId.value : this.planId,
      lapsJson: data.lapsJson.present ? data.lapsJson.value : this.lapsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Run(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('pausedS: $pausedS, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('hrPresetId: $hrPresetId, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('notes: $notes, ')
          ..write('bestsJson: $bestsJson, ')
          ..write('kind: $kind, ')
          ..write('effort: $effort, ')
          ..write('weather: $weather, ')
          ..write('shoeId: $shoeId, ')
          ..write('steps: $steps, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('elevGainM: $elevGainM, ')
          ..write('elevLossM: $elevLossM, ')
          ..write('planId: $planId, ')
          ..write('lapsJson: $lapsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    updatedAt,
    name,
    startedAt,
    endedAt,
    pausedAt,
    pausedS,
    durationS,
    distanceM,
    hrPresetId,
    avgHr,
    maxHr,
    notes,
    bestsJson,
    kind,
    effort,
    weather,
    shoeId,
    steps,
    avgCadence,
    elevGainM,
    elevLossM,
    planId,
    lapsJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Run &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.pausedAt == this.pausedAt &&
          other.pausedS == this.pausedS &&
          other.durationS == this.durationS &&
          other.distanceM == this.distanceM &&
          other.hrPresetId == this.hrPresetId &&
          other.avgHr == this.avgHr &&
          other.maxHr == this.maxHr &&
          other.notes == this.notes &&
          other.bestsJson == this.bestsJson &&
          other.kind == this.kind &&
          other.effort == this.effort &&
          other.weather == this.weather &&
          other.shoeId == this.shoeId &&
          other.steps == this.steps &&
          other.avgCadence == this.avgCadence &&
          other.elevGainM == this.elevGainM &&
          other.elevLossM == this.elevLossM &&
          other.planId == this.planId &&
          other.lapsJson == this.lapsJson);
}

class RunsCompanion extends UpdateCompanion<Run> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<DateTime?> pausedAt;
  final Value<int> pausedS;
  final Value<int> durationS;
  final Value<double> distanceM;
  final Value<String?> hrPresetId;
  final Value<int?> avgHr;
  final Value<int?> maxHr;
  final Value<String> notes;
  final Value<String?> bestsJson;
  final Value<RunKind> kind;
  final Value<int?> effort;
  final Value<String?> weather;
  final Value<String?> shoeId;
  final Value<int?> steps;
  final Value<int?> avgCadence;
  final Value<double?> elevGainM;
  final Value<double?> elevLossM;
  final Value<String?> planId;
  final Value<String?> lapsJson;
  final Value<int> rowid;
  const RunsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.pausedS = const Value.absent(),
    this.durationS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.hrPresetId = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.notes = const Value.absent(),
    this.bestsJson = const Value.absent(),
    this.kind = const Value.absent(),
    this.effort = const Value.absent(),
    this.weather = const Value.absent(),
    this.shoeId = const Value.absent(),
    this.steps = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.elevGainM = const Value.absent(),
    this.elevLossM = const Value.absent(),
    this.planId = const Value.absent(),
    this.lapsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.pausedS = const Value.absent(),
    this.durationS = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.hrPresetId = const Value.absent(),
    this.avgHr = const Value.absent(),
    this.maxHr = const Value.absent(),
    this.notes = const Value.absent(),
    this.bestsJson = const Value.absent(),
    this.kind = const Value.absent(),
    this.effort = const Value.absent(),
    this.weather = const Value.absent(),
    this.shoeId = const Value.absent(),
    this.steps = const Value.absent(),
    this.avgCadence = const Value.absent(),
    this.elevGainM = const Value.absent(),
    this.elevLossM = const Value.absent(),
    this.planId = const Value.absent(),
    this.lapsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : startedAt = Value(startedAt);
  static Insertable<Run> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<DateTime>? pausedAt,
    Expression<int>? pausedS,
    Expression<int>? durationS,
    Expression<double>? distanceM,
    Expression<String>? hrPresetId,
    Expression<int>? avgHr,
    Expression<int>? maxHr,
    Expression<String>? notes,
    Expression<String>? bestsJson,
    Expression<int>? kind,
    Expression<int>? effort,
    Expression<String>? weather,
    Expression<String>? shoeId,
    Expression<int>? steps,
    Expression<int>? avgCadence,
    Expression<double>? elevGainM,
    Expression<double>? elevLossM,
    Expression<String>? planId,
    Expression<String>? lapsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (pausedS != null) 'paused_s': pausedS,
      if (durationS != null) 'duration_s': durationS,
      if (distanceM != null) 'distance_m': distanceM,
      if (hrPresetId != null) 'hr_preset_id': hrPresetId,
      if (avgHr != null) 'avg_hr': avgHr,
      if (maxHr != null) 'max_hr': maxHr,
      if (notes != null) 'notes': notes,
      if (bestsJson != null) 'bests_json': bestsJson,
      if (kind != null) 'kind': kind,
      if (effort != null) 'effort': effort,
      if (weather != null) 'weather': weather,
      if (shoeId != null) 'shoe_id': shoeId,
      if (steps != null) 'steps': steps,
      if (avgCadence != null) 'avg_cadence': avgCadence,
      if (elevGainM != null) 'elev_gain_m': elevGainM,
      if (elevLossM != null) 'elev_loss_m': elevLossM,
      if (planId != null) 'plan_id': planId,
      if (lapsJson != null) 'laps_json': lapsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<DateTime?>? pausedAt,
    Value<int>? pausedS,
    Value<int>? durationS,
    Value<double>? distanceM,
    Value<String?>? hrPresetId,
    Value<int?>? avgHr,
    Value<int?>? maxHr,
    Value<String>? notes,
    Value<String?>? bestsJson,
    Value<RunKind>? kind,
    Value<int?>? effort,
    Value<String?>? weather,
    Value<String?>? shoeId,
    Value<int?>? steps,
    Value<int?>? avgCadence,
    Value<double?>? elevGainM,
    Value<double?>? elevLossM,
    Value<String?>? planId,
    Value<String?>? lapsJson,
    Value<int>? rowid,
  }) {
    return RunsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      pausedS: pausedS ?? this.pausedS,
      durationS: durationS ?? this.durationS,
      distanceM: distanceM ?? this.distanceM,
      hrPresetId: hrPresetId ?? this.hrPresetId,
      avgHr: avgHr ?? this.avgHr,
      maxHr: maxHr ?? this.maxHr,
      notes: notes ?? this.notes,
      bestsJson: bestsJson ?? this.bestsJson,
      kind: kind ?? this.kind,
      effort: effort ?? this.effort,
      weather: weather ?? this.weather,
      shoeId: shoeId ?? this.shoeId,
      steps: steps ?? this.steps,
      avgCadence: avgCadence ?? this.avgCadence,
      elevGainM: elevGainM ?? this.elevGainM,
      elevLossM: elevLossM ?? this.elevLossM,
      planId: planId ?? this.planId,
      lapsJson: lapsJson ?? this.lapsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<DateTime>(pausedAt.value);
    }
    if (pausedS.present) {
      map['paused_s'] = Variable<int>(pausedS.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<double>(distanceM.value);
    }
    if (hrPresetId.present) {
      map['hr_preset_id'] = Variable<String>(hrPresetId.value);
    }
    if (avgHr.present) {
      map['avg_hr'] = Variable<int>(avgHr.value);
    }
    if (maxHr.present) {
      map['max_hr'] = Variable<int>(maxHr.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (bestsJson.present) {
      map['bests_json'] = Variable<String>(bestsJson.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>($RunsTable.$converterkind.toSql(kind.value));
    }
    if (effort.present) {
      map['effort'] = Variable<int>(effort.value);
    }
    if (weather.present) {
      map['weather'] = Variable<String>(weather.value);
    }
    if (shoeId.present) {
      map['shoe_id'] = Variable<String>(shoeId.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (avgCadence.present) {
      map['avg_cadence'] = Variable<int>(avgCadence.value);
    }
    if (elevGainM.present) {
      map['elev_gain_m'] = Variable<double>(elevGainM.value);
    }
    if (elevLossM.present) {
      map['elev_loss_m'] = Variable<double>(elevLossM.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (lapsJson.present) {
      map['laps_json'] = Variable<String>(lapsJson.value);
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
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('pausedS: $pausedS, ')
          ..write('durationS: $durationS, ')
          ..write('distanceM: $distanceM, ')
          ..write('hrPresetId: $hrPresetId, ')
          ..write('avgHr: $avgHr, ')
          ..write('maxHr: $maxHr, ')
          ..write('notes: $notes, ')
          ..write('bestsJson: $bestsJson, ')
          ..write('kind: $kind, ')
          ..write('effort: $effort, ')
          ..write('weather: $weather, ')
          ..write('shoeId: $shoeId, ')
          ..write('steps: $steps, ')
          ..write('avgCadence: $avgCadence, ')
          ..write('elevGainM: $elevGainM, ')
          ..write('elevLossM: $elevLossM, ')
          ..write('planId: $planId, ')
          ..write('lapsJson: $lapsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunPointsTable extends RunPoints with TableInfo<$RunPointsTable, RunPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _runIdMeta = const VerificationMeta('runId');
  @override
  late final GeneratedColumn<String> runId = GeneratedColumn<String>(
    'run_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES runs (id) ON DELETE CASCADE'),
  );
  static const VerificationMeta _timeMeta = const VerificationMeta('time');
  @override
  late final GeneratedColumn<DateTime> time = GeneratedColumn<DateTime>(
    'time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta('accuracy');
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta('altitude');
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _segmentMeta = const VerificationMeta('segment');
  @override
  late final GeneratedColumn<int> segment = GeneratedColumn<int>(
    'segment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _hrMeta = const VerificationMeta('hr');
  @override
  late final GeneratedColumn<int> hr = GeneratedColumn<int>(
    'hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, runId, time, lat, lon, accuracy, altitude, segment, hr];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_points';
  @override
  VerificationContext validateIntegrity(Insertable<RunPoint> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('run_id')) {
      context.handle(_runIdMeta, runId.isAcceptableOrUnknown(data['run_id']!, _runIdMeta));
    } else if (isInserting) {
      context.missing(_runIdMeta);
    }
    if (data.containsKey('time')) {
      context.handle(_timeMeta, time.isAcceptableOrUnknown(data['time']!, _timeMeta));
    } else if (isInserting) {
      context.missing(_timeMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(_latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(_lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(_accuracyMeta, accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta));
    }
    if (data.containsKey('altitude')) {
      context.handle(_altitudeMeta, altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta));
    }
    if (data.containsKey('segment')) {
      context.handle(_segmentMeta, segment.isAcceptableOrUnknown(data['segment']!, _segmentMeta));
    }
    if (data.containsKey('hr')) {
      context.handle(_hrMeta, hr.isAcceptableOrUnknown(data['hr']!, _hrMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunPoint(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      runId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}run_id'])!,
      time: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}time'])!,
      lat: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      accuracy: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}accuracy']),
      altitude: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}altitude']),
      segment: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}segment'])!,
      hr: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}hr']),
    );
  }

  @override
  $RunPointsTable createAlias(String alias) {
    return $RunPointsTable(attachedDatabase, alias);
  }
}

class RunPoint extends DataClass implements Insertable<RunPoint> {
  final String id;
  final DateTime updatedAt;
  final String runId;
  final DateTime time;
  final double lat;
  final double lon;

  /// Metres (GPS accuracy radius / altitude).
  final double? accuracy;
  final double? altitude;

  /// Pauses split the route: points of different segments are not joined.
  final int segment;

  /// Heart rate at this point (null without a signal).
  final int? hr;
  const RunPoint({
    required this.id,
    required this.updatedAt,
    required this.runId,
    required this.time,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.altitude,
    required this.segment,
    this.hr,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['run_id'] = Variable<String>(runId);
    map['time'] = Variable<DateTime>(time);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    map['segment'] = Variable<int>(segment);
    if (!nullToAbsent || hr != null) {
      map['hr'] = Variable<int>(hr);
    }
    return map;
  }

  RunPointsCompanion toCompanion(bool nullToAbsent) {
    return RunPointsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      runId: Value(runId),
      time: Value(time),
      lat: Value(lat),
      lon: Value(lon),
      accuracy: accuracy == null && nullToAbsent ? const Value.absent() : Value(accuracy),
      altitude: altitude == null && nullToAbsent ? const Value.absent() : Value(altitude),
      segment: Value(segment),
      hr: hr == null && nullToAbsent ? const Value.absent() : Value(hr),
    );
  }

  factory RunPoint.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunPoint(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      runId: serializer.fromJson<String>(json['runId']),
      time: serializer.fromJson<DateTime>(json['time']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      segment: serializer.fromJson<int>(json['segment']),
      hr: serializer.fromJson<int?>(json['hr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'runId': serializer.toJson<String>(runId),
      'time': serializer.toJson<DateTime>(time),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'accuracy': serializer.toJson<double?>(accuracy),
      'altitude': serializer.toJson<double?>(altitude),
      'segment': serializer.toJson<int>(segment),
      'hr': serializer.toJson<int?>(hr),
    };
  }

  RunPoint copyWith({
    String? id,
    DateTime? updatedAt,
    String? runId,
    DateTime? time,
    double? lat,
    double? lon,
    Value<double?> accuracy = const Value.absent(),
    Value<double?> altitude = const Value.absent(),
    int? segment,
    Value<int?> hr = const Value.absent(),
  }) => RunPoint(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    runId: runId ?? this.runId,
    time: time ?? this.time,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    altitude: altitude.present ? altitude.value : this.altitude,
    segment: segment ?? this.segment,
    hr: hr.present ? hr.value : this.hr,
  );
  RunPoint copyWithCompanion(RunPointsCompanion data) {
    return RunPoint(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      runId: data.runId.present ? data.runId.value : this.runId,
      time: data.time.present ? data.time.value : this.time,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      segment: data.segment.present ? data.segment.value : this.segment,
      hr: data.hr.present ? data.hr.value : this.hr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunPoint(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('runId: $runId, ')
          ..write('time: $time, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracy: $accuracy, ')
          ..write('altitude: $altitude, ')
          ..write('segment: $segment, ')
          ..write('hr: $hr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, runId, time, lat, lon, accuracy, altitude, segment, hr);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunPoint &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.runId == this.runId &&
          other.time == this.time &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.accuracy == this.accuracy &&
          other.altitude == this.altitude &&
          other.segment == this.segment &&
          other.hr == this.hr);
}

class RunPointsCompanion extends UpdateCompanion<RunPoint> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> runId;
  final Value<DateTime> time;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double?> accuracy;
  final Value<double?> altitude;
  final Value<int> segment;
  final Value<int?> hr;
  final Value<int> rowid;
  const RunPointsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.runId = const Value.absent(),
    this.time = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.altitude = const Value.absent(),
    this.segment = const Value.absent(),
    this.hr = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunPointsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String runId,
    required DateTime time,
    required double lat,
    required double lon,
    this.accuracy = const Value.absent(),
    this.altitude = const Value.absent(),
    this.segment = const Value.absent(),
    this.hr = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : runId = Value(runId),
       time = Value(time),
       lat = Value(lat),
       lon = Value(lon);
  static Insertable<RunPoint> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? runId,
    Expression<DateTime>? time,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? accuracy,
    Expression<double>? altitude,
    Expression<int>? segment,
    Expression<int>? hr,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (runId != null) 'run_id': runId,
      if (time != null) 'time': time,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (segment != null) 'segment': segment,
      if (hr != null) 'hr': hr,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunPointsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? runId,
    Value<DateTime>? time,
    Value<double>? lat,
    Value<double>? lon,
    Value<double?>? accuracy,
    Value<double?>? altitude,
    Value<int>? segment,
    Value<int?>? hr,
    Value<int>? rowid,
  }) {
    return RunPointsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      runId: runId ?? this.runId,
      time: time ?? this.time,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      segment: segment ?? this.segment,
      hr: hr ?? this.hr,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (runId.present) {
      map['run_id'] = Variable<String>(runId.value);
    }
    if (time.present) {
      map['time'] = Variable<DateTime>(time.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (segment.present) {
      map['segment'] = Variable<int>(segment.value);
    }
    if (hr.present) {
      map['hr'] = Variable<int>(hr.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunPointsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('runId: $runId, ')
          ..write('time: $time, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracy: $accuracy, ')
          ..write('altitude: $altitude, ')
          ..write('segment: $segment, ')
          ..write('hr: $hr, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoesTable extends Shoes with TableInfo<$ShoesTable, Shoe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startKmMeta = const VerificationMeta('startKm');
  @override
  late final GeneratedColumn<double> startKm = GeneratedColumn<double>(
    'start_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _limitKmMeta = const VerificationMeta('limitKm');
  @override
  late final GeneratedColumn<double> limitKm = GeneratedColumn<double>(
    'limit_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(700),
  );
  static const VerificationMeta _retiredMeta = const VerificationMeta('retired');
  @override
  late final GeneratedColumn<bool> retired = GeneratedColumn<bool>(
    'retired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("retired" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta('isDefault');
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("is_default" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, name, startKm, limitKm, retired, isDefault];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shoes';
  @override
  VerificationContext validateIntegrity(Insertable<Shoe> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('start_km')) {
      context.handle(_startKmMeta, startKm.isAcceptableOrUnknown(data['start_km']!, _startKmMeta));
    }
    if (data.containsKey('limit_km')) {
      context.handle(_limitKmMeta, limitKm.isAcceptableOrUnknown(data['limit_km']!, _limitKmMeta));
    }
    if (data.containsKey('retired')) {
      context.handle(_retiredMeta, retired.isAcceptableOrUnknown(data['retired']!, _retiredMeta));
    }
    if (data.containsKey('is_default')) {
      context.handle(_isDefaultMeta, isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shoe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shoe(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      startKm: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}start_km'])!,
      limitKm: attachedDatabase.typeMapping.read(DriftSqlType.double, data['${effectivePrefix}limit_km'])!,
      retired: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}retired'])!,
      isDefault: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}is_default'])!,
    );
  }

  @override
  $ShoesTable createAlias(String alias) {
    return $ShoesTable(attachedDatabase, alias);
  }
}

class Shoe extends DataClass implements Insertable<Shoe> {
  final String id;
  final DateTime updatedAt;
  final String name;

  /// Km the shoes already had when added.
  final double startKm;

  /// Replace them at about this many km (reminder).
  final double limitKm;
  final bool retired;

  /// Picked automatically for new runs.
  final bool isDefault;
  const Shoe({
    required this.id,
    required this.updatedAt,
    required this.name,
    required this.startKm,
    required this.limitKm,
    required this.retired,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['start_km'] = Variable<double>(startKm);
    map['limit_km'] = Variable<double>(limitKm);
    map['retired'] = Variable<bool>(retired);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  ShoesCompanion toCompanion(bool nullToAbsent) {
    return ShoesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      name: Value(name),
      startKm: Value(startKm),
      limitKm: Value(limitKm),
      retired: Value(retired),
      isDefault: Value(isDefault),
    );
  }

  factory Shoe.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shoe(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      startKm: serializer.fromJson<double>(json['startKm']),
      limitKm: serializer.fromJson<double>(json['limitKm']),
      retired: serializer.fromJson<bool>(json['retired']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'startKm': serializer.toJson<double>(startKm),
      'limitKm': serializer.toJson<double>(limitKm),
      'retired': serializer.toJson<bool>(retired),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  Shoe copyWith({
    String? id,
    DateTime? updatedAt,
    String? name,
    double? startKm,
    double? limitKm,
    bool? retired,
    bool? isDefault,
  }) => Shoe(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    startKm: startKm ?? this.startKm,
    limitKm: limitKm ?? this.limitKm,
    retired: retired ?? this.retired,
    isDefault: isDefault ?? this.isDefault,
  );
  Shoe copyWithCompanion(ShoesCompanion data) {
    return Shoe(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      startKm: data.startKm.present ? data.startKm.value : this.startKm,
      limitKm: data.limitKm.present ? data.limitKm.value : this.limitKm,
      retired: data.retired.present ? data.retired.value : this.retired,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shoe(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('startKm: $startKm, ')
          ..write('limitKm: $limitKm, ')
          ..write('retired: $retired, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, name, startKm, limitKm, retired, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shoe &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.startKm == this.startKm &&
          other.limitKm == this.limitKm &&
          other.retired == this.retired &&
          other.isDefault == this.isDefault);
}

class ShoesCompanion extends UpdateCompanion<Shoe> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<double> startKm;
  final Value<double> limitKm;
  final Value<bool> retired;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const ShoesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.startKm = const Value.absent(),
    this.limitKm = const Value.absent(),
    this.retired = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    this.startKm = const Value.absent(),
    this.limitKm = const Value.absent(),
    this.retired = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Shoe> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<double>? startKm,
    Expression<double>? limitKm,
    Expression<bool>? retired,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (startKm != null) 'start_km': startKm,
      if (limitKm != null) 'limit_km': limitKm,
      if (retired != null) 'retired': retired,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<double>? startKm,
    Value<double>? limitKm,
    Value<bool>? retired,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return ShoesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      startKm: startKm ?? this.startKm,
      limitKm: limitKm ?? this.limitKm,
      retired: retired ?? this.retired,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startKm.present) {
      map['start_km'] = Variable<double>(startKm.value);
    }
    if (limitKm.present) {
      map['limit_km'] = Variable<double>(limitKm.value);
    }
    if (retired.present) {
      map['retired'] = Variable<bool>(retired.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('startKm: $startKm, ')
          ..write('limitKm: $limitKm, ')
          ..write('retired: $retired, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RunPlansTable extends RunPlans with TableInfo<$RunPlansTable, RunPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RunPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _specJsonMeta = const VerificationMeta('specJson');
  @override
  late final GeneratedColumn<String> specJson = GeneratedColumn<String>(
    'spec_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, name, specJson, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'run_plans';
  @override
  VerificationContext validateIntegrity(Insertable<RunPlan> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('spec_json')) {
      context.handle(_specJsonMeta, specJson.isAcceptableOrUnknown(data['spec_json']!, _specJsonMeta));
    } else if (isInserting) {
      context.missing(_specJsonMeta);
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta, position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RunPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RunPlan(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      specJson: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}spec_json'])!,
      position: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}position'])!,
    );
  }

  @override
  $RunPlansTable createAlias(String alias) {
    return $RunPlansTable(attachedDatabase, alias);
  }
}

class RunPlan extends DataClass implements Insertable<RunPlan> {
  final String id;
  final DateTime updatedAt;
  final String name;
  final String specJson;
  final int position;
  const RunPlan({
    required this.id,
    required this.updatedAt,
    required this.name,
    required this.specJson,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['spec_json'] = Variable<String>(specJson);
    map['position'] = Variable<int>(position);
    return map;
  }

  RunPlansCompanion toCompanion(bool nullToAbsent) {
    return RunPlansCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      name: Value(name),
      specJson: Value(specJson),
      position: Value(position),
    );
  }

  factory RunPlan.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RunPlan(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      specJson: serializer.fromJson<String>(json['specJson']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'specJson': serializer.toJson<String>(specJson),
      'position': serializer.toJson<int>(position),
    };
  }

  RunPlan copyWith({String? id, DateTime? updatedAt, String? name, String? specJson, int? position}) => RunPlan(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    specJson: specJson ?? this.specJson,
    position: position ?? this.position,
  );
  RunPlan copyWithCompanion(RunPlansCompanion data) {
    return RunPlan(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      specJson: data.specJson.present ? data.specJson.value : this.specJson,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RunPlan(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('specJson: $specJson, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, name, specJson, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RunPlan &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.specJson == this.specJson &&
          other.position == this.position);
}

class RunPlansCompanion extends UpdateCompanion<RunPlan> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String> specJson;
  final Value<int> position;
  final Value<int> rowid;
  const RunPlansCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.specJson = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RunPlansCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    required String name,
    required String specJson,
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       specJson = Value(specJson);
  static Insertable<RunPlan> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? specJson,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (specJson != null) 'spec_json': specJson,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RunPlansCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String>? specJson,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return RunPlansCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      specJson: specJson ?? this.specJson,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (specJson.present) {
      map['spec_json'] = Variable<String>(specJson.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RunPlansCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('specJson: $specJson, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $TemplateExercisesTable templateExercises = $TemplateExercisesTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WorkoutExercisesTable workoutExercises = $WorkoutExercisesTable(this);
  late final $WorkoutSetsTable workoutSets = $WorkoutSetsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $BodyMeasurementsTable bodyMeasurements = $BodyMeasurementsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $HrPresetsTable hrPresets = $HrPresetsTable(this);
  late final $IntervalPresetsTable intervalPresets = $IntervalPresetsTable(this);
  late final $RunsTable runs = $RunsTable(this);
  late final $RunPointsTable runPoints = $RunPointsTable(this);
  late final $ShoesTable shoes = $ShoesTable(this);
  late final $RunPlansTable runPlans = $RunPlansTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercises,
    templates,
    templateExercises,
    workouts,
    workoutExercises,
    workoutSets,
    settings,
    bodyMeasurements,
    goals,
    hrPresets,
    intervalPresets,
    runs,
    runPoints,
    shoes,
    runPlans,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName('templates', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('template_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('workouts', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('workout_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('workouts', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('workout_sets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('workout_exercises', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('workout_sets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName('runs', limitUpdateKind: UpdateKind.delete),
      result: [TableUpdate('run_points', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String name,
  required String primaryMuscle,
  Value<String> secondaryMuscles,
  Value<String?> equipment,
  Value<String> category,
  required TrackingType trackingType,
  Value<String> instructions,
  Value<String?> imagePath,
  Value<bool> isCustom,
  Value<int> defaultRestSeconds,
  Value<int?> popularity,
  Value<bool> hidden,
  Value<String?> level,
  Value<bool> unilateral,
  Value<String?> note,
  Value<DateTime?> noteAt,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<String> primaryMuscle,
  Value<String> secondaryMuscles,
  Value<String?> equipment,
  Value<String> category,
  Value<TrackingType> trackingType,
  Value<String> instructions,
  Value<String?> imagePath,
  Value<bool> isCustom,
  Value<int> defaultRestSeconds,
  Value<int?> popularity,
  Value<bool> hidden,
  Value<String?> level,
  Value<bool> unilateral,
  Value<String?> note,
  Value<DateTime?> noteAt,
  Value<int> rowid,
});

final class $$ExercisesTableReferences extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>> _templateExercisesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.templateExercises, aliasName: 'exercises__id__template_exercises__exercise_id');

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateExercisesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutExercisesTable, List<WorkoutExercise>> _workoutExercisesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.workoutExercises, aliasName: 'exercises__id__workout_exercises__exercise_id');

  $$WorkoutExercisesTableProcessedTableManager get workoutExercisesRefs {
    final manager = $$WorkoutExercisesTableTableManager(
      $_db,
      $_db.workoutExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutExercisesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>> _workoutSetsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.workoutSets, aliasName: 'exercises__id__workout_sets__exercise_id');

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager(
      $_db,
      $_db.workoutSets,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ExercisesTableFilterComposer extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get primaryMuscle =>
      $composableBuilder(column: $table.primaryMuscle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get secondaryMuscles =>
      $composableBuilder(column: $table.secondaryMuscles, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TrackingType, TrackingType, int> get trackingType =>
      $composableBuilder(column: $table.trackingType, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get instructions =>
      $composableBuilder(column: $table.instructions, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get defaultRestSeconds =>
      $composableBuilder(column: $table.defaultRestSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get popularity =>
      $composableBuilder(column: $table.popularity, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get unilateral =>
      $composableBuilder(column: $table.unilateral, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get noteAt =>
      $composableBuilder(column: $table.noteAt, builder: (column) => ColumnFilters(column));

  Expression<bool> templateExercisesRefs(Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutExercisesRefs(Expression<bool> Function($$WorkoutExercisesTableFilterComposer f) f) {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutSetsRefs(Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get primaryMuscle =>
      $composableBuilder(column: $table.primaryMuscle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get secondaryMuscles =>
      $composableBuilder(column: $table.secondaryMuscles, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get trackingType =>
      $composableBuilder(column: $table.trackingType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get instructions =>
      $composableBuilder(column: $table.instructions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get defaultRestSeconds =>
      $composableBuilder(column: $table.defaultRestSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get popularity =>
      $composableBuilder(column: $table.popularity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get unilateral =>
      $composableBuilder(column: $table.unilateral, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get noteAt =>
      $composableBuilder(column: $table.noteAt, builder: (column) => ColumnOrderings(column));
}

class $$ExercisesTableAnnotationComposer extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get primaryMuscle =>
      $composableBuilder(column: $table.primaryMuscle, builder: (column) => column);

  GeneratedColumn<String> get secondaryMuscles =>
      $composableBuilder(column: $table.secondaryMuscles, builder: (column) => column);

  GeneratedColumn<String> get equipment => $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get category => $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrackingType, int> get trackingType =>
      $composableBuilder(column: $table.trackingType, builder: (column) => column);

  GeneratedColumn<String> get instructions =>
      $composableBuilder(column: $table.instructions, builder: (column) => column);

  GeneratedColumn<String> get imagePath => $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isCustom => $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<int> get defaultRestSeconds =>
      $composableBuilder(column: $table.defaultRestSeconds, builder: (column) => column);

  GeneratedColumn<int> get popularity => $composableBuilder(column: $table.popularity, builder: (column) => column);

  GeneratedColumn<bool> get hidden => $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<String> get level => $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<bool> get unilateral => $composableBuilder(column: $table.unilateral, builder: (column) => column);

  GeneratedColumn<String> get note => $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get noteAt => $composableBuilder(column: $table.noteAt, builder: (column) => column);

  Expression<T> templateExercisesRefs<T extends Object>(
    Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f,
  ) {
    final $$TemplateExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TemplateExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutExercisesRefs<T extends Object>(
    Expression<T> Function($$WorkoutExercisesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutSetsRefs<T extends Object>(Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.exerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({bool templateExercisesRefs, bool workoutExercisesRefs, bool workoutSetsRefs})
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> primaryMuscle = const Value.absent(),
                Value<String> secondaryMuscles = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<TrackingType> trackingType = const Value.absent(),
                Value<String> instructions = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<int> defaultRestSeconds = const Value.absent(),
                Value<int?> popularity = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String?> level = const Value.absent(),
                Value<bool> unilateral = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> noteAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                updatedAt: updatedAt,
                name: name,
                primaryMuscle: primaryMuscle,
                secondaryMuscles: secondaryMuscles,
                equipment: equipment,
                category: category,
                trackingType: trackingType,
                instructions: instructions,
                imagePath: imagePath,
                isCustom: isCustom,
                defaultRestSeconds: defaultRestSeconds,
                popularity: popularity,
                hidden: hidden,
                level: level,
                unilateral: unilateral,
                note: note,
                noteAt: noteAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                required String primaryMuscle,
                Value<String> secondaryMuscles = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String> category = const Value.absent(),
                required TrackingType trackingType,
                Value<String> instructions = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<int> defaultRestSeconds = const Value.absent(),
                Value<int?> popularity = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<String?> level = const Value.absent(),
                Value<bool> unilateral = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime?> noteAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                name: name,
                primaryMuscle: primaryMuscle,
                secondaryMuscles: secondaryMuscles,
                equipment: equipment,
                category: category,
                trackingType: trackingType,
                instructions: instructions,
                imagePath: imagePath,
                isCustom: isCustom,
                defaultRestSeconds: defaultRestSeconds,
                popularity: popularity,
                hidden: hidden,
                level: level,
                unilateral: unilateral,
                note: note,
                noteAt: noteAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$ExercisesTable, Exercise>(table), $$ExercisesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({templateExercisesRefs = false, workoutExercisesRefs = false, workoutSetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateExercisesRefs) db.templateExercises,
                    if (workoutExercisesRefs) db.workoutExercises,
                    if (workoutSetsRefs) db.workoutSets,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateExercisesRefs)
                        await $_getPrefetchedDataByColumns<
                          Exercise,
                          $ExercisesTable,
                          TemplateExercise,
                          $TemplateExercisesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences._templateExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(db, table, p0).templateExercisesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'exercise_id',
                          typedResults: items,
                        ),
                      if (workoutExercisesRefs)
                        await $_getPrefetchedDataByColumns<
                          Exercise,
                          $ExercisesTable,
                          WorkoutExercise,
                          $WorkoutExercisesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences._workoutExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(db, table, p0).workoutExercisesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'exercise_id',
                          typedResults: items,
                        ),
                      if (workoutSetsRefs)
                        await $_getPrefetchedDataByColumns<Exercise, $ExercisesTable, WorkoutSet, $WorkoutSetsTable>(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences._workoutSetsRefsTable(db),
                          managerFromTypedResult: (p0) => $$ExercisesTableReferences(db, table, p0).workoutSetsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'exercise_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({bool templateExercisesRefs, bool workoutExercisesRefs, bool workoutSetsRefs})
    >;
typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String name,
  Value<String?> folder,
  Value<String?> hrPresetId,
  Value<String> notes,
  Value<int> position,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<String?> folder,
  Value<String?> hrPresetId,
  Value<String> notes,
  Value<int> position,
  Value<int> rowid,
});

final class $$TemplatesTableReferences extends BaseReferences<_$AppDatabase, $TemplatesTable, Template> {
  $$TemplatesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>> _templateExercisesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.templateExercises, aliasName: 'templates__id__template_exercises__template_id');

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_templateExercisesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TemplatesTableFilterComposer extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hrPresetId =>
      $composableBuilder(column: $table.hrPresetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  Expression<bool> templateExercisesRefs(Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.templateId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableOrderingComposer extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hrPresetId =>
      $composableBuilder(column: $table.hrPresetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$TemplatesTableAnnotationComposer extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get folder => $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get hrPresetId => $composableBuilder(column: $table.hrPresetId, builder: (column) => column);

  GeneratedColumn<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  Expression<T> templateExercisesRefs<T extends Object>(
    Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f,
  ) {
    final $$TemplateExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.templateId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TemplateExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          Template,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (Template, $$TemplatesTableReferences),
          Template,
          PrefetchHooks Function({bool templateExercisesRefs})
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<String?> hrPresetId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion(
                id: id,
                updatedAt: updatedAt,
                name: name,
                folder: folder,
                hrPresetId: hrPresetId,
                notes: notes,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                Value<String?> folder = const Value.absent(),
                Value<String?> hrPresetId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                name: name,
                folder: folder,
                hrPresetId: hrPresetId,
                notes: notes,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$TemplatesTable, Template>(table), $$TemplatesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({templateExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (templateExercisesRefs) db.templateExercises],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (templateExercisesRefs)
                    await $_getPrefetchedDataByColumns<
                      Template,
                      $TemplatesTable,
                      TemplateExercise,
                      $TemplateExercisesTable
                    >(
                      currentTable: table,
                      referencedTable: $$TemplatesTableReferences._templateExercisesRefsTable(db),
                      managerFromTypedResult: (p0) => $$TemplatesTableReferences(db, table, p0).templateExercisesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'template_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      Template,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (Template, $$TemplatesTableReferences),
      Template,
      PrefetchHooks Function({bool templateExercisesRefs})
    >;
typedef $$TemplateExercisesTableCreateCompanionBuilder = TemplateExercisesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String templateId,
  required String exerciseId,
  required int position,
  Value<int> targetSets,
  Value<int> restSeconds,
  Value<int?> supersetGroup,
  Value<String?> subExerciseIds,
  Value<String?> setsJson,
  Value<int> rowid,
});
typedef $$TemplateExercisesTableUpdateCompanionBuilder = TemplateExercisesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> templateId,
  Value<String> exerciseId,
  Value<int> position,
  Value<int> targetSets,
  Value<int> restSeconds,
  Value<int?> supersetGroup,
  Value<String?> subExerciseIds,
  Value<String?> setsJson,
  Value<int> rowid,
});

final class $$TemplateExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $TemplateExercisesTable, TemplateExercise> {
  $$TemplateExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.templates.createAlias('template_exercises__template_id__templates__id');

  $$TemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$TemplatesTableTableManager($_db, $_db.templates).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('template_exercises__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TemplateExercisesTableFilterComposer extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get targetSets =>
      $composableBuilder(column: $table.targetSets, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restSeconds =>
      $composableBuilder(column: $table.restSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get supersetGroup =>
      $composableBuilder(column: $table.supersetGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subExerciseIds =>
      $composableBuilder(column: $table.subExerciseIds, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get setsJson =>
      $composableBuilder(column: $table.setsJson, builder: (column) => ColumnFilters(column));

  $$TemplatesTableFilterComposer get templateId {
    final $$TemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TemplatesTableFilterComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableOrderingComposer extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get targetSets =>
      $composableBuilder(column: $table.targetSets, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restSeconds =>
      $composableBuilder(column: $table.restSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get supersetGroup =>
      $composableBuilder(column: $table.supersetGroup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subExerciseIds =>
      $composableBuilder(column: $table.subExerciseIds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get setsJson =>
      $composableBuilder(column: $table.setsJson, builder: (column) => ColumnOrderings(column));

  $$TemplatesTableOrderingComposer get templateId {
    final $$TemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableAnnotationComposer extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get targetSets => $composableBuilder(column: $table.targetSets, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(column: $table.restSeconds, builder: (column) => column);

  GeneratedColumn<int> get supersetGroup =>
      $composableBuilder(column: $table.supersetGroup, builder: (column) => column);

  GeneratedColumn<String> get subExerciseIds =>
      $composableBuilder(column: $table.subExerciseIds, builder: (column) => column);

  GeneratedColumn<String> get setsJson => $composableBuilder(column: $table.setsJson, builder: (column) => column);

  $$TemplatesTableAnnotationComposer get templateId {
    final $$TemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.templates,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$TemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.templates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise,
          $$TemplateExercisesTableFilterComposer,
          $$TemplateExercisesTableOrderingComposer,
          $$TemplateExercisesTableAnnotationComposer,
          $$TemplateExercisesTableCreateCompanionBuilder,
          $$TemplateExercisesTableUpdateCompanionBuilder,
          (TemplateExercise, $$TemplateExercisesTableReferences),
          TemplateExercise,
          PrefetchHooks Function({bool templateId, bool exerciseId})
        > {
  $$TemplateExercisesTableTableManager(_$AppDatabase db, $TemplateExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$TemplateExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$TemplateExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$TemplateExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> targetSets = const Value.absent(),
                Value<int> restSeconds = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
                Value<String?> subExerciseIds = const Value.absent(),
                Value<String?> setsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateExercisesCompanion(
                id: id,
                updatedAt: updatedAt,
                templateId: templateId,
                exerciseId: exerciseId,
                position: position,
                targetSets: targetSets,
                restSeconds: restSeconds,
                supersetGroup: supersetGroup,
                subExerciseIds: subExerciseIds,
                setsJson: setsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String templateId,
                required String exerciseId,
                required int position,
                Value<int> targetSets = const Value.absent(),
                Value<int> restSeconds = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
                Value<String?> subExerciseIds = const Value.absent(),
                Value<String?> setsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateExercisesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                templateId: templateId,
                exerciseId: exerciseId,
                position: position,
                targetSets: targetSets,
                restSeconds: restSeconds,
                supersetGroup: supersetGroup,
                subExerciseIds: subExerciseIds,
                setsJson: setsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplateExercisesTable, TemplateExercise>(table),
                  $$TemplateExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (templateId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.templateId,
                        referencedTable: $$TemplateExercisesTableReferences._templateIdTable(db),
                        referencedColumn: $$TemplateExercisesTableReferences._templateIdTable(db).id,
                      ) as T;
                    }
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$TemplateExercisesTableReferences._exerciseIdTable(db),
                        referencedColumn: $$TemplateExercisesTableReferences._exerciseIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TemplateExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateExercisesTable,
      TemplateExercise,
      $$TemplateExercisesTableFilterComposer,
      $$TemplateExercisesTableOrderingComposer,
      $$TemplateExercisesTableAnnotationComposer,
      $$TemplateExercisesTableCreateCompanionBuilder,
      $$TemplateExercisesTableUpdateCompanionBuilder,
      (TemplateExercise, $$TemplateExercisesTableReferences),
      TemplateExercise,
      PrefetchHooks Function({bool templateId, bool exerciseId})
    >;
typedef $$WorkoutsTableCreateCompanionBuilder = WorkoutsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required WorkoutType type,
  required String name,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<String?> templateId,
  Value<String?> hrPresetId,
  Value<String> notes,
  Value<int?> avgHr,
  Value<int?> maxHr,
  Value<int> rowid,
});
typedef $$WorkoutsTableUpdateCompanionBuilder = WorkoutsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<WorkoutType> type,
  Value<String> name,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<String?> templateId,
  Value<String?> hrPresetId,
  Value<String> notes,
  Value<int?> avgHr,
  Value<int?> maxHr,
  Value<int> rowid,
});

final class $$WorkoutsTableReferences extends BaseReferences<_$AppDatabase, $WorkoutsTable, Workout> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutExercisesTable, List<WorkoutExercise>> _workoutExercisesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(db.workoutExercises, aliasName: 'workouts__id__workout_exercises__workout_id');

  $$WorkoutExercisesTableProcessedTableManager get workoutExercisesRefs {
    final manager = $$WorkoutExercisesTableTableManager(
      $_db,
      $_db.workoutExercises,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutExercisesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>> _workoutSetsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.workoutSets, aliasName: 'workouts__id__workout_sets__workout_id');

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager(
      $_db,
      $_db.workoutSets,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutsTableFilterComposer extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<WorkoutType, WorkoutType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateId =>
      $composableBuilder(column: $table.templateId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hrPresetId =>
      $composableBuilder(column: $table.hrPresetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avgHr => $composableBuilder(column: $table.avgHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxHr => $composableBuilder(column: $table.maxHr, builder: (column) => ColumnFilters(column));

  Expression<bool> workoutExercisesRefs(Expression<bool> Function($$WorkoutExercisesTableFilterComposer f) f) {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.workoutId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> workoutSetsRefs(Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.workoutId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableOrderingComposer extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateId =>
      $composableBuilder(column: $table.templateId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hrPresetId =>
      $composableBuilder(column: $table.hrPresetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxHr =>
      $composableBuilder(column: $table.maxHr, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutsTableAnnotationComposer extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WorkoutType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt => $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt => $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(column: $table.templateId, builder: (column) => column);

  GeneratedColumn<String> get hrPresetId => $composableBuilder(column: $table.hrPresetId, builder: (column) => column);

  GeneratedColumn<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get avgHr => $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<int> get maxHr => $composableBuilder(column: $table.maxHr, builder: (column) => column);

  Expression<T> workoutExercisesRefs<T extends Object>(
    Expression<T> Function($$WorkoutExercisesTableAnnotationComposer a) f,
  ) {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.workoutId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> workoutSetsRefs<T extends Object>(Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.workoutId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutsTable,
          Workout,
          $$WorkoutsTableFilterComposer,
          $$WorkoutsTableOrderingComposer,
          $$WorkoutsTableAnnotationComposer,
          $$WorkoutsTableCreateCompanionBuilder,
          $$WorkoutsTableUpdateCompanionBuilder,
          (Workout, $$WorkoutsTableReferences),
          Workout,
          PrefetchHooks Function({bool workoutExercisesRefs, bool workoutSetsRefs})
        > {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<WorkoutType> type = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<String?> hrPresetId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int?> avgHr = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion(
                id: id,
                updatedAt: updatedAt,
                type: type,
                name: name,
                startedAt: startedAt,
                endedAt: endedAt,
                templateId: templateId,
                hrPresetId: hrPresetId,
                notes: notes,
                avgHr: avgHr,
                maxHr: maxHr,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required WorkoutType type,
                required String name,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<String?> hrPresetId = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int?> avgHr = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                type: type,
                name: name,
                startedAt: startedAt,
                endedAt: endedAt,
                templateId: templateId,
                hrPresetId: hrPresetId,
                notes: notes,
                avgHr: avgHr,
                maxHr: maxHr,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$WorkoutsTable, Workout>(table), $$WorkoutsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({workoutExercisesRefs = false, workoutSetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutExercisesRefs) db.workoutExercises,
                if (workoutSetsRefs) db.workoutSets,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutExercisesRefs)
                    await $_getPrefetchedDataByColumns<
                      Workout,
                      $WorkoutsTable,
                      WorkoutExercise,
                      $WorkoutExercisesTable
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutsTableReferences._workoutExercisesRefsTable(db),
                      managerFromTypedResult: (p0) => $$WorkoutsTableReferences(db, table, p0).workoutExercisesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'workout_id',
                      typedResults: items,
                    ),
                  if (workoutSetsRefs)
                    await $_getPrefetchedDataByColumns<Workout, $WorkoutsTable, WorkoutSet, $WorkoutSetsTable>(
                      currentTable: table,
                      referencedTable: $$WorkoutsTableReferences._workoutSetsRefsTable(db),
                      managerFromTypedResult: (p0) => $$WorkoutsTableReferences(db, table, p0).workoutSetsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'workout_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutsTable,
      Workout,
      $$WorkoutsTableFilterComposer,
      $$WorkoutsTableOrderingComposer,
      $$WorkoutsTableAnnotationComposer,
      $$WorkoutsTableCreateCompanionBuilder,
      $$WorkoutsTableUpdateCompanionBuilder,
      (Workout, $$WorkoutsTableReferences),
      Workout,
      PrefetchHooks Function({bool workoutExercisesRefs, bool workoutSetsRefs})
    >;
typedef $$WorkoutExercisesTableCreateCompanionBuilder = WorkoutExercisesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String workoutId,
  required String exerciseId,
  required int position,
  Value<int> restSeconds,
  Value<int?> supersetGroup,
  Value<String> notes,
  Value<int> rowid,
});
typedef $$WorkoutExercisesTableUpdateCompanionBuilder = WorkoutExercisesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> workoutId,
  Value<String> exerciseId,
  Value<int> position,
  Value<int> restSeconds,
  Value<int?> supersetGroup,
  Value<String> notes,
  Value<int> rowid,
});

final class $$WorkoutExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutExercisesTable, WorkoutExercise> {
  $$WorkoutExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias('workout_exercises__workout_id__workouts__id');

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$WorkoutsTableTableManager($_db, $_db.workouts).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('workout_exercises__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$WorkoutSetsTable, List<WorkoutSet>> _workoutSetsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.workoutSets,
        aliasName: 'workout_exercises__id__workout_sets__workout_exercise_id',
      );

  $$WorkoutSetsTableProcessedTableManager get workoutSetsRefs {
    final manager = $$WorkoutSetsTableTableManager(
      $_db,
      $_db.workoutSets,
    ).filter((f) => f.workoutExerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutSetsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WorkoutExercisesTableFilterComposer extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get restSeconds =>
      $composableBuilder(column: $table.restSeconds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get supersetGroup =>
      $composableBuilder(column: $table.supersetGroup, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> workoutSetsRefs(Expression<bool> Function($$WorkoutSetsTableFilterComposer f) f) {
    final $$WorkoutSetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.workoutExerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutSetsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutExercisesTableOrderingComposer extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get restSeconds =>
      $composableBuilder(column: $table.restSeconds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get supersetGroup =>
      $composableBuilder(column: $table.supersetGroup, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutExercisesTableAnnotationComposer extends Composer<_$AppDatabase, $WorkoutExercisesTable> {
  $$WorkoutExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get restSeconds => $composableBuilder(column: $table.restSeconds, builder: (column) => column);

  GeneratedColumn<int> get supersetGroup =>
      $composableBuilder(column: $table.supersetGroup, builder: (column) => column);

  GeneratedColumn<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> workoutSetsRefs<T extends Object>(Expression<T> Function($$WorkoutSetsTableAnnotationComposer a) f) {
    final $$WorkoutSetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutSets,
      getReferencedColumn: (t) => t.workoutExerciseId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutSetsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutExercisesTable,
          WorkoutExercise,
          $$WorkoutExercisesTableFilterComposer,
          $$WorkoutExercisesTableOrderingComposer,
          $$WorkoutExercisesTableAnnotationComposer,
          $$WorkoutExercisesTableCreateCompanionBuilder,
          $$WorkoutExercisesTableUpdateCompanionBuilder,
          (WorkoutExercise, $$WorkoutExercisesTableReferences),
          WorkoutExercise,
          PrefetchHooks Function({bool workoutId, bool exerciseId, bool workoutSetsRefs})
        > {
  $$WorkoutExercisesTableTableManager(_$AppDatabase db, $WorkoutExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WorkoutExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WorkoutExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WorkoutExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> restSeconds = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutExercisesCompanion(
                id: id,
                updatedAt: updatedAt,
                workoutId: workoutId,
                exerciseId: exerciseId,
                position: position,
                restSeconds: restSeconds,
                supersetGroup: supersetGroup,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workoutId,
                required String exerciseId,
                required int position,
                Value<int> restSeconds = const Value.absent(),
                Value<int?> supersetGroup = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutExercisesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                workoutId: workoutId,
                exerciseId: exerciseId,
                position: position,
                restSeconds: restSeconds,
                supersetGroup: supersetGroup,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutExercisesTable, WorkoutExercise>(table),
                  $$WorkoutExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false, exerciseId = false, workoutSetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (workoutSetsRefs) db.workoutSets],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workoutId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workoutId,
                        referencedTable: $$WorkoutExercisesTableReferences._workoutIdTable(db),
                        referencedColumn: $$WorkoutExercisesTableReferences._workoutIdTable(db).id,
                      ) as T;
                    }
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$WorkoutExercisesTableReferences._exerciseIdTable(db),
                        referencedColumn: $$WorkoutExercisesTableReferences._exerciseIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutSetsRefs)
                    await $_getPrefetchedDataByColumns<
                      WorkoutExercise,
                      $WorkoutExercisesTable,
                      WorkoutSet,
                      $WorkoutSetsTable
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutExercisesTableReferences._workoutSetsRefsTable(db),
                      managerFromTypedResult: (p0) => $$WorkoutExercisesTableReferences(db, table, p0).workoutSetsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'workout_exercise_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutExercisesTable,
      WorkoutExercise,
      $$WorkoutExercisesTableFilterComposer,
      $$WorkoutExercisesTableOrderingComposer,
      $$WorkoutExercisesTableAnnotationComposer,
      $$WorkoutExercisesTableCreateCompanionBuilder,
      $$WorkoutExercisesTableUpdateCompanionBuilder,
      (WorkoutExercise, $$WorkoutExercisesTableReferences),
      WorkoutExercise,
      PrefetchHooks Function({bool workoutId, bool exerciseId, bool workoutSetsRefs})
    >;
typedef $$WorkoutSetsTableCreateCompanionBuilder = WorkoutSetsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String workoutId,
  required String workoutExerciseId,
  required String exerciseId,
  required int setIndex,
  Value<SetType> setType,
  Value<double?> weightKg,
  Value<int?> reps,
  Value<int?> durationS,
  Value<double?> distanceM,
  Value<double?> rpe,
  Value<String?> subExerciseId,
  Value<Side?> side,
  Value<int?> maxHr,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});
typedef $$WorkoutSetsTableUpdateCompanionBuilder = WorkoutSetsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> workoutId,
  Value<String> workoutExerciseId,
  Value<String> exerciseId,
  Value<int> setIndex,
  Value<SetType> setType,
  Value<double?> weightKg,
  Value<int?> reps,
  Value<int?> durationS,
  Value<double?> distanceM,
  Value<double?> rpe,
  Value<String?> subExerciseId,
  Value<Side?> side,
  Value<int?> maxHr,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});

final class $$WorkoutSetsTableReferences extends BaseReferences<_$AppDatabase, $WorkoutSetsTable, WorkoutSet> {
  $$WorkoutSetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias('workout_sets__workout_id__workouts__id');

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<String>('workout_id')!;

    final manager = $$WorkoutsTableTableManager($_db, $_db.workouts).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $WorkoutExercisesTable _workoutExerciseIdTable(_$AppDatabase db) =>
      db.workoutExercises.createAlias('workout_sets__workout_exercise_id__workout_exercises__id');

  $$WorkoutExercisesTableProcessedTableManager get workoutExerciseId {
    final $_column = $_itemColumn<String>('workout_exercise_id')!;

    final manager = $$WorkoutExercisesTableTableManager(
      $_db,
      $_db.workoutExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('workout_sets__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager($_db, $_db.exercises).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$WorkoutSetsTableFilterComposer extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<SetType, SetType, int> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reps => $composableBuilder(column: $table.reps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rpe => $composableBuilder(column: $table.rpe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subExerciseId =>
      $composableBuilder(column: $table.subExerciseId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Side?, Side, int> get side =>
      $composableBuilder(column: $table.side, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get maxHr => $composableBuilder(column: $table.maxHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnFilters(column));

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkoutExercisesTableFilterComposer get workoutExerciseId {
    final $$WorkoutExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutExerciseId,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutExercisesTableFilterComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableOrderingComposer extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setIndex =>
      $composableBuilder(column: $table.setIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rpe =>
      $composableBuilder(column: $table.rpe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subExerciseId =>
      $composableBuilder(column: $table.subExerciseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get side =>
      $composableBuilder(column: $table.side, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxHr =>
      $composableBuilder(column: $table.maxHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkoutExercisesTableOrderingComposer get workoutExerciseId {
    final $$WorkoutExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutExerciseId,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableAnnotationComposer extends Composer<_$AppDatabase, $WorkoutSetsTable> {
  $$WorkoutSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get setIndex => $composableBuilder(column: $table.setIndex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SetType, int> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => column);

  GeneratedColumn<double> get weightKg => $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<int> get reps => $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get durationS => $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<double> get distanceM => $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<double> get rpe => $composableBuilder(column: $table.rpe, builder: (column) => column);

  GeneratedColumn<String> get subExerciseId =>
      $composableBuilder(column: $table.subExerciseId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Side?, int> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumn<int> get maxHr => $composableBuilder(column: $table.maxHr, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt =>
      $composableBuilder(column: $table.completedAt, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$WorkoutExercisesTableAnnotationComposer get workoutExerciseId {
    final $$WorkoutExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutExerciseId,
      referencedTable: $db.workoutExercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$WorkoutExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSetsTable,
          WorkoutSet,
          $$WorkoutSetsTableFilterComposer,
          $$WorkoutSetsTableOrderingComposer,
          $$WorkoutSetsTableAnnotationComposer,
          $$WorkoutSetsTableCreateCompanionBuilder,
          $$WorkoutSetsTableUpdateCompanionBuilder,
          (WorkoutSet, $$WorkoutSetsTableReferences),
          WorkoutSet,
          PrefetchHooks Function({bool workoutId, bool workoutExerciseId, bool exerciseId})
        > {
  $$WorkoutSetsTableTableManager(_$AppDatabase db, $WorkoutSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$WorkoutSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$WorkoutSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$WorkoutSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> workoutId = const Value.absent(),
                Value<String> workoutExerciseId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> setIndex = const Value.absent(),
                Value<SetType> setType = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> durationS = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<String?> subExerciseId = const Value.absent(),
                Value<Side?> side = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion(
                id: id,
                updatedAt: updatedAt,
                workoutId: workoutId,
                workoutExerciseId: workoutExerciseId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                setType: setType,
                weightKg: weightKg,
                reps: reps,
                durationS: durationS,
                distanceM: distanceM,
                rpe: rpe,
                subExerciseId: subExerciseId,
                side: side,
                maxHr: maxHr,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String workoutId,
                required String workoutExerciseId,
                required String exerciseId,
                required int setIndex,
                Value<SetType> setType = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<int?> durationS = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<double?> rpe = const Value.absent(),
                Value<String?> subExerciseId = const Value.absent(),
                Value<Side?> side = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSetsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                workoutId: workoutId,
                workoutExerciseId: workoutExerciseId,
                exerciseId: exerciseId,
                setIndex: setIndex,
                setType: setType,
                weightKg: weightKg,
                reps: reps,
                durationS: durationS,
                distanceM: distanceM,
                rpe: rpe,
                subExerciseId: subExerciseId,
                side: side,
                maxHr: maxHr,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable<$WorkoutSetsTable, WorkoutSet>(table), $$WorkoutSetsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false, workoutExerciseId = false, exerciseId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workoutId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workoutId,
                        referencedTable: $$WorkoutSetsTableReferences._workoutIdTable(db),
                        referencedColumn: $$WorkoutSetsTableReferences._workoutIdTable(db).id,
                      ) as T;
                    }
                    if (workoutExerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workoutExerciseId,
                        referencedTable: $$WorkoutSetsTableReferences._workoutExerciseIdTable(db),
                        referencedColumn: $$WorkoutSetsTableReferences._workoutExerciseIdTable(db).id,
                      ) as T;
                    }
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$WorkoutSetsTableReferences._exerciseIdTable(db),
                        referencedColumn: $$WorkoutSetsTableReferences._exerciseIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSetsTable,
      WorkoutSet,
      $$WorkoutSetsTableFilterComposer,
      $$WorkoutSetsTableOrderingComposer,
      $$WorkoutSetsTableAnnotationComposer,
      $$WorkoutSetsTableCreateCompanionBuilder,
      $$WorkoutSetsTableUpdateCompanionBuilder,
      (WorkoutSet, $$WorkoutSetsTableReferences),
      WorkoutSet,
      PrefetchHooks Function({bool workoutId, bool workoutExerciseId, bool exerciseId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$SettingsTableOrderingComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableAnnotationComposer extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);
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
          createFilteringComposer: () => $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(db, table, e),
                ),
              )
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
typedef $$BodyMeasurementsTableCreateCompanionBuilder = BodyMeasurementsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required DateTime date,
  required String kind,
  required double value,
  Value<int> rowid,
});
typedef $$BodyMeasurementsTableUpdateCompanionBuilder = BodyMeasurementsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime> date,
  Value<String> kind,
  Value<double> value,
  Value<int> rowid,
});

class $$BodyMeasurementsTableFilterComposer extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$BodyMeasurementsTableOrderingComposer extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$BodyMeasurementsTableAnnotationComposer extends Composer<_$AppDatabase, $BodyMeasurementsTable> {
  $$BodyMeasurementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get date => $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get kind => $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<double> get value => $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$BodyMeasurementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyMeasurementsTable,
          BodyMeasurement,
          $$BodyMeasurementsTableFilterComposer,
          $$BodyMeasurementsTableOrderingComposer,
          $$BodyMeasurementsTableAnnotationComposer,
          $$BodyMeasurementsTableCreateCompanionBuilder,
          $$BodyMeasurementsTableUpdateCompanionBuilder,
          (BodyMeasurement, BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>),
          BodyMeasurement,
          PrefetchHooks Function()
        > {
  $$BodyMeasurementsTableTableManager(_$AppDatabase db, $BodyMeasurementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$BodyMeasurementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$BodyMeasurementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$BodyMeasurementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyMeasurementsCompanion(
                id: id,
                updatedAt: updatedAt,
                date: date,
                kind: kind,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required DateTime date,
                required String kind,
                required double value,
                Value<int> rowid = const Value.absent(),
              }) => BodyMeasurementsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                date: date,
                kind: kind,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BodyMeasurementsTable, BodyMeasurement>(table),
                  BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyMeasurementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyMeasurementsTable,
      BodyMeasurement,
      $$BodyMeasurementsTableFilterComposer,
      $$BodyMeasurementsTableOrderingComposer,
      $$BodyMeasurementsTableAnnotationComposer,
      $$BodyMeasurementsTableCreateCompanionBuilder,
      $$BodyMeasurementsTableUpdateCompanionBuilder,
      (BodyMeasurement, BaseReferences<_$AppDatabase, $BodyMeasurementsTable, BodyMeasurement>),
      BodyMeasurement,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required GoalType type,
  required double target,
  Value<double?> startValue,
  Value<String?> exerciseId,
  Value<String?> measurementKind,
  Value<DateTime?> deadline,
  Value<DateTime> createdAt,
  Value<DateTime?> achievedAt,
  Value<double?> distanceM,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<GoalType> type,
  Value<double> target,
  Value<double?> startValue,
  Value<String?> exerciseId,
  Value<String?> measurementKind,
  Value<DateTime?> deadline,
  Value<DateTime> createdAt,
  Value<DateTime?> achievedAt,
  Value<double?> distanceM,
  Value<int> rowid,
});

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GoalType, GoalType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<double> get target =>
      $composableBuilder(column: $table.target, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startValue =>
      $composableBuilder(column: $table.startValue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseId =>
      $composableBuilder(column: $table.exerciseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get measurementKind =>
      $composableBuilder(column: $table.measurementKind, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get achievedAt =>
      $composableBuilder(column: $table.achievedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => ColumnFilters(column));
}

class $$GoalsTableOrderingComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get target =>
      $composableBuilder(column: $table.target, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startValue =>
      $composableBuilder(column: $table.startValue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseId =>
      $composableBuilder(column: $table.exerciseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get measurementKind =>
      $composableBuilder(column: $table.measurementKind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get achievedAt =>
      $composableBuilder(column: $table.achievedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => ColumnOrderings(column));
}

class $$GoalsTableAnnotationComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GoalType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get target => $composableBuilder(column: $table.target, builder: (column) => column);

  GeneratedColumn<double> get startValue => $composableBuilder(column: $table.startValue, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(column: $table.exerciseId, builder: (column) => column);

  GeneratedColumn<String> get measurementKind =>
      $composableBuilder(column: $table.measurementKind, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline => $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get achievedAt =>
      $composableBuilder(column: $table.achievedAt, builder: (column) => column);

  GeneratedColumn<double> get distanceM => $composableBuilder(column: $table.distanceM, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<GoalType> type = const Value.absent(),
                Value<double> target = const Value.absent(),
                Value<double?> startValue = const Value.absent(),
                Value<String?> exerciseId = const Value.absent(),
                Value<String?> measurementKind = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> achievedAt = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                updatedAt: updatedAt,
                type: type,
                target: target,
                startValue: startValue,
                exerciseId: exerciseId,
                measurementKind: measurementKind,
                deadline: deadline,
                createdAt: createdAt,
                achievedAt: achievedAt,
                distanceM: distanceM,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required GoalType type,
                required double target,
                Value<double?> startValue = const Value.absent(),
                Value<String?> exerciseId = const Value.absent(),
                Value<String?> measurementKind = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> achievedAt = const Value.absent(),
                Value<double?> distanceM = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                type: type,
                target: target,
                startValue: startValue,
                exerciseId: exerciseId,
                measurementKind: measurementKind,
                deadline: deadline,
                createdAt: createdAt,
                achievedAt: achievedAt,
                distanceM: distanceM,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, Goal>(table),
                  BaseReferences<_$AppDatabase, $GoalsTable, Goal>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$AppDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$HrPresetsTableCreateCompanionBuilder = HrPresetsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String name,
  required int minBpm,
  required int maxBpm,
  Value<PresetUse> use,
  Value<int> rowid,
});
typedef $$HrPresetsTableUpdateCompanionBuilder = HrPresetsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<int> minBpm,
  Value<int> maxBpm,
  Value<PresetUse> use,
  Value<int> rowid,
});

class $$HrPresetsTableFilterComposer extends Composer<_$AppDatabase, $HrPresetsTable> {
  $$HrPresetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minBpm =>
      $composableBuilder(column: $table.minBpm, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxBpm =>
      $composableBuilder(column: $table.maxBpm, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<PresetUse, PresetUse, int> get use =>
      $composableBuilder(column: $table.use, builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$HrPresetsTableOrderingComposer extends Composer<_$AppDatabase, $HrPresetsTable> {
  $$HrPresetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minBpm =>
      $composableBuilder(column: $table.minBpm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxBpm =>
      $composableBuilder(column: $table.maxBpm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get use => $composableBuilder(column: $table.use, builder: (column) => ColumnOrderings(column));
}

class $$HrPresetsTableAnnotationComposer extends Composer<_$AppDatabase, $HrPresetsTable> {
  $$HrPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get minBpm => $composableBuilder(column: $table.minBpm, builder: (column) => column);

  GeneratedColumn<int> get maxBpm => $composableBuilder(column: $table.maxBpm, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PresetUse, int> get use =>
      $composableBuilder(column: $table.use, builder: (column) => column);
}

class $$HrPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HrPresetsTable,
          HrPreset,
          $$HrPresetsTableFilterComposer,
          $$HrPresetsTableOrderingComposer,
          $$HrPresetsTableAnnotationComposer,
          $$HrPresetsTableCreateCompanionBuilder,
          $$HrPresetsTableUpdateCompanionBuilder,
          (HrPreset, BaseReferences<_$AppDatabase, $HrPresetsTable, HrPreset>),
          HrPreset,
          PrefetchHooks Function()
        > {
  $$HrPresetsTableTableManager(_$AppDatabase db, $HrPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$HrPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$HrPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$HrPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> minBpm = const Value.absent(),
                Value<int> maxBpm = const Value.absent(),
                Value<PresetUse> use = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HrPresetsCompanion(
                id: id,
                updatedAt: updatedAt,
                name: name,
                minBpm: minBpm,
                maxBpm: maxBpm,
                use: use,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                required int minBpm,
                required int maxBpm,
                Value<PresetUse> use = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HrPresetsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                name: name,
                minBpm: minBpm,
                maxBpm: maxBpm,
                use: use,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HrPresetsTable, HrPreset>(table),
                  BaseReferences<_$AppDatabase, $HrPresetsTable, HrPreset>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HrPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HrPresetsTable,
      HrPreset,
      $$HrPresetsTableFilterComposer,
      $$HrPresetsTableOrderingComposer,
      $$HrPresetsTableAnnotationComposer,
      $$HrPresetsTableCreateCompanionBuilder,
      $$HrPresetsTableUpdateCompanionBuilder,
      (HrPreset, BaseReferences<_$AppDatabase, $HrPresetsTable, HrPreset>),
      HrPreset,
      PrefetchHooks Function()
    >;
typedef $$IntervalPresetsTableCreateCompanionBuilder = IntervalPresetsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String name,
  required String segmentsJson,
  Value<int> rounds,
  Value<int> position,
  Value<int> rowid,
});
typedef $$IntervalPresetsTableUpdateCompanionBuilder = IntervalPresetsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<String> segmentsJson,
  Value<int> rounds,
  Value<int> position,
  Value<int> rowid,
});

class $$IntervalPresetsTableFilterComposer extends Composer<_$AppDatabase, $IntervalPresetsTable> {
  $$IntervalPresetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get segmentsJson =>
      $composableBuilder(column: $table.segmentsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get rounds =>
      $composableBuilder(column: $table.rounds, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));
}

class $$IntervalPresetsTableOrderingComposer extends Composer<_$AppDatabase, $IntervalPresetsTable> {
  $$IntervalPresetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get segmentsJson =>
      $composableBuilder(column: $table.segmentsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get rounds =>
      $composableBuilder(column: $table.rounds, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$IntervalPresetsTableAnnotationComposer extends Composer<_$AppDatabase, $IntervalPresetsTable> {
  $$IntervalPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get segmentsJson =>
      $composableBuilder(column: $table.segmentsJson, builder: (column) => column);

  GeneratedColumn<int> get rounds => $composableBuilder(column: $table.rounds, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$IntervalPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntervalPresetsTable,
          IntervalPreset,
          $$IntervalPresetsTableFilterComposer,
          $$IntervalPresetsTableOrderingComposer,
          $$IntervalPresetsTableAnnotationComposer,
          $$IntervalPresetsTableCreateCompanionBuilder,
          $$IntervalPresetsTableUpdateCompanionBuilder,
          (IntervalPreset, BaseReferences<_$AppDatabase, $IntervalPresetsTable, IntervalPreset>),
          IntervalPreset,
          PrefetchHooks Function()
        > {
  $$IntervalPresetsTableTableManager(_$AppDatabase db, $IntervalPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$IntervalPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$IntervalPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$IntervalPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> segmentsJson = const Value.absent(),
                Value<int> rounds = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntervalPresetsCompanion(
                id: id,
                updatedAt: updatedAt,
                name: name,
                segmentsJson: segmentsJson,
                rounds: rounds,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                required String segmentsJson,
                Value<int> rounds = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IntervalPresetsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                name: name,
                segmentsJson: segmentsJson,
                rounds: rounds,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IntervalPresetsTable, IntervalPreset>(table),
                  BaseReferences<_$AppDatabase, $IntervalPresetsTable, IntervalPreset>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IntervalPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntervalPresetsTable,
      IntervalPreset,
      $$IntervalPresetsTableFilterComposer,
      $$IntervalPresetsTableOrderingComposer,
      $$IntervalPresetsTableAnnotationComposer,
      $$IntervalPresetsTableCreateCompanionBuilder,
      $$IntervalPresetsTableUpdateCompanionBuilder,
      (IntervalPreset, BaseReferences<_$AppDatabase, $IntervalPresetsTable, IntervalPreset>),
      IntervalPreset,
      PrefetchHooks Function()
    >;
typedef $$RunsTableCreateCompanionBuilder = RunsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> name,
  required DateTime startedAt,
  Value<DateTime?> endedAt,
  Value<DateTime?> pausedAt,
  Value<int> pausedS,
  Value<int> durationS,
  Value<double> distanceM,
  Value<String?> hrPresetId,
  Value<int?> avgHr,
  Value<int?> maxHr,
  Value<String> notes,
  Value<String?> bestsJson,
  Value<RunKind> kind,
  Value<int?> effort,
  Value<String?> weather,
  Value<String?> shoeId,
  Value<int?> steps,
  Value<int?> avgCadence,
  Value<double?> elevGainM,
  Value<double?> elevLossM,
  Value<String?> planId,
  Value<String?> lapsJson,
  Value<int> rowid,
});
typedef $$RunsTableUpdateCompanionBuilder = RunsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<DateTime> startedAt,
  Value<DateTime?> endedAt,
  Value<DateTime?> pausedAt,
  Value<int> pausedS,
  Value<int> durationS,
  Value<double> distanceM,
  Value<String?> hrPresetId,
  Value<int?> avgHr,
  Value<int?> maxHr,
  Value<String> notes,
  Value<String?> bestsJson,
  Value<RunKind> kind,
  Value<int?> effort,
  Value<String?> weather,
  Value<String?> shoeId,
  Value<int?> steps,
  Value<int?> avgCadence,
  Value<double?> elevGainM,
  Value<double?> elevLossM,
  Value<String?> planId,
  Value<String?> lapsJson,
  Value<int> rowid,
});

final class $$RunsTableReferences extends BaseReferences<_$AppDatabase, $RunsTable, Run> {
  $$RunsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RunPointsTable, List<RunPoint>> _runPointsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.runPoints, aliasName: 'runs__id__run_points__run_id');

  $$RunPointsTableProcessedTableManager get runPointsRefs {
    final manager = $$RunPointsTableTableManager(
      $_db,
      $_db.runPoints,
    ).filter((f) => f.runId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_runPointsRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RunsTableFilterComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pausedS =>
      $composableBuilder(column: $table.pausedS, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hrPresetId =>
      $composableBuilder(column: $table.hrPresetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avgHr => $composableBuilder(column: $table.avgHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get maxHr => $composableBuilder(column: $table.maxHr, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bestsJson =>
      $composableBuilder(column: $table.bestsJson, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<RunKind, RunKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get effort =>
      $composableBuilder(column: $table.effort, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weather =>
      $composableBuilder(column: $table.weather, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get shoeId =>
      $composableBuilder(column: $table.shoeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get steps => $composableBuilder(column: $table.steps, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get avgCadence =>
      $composableBuilder(column: $table.avgCadence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elevGainM =>
      $composableBuilder(column: $table.elevGainM, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elevLossM =>
      $composableBuilder(column: $table.elevLossM, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lapsJson =>
      $composableBuilder(column: $table.lapsJson, builder: (column) => ColumnFilters(column));

  Expression<bool> runPointsRefs(Expression<bool> Function($$RunPointsTableFilterComposer f) f) {
    final $$RunPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runPoints,
      getReferencedColumn: (t) => t.runId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RunPointsTableFilterComposer(
            $db: $db,
            $table: $db.runPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RunsTableOrderingComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pausedS =>
      $composableBuilder(column: $table.pausedS, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hrPresetId =>
      $composableBuilder(column: $table.hrPresetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avgHr =>
      $composableBuilder(column: $table.avgHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maxHr =>
      $composableBuilder(column: $table.maxHr, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bestsJson =>
      $composableBuilder(column: $table.bestsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get effort =>
      $composableBuilder(column: $table.effort, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weather =>
      $composableBuilder(column: $table.weather, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get shoeId =>
      $composableBuilder(column: $table.shoeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get avgCadence =>
      $composableBuilder(column: $table.avgCadence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elevGainM =>
      $composableBuilder(column: $table.elevGainM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elevLossM =>
      $composableBuilder(column: $table.elevLossM, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lapsJson =>
      $composableBuilder(column: $table.lapsJson, builder: (column) => ColumnOrderings(column));
}

class $$RunsTableAnnotationComposer extends Composer<_$AppDatabase, $RunsTable> {
  $$RunsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt => $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt => $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get pausedAt => $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  GeneratedColumn<int> get pausedS => $composableBuilder(column: $table.pausedS, builder: (column) => column);

  GeneratedColumn<int> get durationS => $composableBuilder(column: $table.durationS, builder: (column) => column);

  GeneratedColumn<double> get distanceM => $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<String> get hrPresetId => $composableBuilder(column: $table.hrPresetId, builder: (column) => column);

  GeneratedColumn<int> get avgHr => $composableBuilder(column: $table.avgHr, builder: (column) => column);

  GeneratedColumn<int> get maxHr => $composableBuilder(column: $table.maxHr, builder: (column) => column);

  GeneratedColumn<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get bestsJson => $composableBuilder(column: $table.bestsJson, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RunKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get effort => $composableBuilder(column: $table.effort, builder: (column) => column);

  GeneratedColumn<String> get weather => $composableBuilder(column: $table.weather, builder: (column) => column);

  GeneratedColumn<String> get shoeId => $composableBuilder(column: $table.shoeId, builder: (column) => column);

  GeneratedColumn<int> get steps => $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<int> get avgCadence => $composableBuilder(column: $table.avgCadence, builder: (column) => column);

  GeneratedColumn<double> get elevGainM => $composableBuilder(column: $table.elevGainM, builder: (column) => column);

  GeneratedColumn<double> get elevLossM => $composableBuilder(column: $table.elevLossM, builder: (column) => column);

  GeneratedColumn<String> get planId => $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get lapsJson => $composableBuilder(column: $table.lapsJson, builder: (column) => column);

  Expression<T> runPointsRefs<T extends Object>(Expression<T> Function($$RunPointsTableAnnotationComposer a) f) {
    final $$RunPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.runPoints,
      getReferencedColumn: (t) => t.runId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RunPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.runPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RunsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunsTable,
          Run,
          $$RunsTableFilterComposer,
          $$RunsTableOrderingComposer,
          $$RunsTableAnnotationComposer,
          $$RunsTableCreateCompanionBuilder,
          $$RunsTableUpdateCompanionBuilder,
          (Run, $$RunsTableReferences),
          Run,
          PrefetchHooks Function({bool runPointsRefs})
        > {
  $$RunsTableTableManager(_$AppDatabase db, $RunsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RunsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RunsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RunsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<int> pausedS = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<String?> hrPresetId = const Value.absent(),
                Value<int?> avgHr = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> bestsJson = const Value.absent(),
                Value<RunKind> kind = const Value.absent(),
                Value<int?> effort = const Value.absent(),
                Value<String?> weather = const Value.absent(),
                Value<String?> shoeId = const Value.absent(),
                Value<int?> steps = const Value.absent(),
                Value<int?> avgCadence = const Value.absent(),
                Value<double?> elevGainM = const Value.absent(),
                Value<double?> elevLossM = const Value.absent(),
                Value<String?> planId = const Value.absent(),
                Value<String?> lapsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion(
                id: id,
                updatedAt: updatedAt,
                name: name,
                startedAt: startedAt,
                endedAt: endedAt,
                pausedAt: pausedAt,
                pausedS: pausedS,
                durationS: durationS,
                distanceM: distanceM,
                hrPresetId: hrPresetId,
                avgHr: avgHr,
                maxHr: maxHr,
                notes: notes,
                bestsJson: bestsJson,
                kind: kind,
                effort: effort,
                weather: weather,
                shoeId: shoeId,
                steps: steps,
                avgCadence: avgCadence,
                elevGainM: elevGainM,
                elevLossM: elevLossM,
                planId: planId,
                lapsJson: lapsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<int> pausedS = const Value.absent(),
                Value<int> durationS = const Value.absent(),
                Value<double> distanceM = const Value.absent(),
                Value<String?> hrPresetId = const Value.absent(),
                Value<int?> avgHr = const Value.absent(),
                Value<int?> maxHr = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> bestsJson = const Value.absent(),
                Value<RunKind> kind = const Value.absent(),
                Value<int?> effort = const Value.absent(),
                Value<String?> weather = const Value.absent(),
                Value<String?> shoeId = const Value.absent(),
                Value<int?> steps = const Value.absent(),
                Value<int?> avgCadence = const Value.absent(),
                Value<double?> elevGainM = const Value.absent(),
                Value<double?> elevLossM = const Value.absent(),
                Value<String?> planId = const Value.absent(),
                Value<String?> lapsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                name: name,
                startedAt: startedAt,
                endedAt: endedAt,
                pausedAt: pausedAt,
                pausedS: pausedS,
                durationS: durationS,
                distanceM: distanceM,
                hrPresetId: hrPresetId,
                avgHr: avgHr,
                maxHr: maxHr,
                notes: notes,
                bestsJson: bestsJson,
                kind: kind,
                effort: effort,
                weather: weather,
                shoeId: shoeId,
                steps: steps,
                avgCadence: avgCadence,
                elevGainM: elevGainM,
                elevLossM: elevLossM,
                planId: planId,
                lapsJson: lapsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable<$RunsTable, Run>(table), $$RunsTableReferences(db, table, e))).toList(),
          prefetchHooksCallback: ({runPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (runPointsRefs) db.runPoints],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (runPointsRefs)
                    await $_getPrefetchedDataByColumns<Run, $RunsTable, RunPoint, $RunPointsTable>(
                      currentTable: table,
                      referencedTable: $$RunsTableReferences._runPointsRefsTable(db),
                      managerFromTypedResult: (p0) => $$RunsTableReferences(db, table, p0).runPointsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'run_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RunsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunsTable,
      Run,
      $$RunsTableFilterComposer,
      $$RunsTableOrderingComposer,
      $$RunsTableAnnotationComposer,
      $$RunsTableCreateCompanionBuilder,
      $$RunsTableUpdateCompanionBuilder,
      (Run, $$RunsTableReferences),
      Run,
      PrefetchHooks Function({bool runPointsRefs})
    >;
typedef $$RunPointsTableCreateCompanionBuilder = RunPointsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String runId,
  required DateTime time,
  required double lat,
  required double lon,
  Value<double?> accuracy,
  Value<double?> altitude,
  Value<int> segment,
  Value<int?> hr,
  Value<int> rowid,
});
typedef $$RunPointsTableUpdateCompanionBuilder = RunPointsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> runId,
  Value<DateTime> time,
  Value<double> lat,
  Value<double> lon,
  Value<double?> accuracy,
  Value<double?> altitude,
  Value<int> segment,
  Value<int?> hr,
  Value<int> rowid,
});

final class $$RunPointsTableReferences extends BaseReferences<_$AppDatabase, $RunPointsTable, RunPoint> {
  $$RunPointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RunsTable _runIdTable(_$AppDatabase db) => db.runs.createAlias('run_points__run_id__runs__id');

  $$RunsTableProcessedTableManager get runId {
    final $_column = $_itemColumn<String>('run_id')!;

    final manager = $$RunsTableTableManager($_db, $_db.runs).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_runIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$RunPointsTableFilterComposer extends Composer<_$AppDatabase, $RunPointsTable> {
  $$RunPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get time =>
      $composableBuilder(column: $table.time, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get segment =>
      $composableBuilder(column: $table.segment, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hr => $composableBuilder(column: $table.hr, builder: (column) => ColumnFilters(column));

  $$RunsTableFilterComposer get runId {
    final $$RunsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RunsTableFilterComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunPointsTableOrderingComposer extends Composer<_$AppDatabase, $RunPointsTable> {
  $$RunPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get time =>
      $composableBuilder(column: $table.time, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get segment =>
      $composableBuilder(column: $table.segment, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hr => $composableBuilder(column: $table.hr, builder: (column) => ColumnOrderings(column));

  $$RunsTableOrderingComposer get runId {
    final $$RunsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RunsTableOrderingComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunPointsTableAnnotationComposer extends Composer<_$AppDatabase, $RunPointsTable> {
  $$RunPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get time => $composableBuilder(column: $table.time, builder: (column) => column);

  GeneratedColumn<double> get lat => $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon => $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get accuracy => $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<double> get altitude => $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<int> get segment => $composableBuilder(column: $table.segment, builder: (column) => column);

  GeneratedColumn<int> get hr => $composableBuilder(column: $table.hr, builder: (column) => column);

  $$RunsTableAnnotationComposer get runId {
    final $$RunsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.runId,
      referencedTable: $db.runs,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RunsTableAnnotationComposer(
            $db: $db,
            $table: $db.runs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RunPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunPointsTable,
          RunPoint,
          $$RunPointsTableFilterComposer,
          $$RunPointsTableOrderingComposer,
          $$RunPointsTableAnnotationComposer,
          $$RunPointsTableCreateCompanionBuilder,
          $$RunPointsTableUpdateCompanionBuilder,
          (RunPoint, $$RunPointsTableReferences),
          RunPoint,
          PrefetchHooks Function({bool runId})
        > {
  $$RunPointsTableTableManager(_$AppDatabase db, $RunPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RunPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RunPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RunPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> runId = const Value.absent(),
                Value<DateTime> time = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<int> segment = const Value.absent(),
                Value<int?> hr = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunPointsCompanion(
                id: id,
                updatedAt: updatedAt,
                runId: runId,
                time: time,
                lat: lat,
                lon: lon,
                accuracy: accuracy,
                altitude: altitude,
                segment: segment,
                hr: hr,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String runId,
                required DateTime time,
                required double lat,
                required double lon,
                Value<double?> accuracy = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<int> segment = const Value.absent(),
                Value<int?> hr = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunPointsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                runId: runId,
                time: time,
                lat: lat,
                lon: lon,
                accuracy: accuracy,
                altitude: altitude,
                segment: segment,
                hr: hr,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$RunPointsTable, RunPoint>(table), $$RunPointsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({runId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (runId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.runId,
                        referencedTable: $$RunPointsTableReferences._runIdTable(db),
                        referencedColumn: $$RunPointsTableReferences._runIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RunPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunPointsTable,
      RunPoint,
      $$RunPointsTableFilterComposer,
      $$RunPointsTableOrderingComposer,
      $$RunPointsTableAnnotationComposer,
      $$RunPointsTableCreateCompanionBuilder,
      $$RunPointsTableUpdateCompanionBuilder,
      (RunPoint, $$RunPointsTableReferences),
      RunPoint,
      PrefetchHooks Function({bool runId})
    >;
typedef $$ShoesTableCreateCompanionBuilder = ShoesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String name,
  Value<double> startKm,
  Value<double> limitKm,
  Value<bool> retired,
  Value<bool> isDefault,
  Value<int> rowid,
});
typedef $$ShoesTableUpdateCompanionBuilder = ShoesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<double> startKm,
  Value<double> limitKm,
  Value<bool> retired,
  Value<bool> isDefault,
  Value<int> rowid,
});

class $$ShoesTableFilterComposer extends Composer<_$AppDatabase, $ShoesTable> {
  $$ShoesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get startKm =>
      $composableBuilder(column: $table.startKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get limitKm =>
      $composableBuilder(column: $table.limitKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get retired =>
      $composableBuilder(column: $table.retired, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => ColumnFilters(column));
}

class $$ShoesTableOrderingComposer extends Composer<_$AppDatabase, $ShoesTable> {
  $$ShoesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get startKm =>
      $composableBuilder(column: $table.startKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get limitKm =>
      $composableBuilder(column: $table.limitKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get retired =>
      $composableBuilder(column: $table.retired, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => ColumnOrderings(column));
}

class $$ShoesTableAnnotationComposer extends Composer<_$AppDatabase, $ShoesTable> {
  $$ShoesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get startKm => $composableBuilder(column: $table.startKm, builder: (column) => column);

  GeneratedColumn<double> get limitKm => $composableBuilder(column: $table.limitKm, builder: (column) => column);

  GeneratedColumn<bool> get retired => $composableBuilder(column: $table.retired, builder: (column) => column);

  GeneratedColumn<bool> get isDefault => $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$ShoesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoesTable,
          Shoe,
          $$ShoesTableFilterComposer,
          $$ShoesTableOrderingComposer,
          $$ShoesTableAnnotationComposer,
          $$ShoesTableCreateCompanionBuilder,
          $$ShoesTableUpdateCompanionBuilder,
          (Shoe, BaseReferences<_$AppDatabase, $ShoesTable, Shoe>),
          Shoe,
          PrefetchHooks Function()
        > {
  $$ShoesTableTableManager(_$AppDatabase db, $ShoesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$ShoesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$ShoesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$ShoesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> startKm = const Value.absent(),
                Value<double> limitKm = const Value.absent(),
                Value<bool> retired = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoesCompanion(
                id: id,
                updatedAt: updatedAt,
                name: name,
                startKm: startKm,
                limitKm: limitKm,
                retired: retired,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                Value<double> startKm = const Value.absent(),
                Value<double> limitKm = const Value.absent(),
                Value<bool> retired = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                name: name,
                startKm: startKm,
                limitKm: limitKm,
                retired: retired,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShoesTable, Shoe>(table),
                  BaseReferences<_$AppDatabase, $ShoesTable, Shoe>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ShoesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoesTable,
      Shoe,
      $$ShoesTableFilterComposer,
      $$ShoesTableOrderingComposer,
      $$ShoesTableAnnotationComposer,
      $$ShoesTableCreateCompanionBuilder,
      $$ShoesTableUpdateCompanionBuilder,
      (Shoe, BaseReferences<_$AppDatabase, $ShoesTable, Shoe>),
      Shoe,
      PrefetchHooks Function()
    >;
typedef $$RunPlansTableCreateCompanionBuilder = RunPlansCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  required String name,
  required String specJson,
  Value<int> position,
  Value<int> rowid,
});
typedef $$RunPlansTableUpdateCompanionBuilder = RunPlansCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<String> specJson,
  Value<int> position,
  Value<int> rowid,
});

class $$RunPlansTableFilterComposer extends Composer<_$AppDatabase, $RunPlansTable> {
  $$RunPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get specJson =>
      $composableBuilder(column: $table.specJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));
}

class $$RunPlansTableOrderingComposer extends Composer<_$AppDatabase, $RunPlansTable> {
  $$RunPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get specJson =>
      $composableBuilder(column: $table.specJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$RunPlansTableAnnotationComposer extends Composer<_$AppDatabase, $RunPlansTable> {
  $$RunPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get specJson => $composableBuilder(column: $table.specJson, builder: (column) => column);

  GeneratedColumn<int> get position => $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$RunPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RunPlansTable,
          RunPlan,
          $$RunPlansTableFilterComposer,
          $$RunPlansTableOrderingComposer,
          $$RunPlansTableAnnotationComposer,
          $$RunPlansTableCreateCompanionBuilder,
          $$RunPlansTableUpdateCompanionBuilder,
          (RunPlan, BaseReferences<_$AppDatabase, $RunPlansTable, RunPlan>),
          RunPlan,
          PrefetchHooks Function()
        > {
  $$RunPlansTableTableManager(_$AppDatabase db, $RunPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RunPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RunPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RunPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> specJson = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunPlansCompanion(
                id: id,
                updatedAt: updatedAt,
                name: name,
                specJson: specJson,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                required String name,
                required String specJson,
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RunPlansCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                name: name,
                specJson: specJson,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RunPlansTable, RunPlan>(table),
                  BaseReferences<_$AppDatabase, $RunPlansTable, RunPlan>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RunPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RunPlansTable,
      RunPlan,
      $$RunPlansTableFilterComposer,
      $$RunPlansTableOrderingComposer,
      $$RunPlansTableAnnotationComposer,
      $$RunPlansTableCreateCompanionBuilder,
      $$RunPlansTableUpdateCompanionBuilder,
      (RunPlan, BaseReferences<_$AppDatabase, $RunPlansTable, RunPlan>),
      RunPlan,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises => $$ExercisesTableTableManager(_db, _db.exercises);
  $$TemplatesTableTableManager get templates => $$TemplatesTableTableManager(_db, _db.templates);
  $$TemplateExercisesTableTableManager get templateExercises =>
      $$TemplateExercisesTableTableManager(_db, _db.templateExercises);
  $$WorkoutsTableTableManager get workouts => $$WorkoutsTableTableManager(_db, _db.workouts);
  $$WorkoutExercisesTableTableManager get workoutExercises =>
      $$WorkoutExercisesTableTableManager(_db, _db.workoutExercises);
  $$WorkoutSetsTableTableManager get workoutSets => $$WorkoutSetsTableTableManager(_db, _db.workoutSets);
  $$SettingsTableTableManager get settings => $$SettingsTableTableManager(_db, _db.settings);
  $$BodyMeasurementsTableTableManager get bodyMeasurements =>
      $$BodyMeasurementsTableTableManager(_db, _db.bodyMeasurements);
  $$GoalsTableTableManager get goals => $$GoalsTableTableManager(_db, _db.goals);
  $$HrPresetsTableTableManager get hrPresets => $$HrPresetsTableTableManager(_db, _db.hrPresets);
  $$IntervalPresetsTableTableManager get intervalPresets =>
      $$IntervalPresetsTableTableManager(_db, _db.intervalPresets);
  $$RunsTableTableManager get runs => $$RunsTableTableManager(_db, _db.runs);
  $$RunPointsTableTableManager get runPoints => $$RunPointsTableTableManager(_db, _db.runPoints);
  $$ShoesTableTableManager get shoes => $$ShoesTableTableManager(_db, _db.shoes);
  $$RunPlansTableTableManager get runPlans => $$RunPlansTableTableManager(_db, _db.runPlans);
}
