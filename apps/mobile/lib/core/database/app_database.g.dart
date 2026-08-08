// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProfileCachesTable extends ProfileCaches
    with TableInfo<$ProfileCachesTable, ProfileCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dateOfBirthMeta =
      const VerificationMeta('dateOfBirth');
  @override
  late final GeneratedColumn<String> dateOfBirth = GeneratedColumn<String>(
      'date_of_birth', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timeOfBirthMeta =
      const VerificationMeta('timeOfBirth');
  @override
  late final GeneratedColumn<String> timeOfBirth = GeneratedColumn<String>(
      'time_of_birth', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _placeNameMeta =
      const VerificationMeta('placeName');
  @override
  late final GeneratedColumn<String> placeName = GeneratedColumn<String>(
      'place_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _timezoneMeta =
      const VerificationMeta('timezone');
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
      'timezone', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isPrimaryMeta =
      const VerificationMeta('isPrimary');
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
      'is_primary', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_primary" IN (0, 1))'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _syncedAtMeta =
      const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
      'synced_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isDirtyMeta =
      const VerificationMeta('isDirty');
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
      'is_dirty', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_dirty" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        dateOfBirth,
        timeOfBirth,
        placeName,
        latitude,
        longitude,
        timezone,
        isPrimary,
        createdAt,
        updatedAt,
        syncedAt,
        isDirty
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile_caches';
  @override
  VerificationContext validateIntegrity(Insertable<ProfileCache> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date_of_birth')) {
      context.handle(
          _dateOfBirthMeta,
          dateOfBirth.isAcceptableOrUnknown(
              data['date_of_birth']!, _dateOfBirthMeta));
    } else if (isInserting) {
      context.missing(_dateOfBirthMeta);
    }
    if (data.containsKey('time_of_birth')) {
      context.handle(
          _timeOfBirthMeta,
          timeOfBirth.isAcceptableOrUnknown(
              data['time_of_birth']!, _timeOfBirthMeta));
    } else if (isInserting) {
      context.missing(_timeOfBirthMeta);
    }
    if (data.containsKey('place_name')) {
      context.handle(_placeNameMeta,
          placeName.isAcceptableOrUnknown(data['place_name']!, _placeNameMeta));
    } else if (isInserting) {
      context.missing(_placeNameMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(_timezoneMeta,
          timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta));
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('is_primary')) {
      context.handle(_isPrimaryMeta,
          isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta));
    } else if (isInserting) {
      context.missing(_isPrimaryMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(_syncedAtMeta,
          syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta));
    }
    if (data.containsKey('is_dirty')) {
      context.handle(_isDirtyMeta,
          isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta));
    } else if (isInserting) {
      context.missing(_isDirtyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileCache(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      dateOfBirth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date_of_birth'])!,
      timeOfBirth: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}time_of_birth'])!,
      placeName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}place_name'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      timezone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}timezone'])!,
      isPrimary: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_primary'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      syncedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}synced_at']),
      isDirty: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_dirty'])!,
    );
  }

  @override
  $ProfileCachesTable createAlias(String alias) {
    return $ProfileCachesTable(attachedDatabase, alias);
  }
}

class ProfileCache extends DataClass implements Insertable<ProfileCache> {
  final String id;
  final String name;
  final String dateOfBirth;
  final String timeOfBirth;
  final String placeName;
  final double latitude;
  final double longitude;
  final String timezone;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? syncedAt;
  final bool isDirty;
  const ProfileCache(
      {required this.id,
      required this.name,
      required this.dateOfBirth,
      required this.timeOfBirth,
      required this.placeName,
      required this.latitude,
      required this.longitude,
      required this.timezone,
      required this.isPrimary,
      required this.createdAt,
      required this.updatedAt,
      this.syncedAt,
      required this.isDirty});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['date_of_birth'] = Variable<String>(dateOfBirth);
    map['time_of_birth'] = Variable<String>(timeOfBirth);
    map['place_name'] = Variable<String>(placeName);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['timezone'] = Variable<String>(timezone);
    map['is_primary'] = Variable<bool>(isPrimary);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    return map;
  }

  ProfileCachesCompanion toCompanion(bool nullToAbsent) {
    return ProfileCachesCompanion(
      id: Value(id),
      name: Value(name),
      dateOfBirth: Value(dateOfBirth),
      timeOfBirth: Value(timeOfBirth),
      placeName: Value(placeName),
      latitude: Value(latitude),
      longitude: Value(longitude),
      timezone: Value(timezone),
      isPrimary: Value(isPrimary),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      isDirty: Value(isDirty),
    );
  }

  factory ProfileCache.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileCache(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      dateOfBirth: serializer.fromJson<String>(json['dateOfBirth']),
      timeOfBirth: serializer.fromJson<String>(json['timeOfBirth']),
      placeName: serializer.fromJson<String>(json['placeName']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      timezone: serializer.fromJson<String>(json['timezone']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'dateOfBirth': serializer.toJson<String>(dateOfBirth),
      'timeOfBirth': serializer.toJson<String>(timeOfBirth),
      'placeName': serializer.toJson<String>(placeName),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'timezone': serializer.toJson<String>(timezone),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'isDirty': serializer.toJson<bool>(isDirty),
    };
  }

  ProfileCache copyWith(
          {String? id,
          String? name,
          String? dateOfBirth,
          String? timeOfBirth,
          String? placeName,
          double? latitude,
          double? longitude,
          String? timezone,
          bool? isPrimary,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> syncedAt = const Value.absent(),
          bool? isDirty}) =>
      ProfileCache(
        id: id ?? this.id,
        name: name ?? this.name,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        timeOfBirth: timeOfBirth ?? this.timeOfBirth,
        placeName: placeName ?? this.placeName,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        timezone: timezone ?? this.timezone,
        isPrimary: isPrimary ?? this.isPrimary,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
        isDirty: isDirty ?? this.isDirty,
      );
  ProfileCache copyWithCompanion(ProfileCachesCompanion data) {
    return ProfileCache(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      dateOfBirth:
          data.dateOfBirth.present ? data.dateOfBirth.value : this.dateOfBirth,
      timeOfBirth:
          data.timeOfBirth.present ? data.timeOfBirth.value : this.timeOfBirth,
      placeName: data.placeName.present ? data.placeName.value : this.placeName,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileCache(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('timeOfBirth: $timeOfBirth, ')
          ..write('placeName: $placeName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('timezone: $timezone, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isDirty: $isDirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      dateOfBirth,
      timeOfBirth,
      placeName,
      latitude,
      longitude,
      timezone,
      isPrimary,
      createdAt,
      updatedAt,
      syncedAt,
      isDirty);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileCache &&
          other.id == this.id &&
          other.name == this.name &&
          other.dateOfBirth == this.dateOfBirth &&
          other.timeOfBirth == this.timeOfBirth &&
          other.placeName == this.placeName &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.timezone == this.timezone &&
          other.isPrimary == this.isPrimary &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncedAt == this.syncedAt &&
          other.isDirty == this.isDirty);
}

class ProfileCachesCompanion extends UpdateCompanion<ProfileCache> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> dateOfBirth;
  final Value<String> timeOfBirth;
  final Value<String> placeName;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> timezone;
  final Value<bool> isPrimary;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> syncedAt;
  final Value<bool> isDirty;
  final Value<int> rowid;
  const ProfileCachesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.dateOfBirth = const Value.absent(),
    this.timeOfBirth = const Value.absent(),
    this.placeName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.timezone = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileCachesCompanion.insert({
    required String id,
    required String name,
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeName,
    required double latitude,
    required double longitude,
    required String timezone,
    required bool isPrimary,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.syncedAt = const Value.absent(),
    required bool isDirty,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        dateOfBirth = Value(dateOfBirth),
        timeOfBirth = Value(timeOfBirth),
        placeName = Value(placeName),
        latitude = Value(latitude),
        longitude = Value(longitude),
        timezone = Value(timezone),
        isPrimary = Value(isPrimary),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt),
        isDirty = Value(isDirty);
  static Insertable<ProfileCache> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? dateOfBirth,
    Expression<String>? timeOfBirth,
    Expression<String>? placeName,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? timezone,
    Expression<bool>? isPrimary,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? syncedAt,
    Expression<bool>? isDirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (timeOfBirth != null) 'time_of_birth': timeOfBirth,
      if (placeName != null) 'place_name': placeName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (timezone != null) 'timezone': timezone,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileCachesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? dateOfBirth,
      Value<String>? timeOfBirth,
      Value<String>? placeName,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<String>? timezone,
      Value<bool>? isPrimary,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? syncedAt,
      Value<bool>? isDirty,
      Value<int>? rowid}) {
    return ProfileCachesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      timeOfBirth: timeOfBirth ?? this.timeOfBirth,
      placeName: placeName ?? this.placeName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      isDirty: isDirty ?? this.isDirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dateOfBirth.present) {
      map['date_of_birth'] = Variable<String>(dateOfBirth.value);
    }
    if (timeOfBirth.present) {
      map['time_of_birth'] = Variable<String>(timeOfBirth.value);
    }
    if (placeName.present) {
      map['place_name'] = Variable<String>(placeName.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileCachesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('dateOfBirth: $dateOfBirth, ')
          ..write('timeOfBirth: $timeOfBirth, ')
          ..write('placeName: $placeName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('timezone: $timezone, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChartCachesTable extends ChartCaches
    with TableInfo<$ChartCachesTable, ChartCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChartCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chartIdMeta =
      const VerificationMeta('chartId');
  @override
  late final GeneratedColumn<String> chartId = GeneratedColumn<String>(
      'chart_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profileIdMeta =
      const VerificationMeta('profileId');
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
      'profile_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ayanamsaMeta =
      const VerificationMeta('ayanamsa');
  @override
  late final GeneratedColumn<String> ayanamsa = GeneratedColumn<String>(
      'ayanamsa', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _houseSystemMeta =
      const VerificationMeta('houseSystem');
  @override
  late final GeneratedColumn<String> houseSystem = GeneratedColumn<String>(
      'house_system', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chartFactsJsonMeta =
      const VerificationMeta('chartFactsJson');
  @override
  late final GeneratedColumn<String> chartFactsJson = GeneratedColumn<String>(
      'chart_facts_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _calculatedAtMeta =
      const VerificationMeta('calculatedAt');
  @override
  late final GeneratedColumn<DateTime> calculatedAt = GeneratedColumn<DateTime>(
      'calculated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [chartId, profileId, ayanamsa, houseSystem, chartFactsJson, calculatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chart_caches';
  @override
  VerificationContext validateIntegrity(Insertable<ChartCache> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chart_id')) {
      context.handle(_chartIdMeta,
          chartId.isAcceptableOrUnknown(data['chart_id']!, _chartIdMeta));
    } else if (isInserting) {
      context.missing(_chartIdMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(_profileIdMeta,
          profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta));
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('ayanamsa')) {
      context.handle(_ayanamsaMeta,
          ayanamsa.isAcceptableOrUnknown(data['ayanamsa']!, _ayanamsaMeta));
    } else if (isInserting) {
      context.missing(_ayanamsaMeta);
    }
    if (data.containsKey('house_system')) {
      context.handle(
          _houseSystemMeta,
          houseSystem.isAcceptableOrUnknown(
              data['house_system']!, _houseSystemMeta));
    } else if (isInserting) {
      context.missing(_houseSystemMeta);
    }
    if (data.containsKey('chart_facts_json')) {
      context.handle(
          _chartFactsJsonMeta,
          chartFactsJson.isAcceptableOrUnknown(
              data['chart_facts_json']!, _chartFactsJsonMeta));
    } else if (isInserting) {
      context.missing(_chartFactsJsonMeta);
    }
    if (data.containsKey('calculated_at')) {
      context.handle(
          _calculatedAtMeta,
          calculatedAt.isAcceptableOrUnknown(
              data['calculated_at']!, _calculatedAtMeta));
    } else if (isInserting) {
      context.missing(_calculatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chartId};
  @override
  ChartCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChartCache(
      chartId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chart_id'])!,
      profileId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_id'])!,
      ayanamsa: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ayanamsa'])!,
      houseSystem: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}house_system'])!,
      chartFactsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}chart_facts_json'])!,
      calculatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}calculated_at'])!,
    );
  }

  @override
  $ChartCachesTable createAlias(String alias) {
    return $ChartCachesTable(attachedDatabase, alias);
  }
}

class ChartCache extends DataClass implements Insertable<ChartCache> {
  final String chartId;
  final String profileId;
  final String ayanamsa;
  final String houseSystem;
  final String chartFactsJson;
  final DateTime calculatedAt;
  const ChartCache(
      {required this.chartId,
      required this.profileId,
      required this.ayanamsa,
      required this.houseSystem,
      required this.chartFactsJson,
      required this.calculatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chart_id'] = Variable<String>(chartId);
    map['profile_id'] = Variable<String>(profileId);
    map['ayanamsa'] = Variable<String>(ayanamsa);
    map['house_system'] = Variable<String>(houseSystem);
    map['chart_facts_json'] = Variable<String>(chartFactsJson);
    map['calculated_at'] = Variable<DateTime>(calculatedAt);
    return map;
  }

  ChartCachesCompanion toCompanion(bool nullToAbsent) {
    return ChartCachesCompanion(
      chartId: Value(chartId),
      profileId: Value(profileId),
      ayanamsa: Value(ayanamsa),
      houseSystem: Value(houseSystem),
      chartFactsJson: Value(chartFactsJson),
      calculatedAt: Value(calculatedAt),
    );
  }

  factory ChartCache.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChartCache(
      chartId: serializer.fromJson<String>(json['chartId']),
      profileId: serializer.fromJson<String>(json['profileId']),
      ayanamsa: serializer.fromJson<String>(json['ayanamsa']),
      houseSystem: serializer.fromJson<String>(json['houseSystem']),
      chartFactsJson: serializer.fromJson<String>(json['chartFactsJson']),
      calculatedAt: serializer.fromJson<DateTime>(json['calculatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chartId': serializer.toJson<String>(chartId),
      'profileId': serializer.toJson<String>(profileId),
      'ayanamsa': serializer.toJson<String>(ayanamsa),
      'houseSystem': serializer.toJson<String>(houseSystem),
      'chartFactsJson': serializer.toJson<String>(chartFactsJson),
      'calculatedAt': serializer.toJson<DateTime>(calculatedAt),
    };
  }

  ChartCache copyWith(
          {String? chartId,
          String? profileId,
          String? ayanamsa,
          String? houseSystem,
          String? chartFactsJson,
          DateTime? calculatedAt}) =>
      ChartCache(
        chartId: chartId ?? this.chartId,
        profileId: profileId ?? this.profileId,
        ayanamsa: ayanamsa ?? this.ayanamsa,
        houseSystem: houseSystem ?? this.houseSystem,
        chartFactsJson: chartFactsJson ?? this.chartFactsJson,
        calculatedAt: calculatedAt ?? this.calculatedAt,
      );
  ChartCache copyWithCompanion(ChartCachesCompanion data) {
    return ChartCache(
      chartId: data.chartId.present ? data.chartId.value : this.chartId,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      ayanamsa: data.ayanamsa.present ? data.ayanamsa.value : this.ayanamsa,
      houseSystem:
          data.houseSystem.present ? data.houseSystem.value : this.houseSystem,
      chartFactsJson: data.chartFactsJson.present
          ? data.chartFactsJson.value
          : this.chartFactsJson,
      calculatedAt: data.calculatedAt.present
          ? data.calculatedAt.value
          : this.calculatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChartCache(')
          ..write('chartId: $chartId, ')
          ..write('profileId: $profileId, ')
          ..write('ayanamsa: $ayanamsa, ')
          ..write('houseSystem: $houseSystem, ')
          ..write('chartFactsJson: $chartFactsJson, ')
          ..write('calculatedAt: $calculatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      chartId, profileId, ayanamsa, houseSystem, chartFactsJson, calculatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChartCache &&
          other.chartId == this.chartId &&
          other.profileId == this.profileId &&
          other.ayanamsa == this.ayanamsa &&
          other.houseSystem == this.houseSystem &&
          other.chartFactsJson == this.chartFactsJson &&
          other.calculatedAt == this.calculatedAt);
}

class ChartCachesCompanion extends UpdateCompanion<ChartCache> {
  final Value<String> chartId;
  final Value<String> profileId;
  final Value<String> ayanamsa;
  final Value<String> houseSystem;
  final Value<String> chartFactsJson;
  final Value<DateTime> calculatedAt;
  final Value<int> rowid;
  const ChartCachesCompanion({
    this.chartId = const Value.absent(),
    this.profileId = const Value.absent(),
    this.ayanamsa = const Value.absent(),
    this.houseSystem = const Value.absent(),
    this.chartFactsJson = const Value.absent(),
    this.calculatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChartCachesCompanion.insert({
    required String chartId,
    required String profileId,
    required String ayanamsa,
    required String houseSystem,
    required String chartFactsJson,
    required DateTime calculatedAt,
    this.rowid = const Value.absent(),
  })  : chartId = Value(chartId),
        profileId = Value(profileId),
        ayanamsa = Value(ayanamsa),
        houseSystem = Value(houseSystem),
        chartFactsJson = Value(chartFactsJson),
        calculatedAt = Value(calculatedAt);
  static Insertable<ChartCache> custom({
    Expression<String>? chartId,
    Expression<String>? profileId,
    Expression<String>? ayanamsa,
    Expression<String>? houseSystem,
    Expression<String>? chartFactsJson,
    Expression<DateTime>? calculatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chartId != null) 'chart_id': chartId,
      if (profileId != null) 'profile_id': profileId,
      if (ayanamsa != null) 'ayanamsa': ayanamsa,
      if (houseSystem != null) 'house_system': houseSystem,
      if (chartFactsJson != null) 'chart_facts_json': chartFactsJson,
      if (calculatedAt != null) 'calculated_at': calculatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChartCachesCompanion copyWith(
      {Value<String>? chartId,
      Value<String>? profileId,
      Value<String>? ayanamsa,
      Value<String>? houseSystem,
      Value<String>? chartFactsJson,
      Value<DateTime>? calculatedAt,
      Value<int>? rowid}) {
    return ChartCachesCompanion(
      chartId: chartId ?? this.chartId,
      profileId: profileId ?? this.profileId,
      ayanamsa: ayanamsa ?? this.ayanamsa,
      houseSystem: houseSystem ?? this.houseSystem,
      chartFactsJson: chartFactsJson ?? this.chartFactsJson,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chartId.present) {
      map['chart_id'] = Variable<String>(chartId.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (ayanamsa.present) {
      map['ayanamsa'] = Variable<String>(ayanamsa.value);
    }
    if (houseSystem.present) {
      map['house_system'] = Variable<String>(houseSystem.value);
    }
    if (chartFactsJson.present) {
      map['chart_facts_json'] = Variable<String>(chartFactsJson.value);
    }
    if (calculatedAt.present) {
      map['calculated_at'] = Variable<DateTime>(calculatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChartCachesCompanion(')
          ..write('chartId: $chartId, ')
          ..write('profileId: $profileId, ')
          ..write('ayanamsa: $ayanamsa, ')
          ..write('houseSystem: $houseSystem, ')
          ..write('chartFactsJson: $chartFactsJson, ')
          ..write('calculatedAt: $calculatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProfileCachesTable profileCaches = $ProfileCachesTable(this);
  late final $ChartCachesTable chartCaches = $ChartCachesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [profileCaches, chartCaches];
}

typedef $$ProfileCachesTableCreateCompanionBuilder = ProfileCachesCompanion
    Function({
  required String id,
  required String name,
  required String dateOfBirth,
  required String timeOfBirth,
  required String placeName,
  required double latitude,
  required double longitude,
  required String timezone,
  required bool isPrimary,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> syncedAt,
  required bool isDirty,
  Value<int> rowid,
});
typedef $$ProfileCachesTableUpdateCompanionBuilder = ProfileCachesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> dateOfBirth,
  Value<String> timeOfBirth,
  Value<String> placeName,
  Value<double> latitude,
  Value<double> longitude,
  Value<String> timezone,
  Value<bool> isPrimary,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> syncedAt,
  Value<bool> isDirty,
  Value<int> rowid,
});

class $$ProfileCachesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileCachesTable> {
  $$ProfileCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timeOfBirth => $composableBuilder(
      column: $table.timeOfBirth, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get placeName => $composableBuilder(
      column: $table.placeName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPrimary => $composableBuilder(
      column: $table.isPrimary, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDirty => $composableBuilder(
      column: $table.isDirty, builder: (column) => ColumnFilters(column));
}

class $$ProfileCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileCachesTable> {
  $$ProfileCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timeOfBirth => $composableBuilder(
      column: $table.timeOfBirth, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get placeName => $composableBuilder(
      column: $table.placeName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timezone => $composableBuilder(
      column: $table.timezone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
      column: $table.isPrimary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
      column: $table.syncedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDirty => $composableBuilder(
      column: $table.isDirty, builder: (column) => ColumnOrderings(column));
}

class $$ProfileCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileCachesTable> {
  $$ProfileCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dateOfBirth => $composableBuilder(
      column: $table.dateOfBirth, builder: (column) => column);

  GeneratedColumn<String> get timeOfBirth => $composableBuilder(
      column: $table.timeOfBirth, builder: (column) => column);

  GeneratedColumn<String> get placeName =>
      $composableBuilder(column: $table.placeName, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);
}

class $$ProfileCachesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProfileCachesTable,
    ProfileCache,
    $$ProfileCachesTableFilterComposer,
    $$ProfileCachesTableOrderingComposer,
    $$ProfileCachesTableAnnotationComposer,
    $$ProfileCachesTableCreateCompanionBuilder,
    $$ProfileCachesTableUpdateCompanionBuilder,
    (
      ProfileCache,
      BaseReferences<_$AppDatabase, $ProfileCachesTable, ProfileCache>
    ),
    ProfileCache,
    PrefetchHooks Function()> {
  $$ProfileCachesTableTableManager(_$AppDatabase db, $ProfileCachesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> dateOfBirth = const Value.absent(),
            Value<String> timeOfBirth = const Value.absent(),
            Value<String> placeName = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<String> timezone = const Value.absent(),
            Value<bool> isPrimary = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> syncedAt = const Value.absent(),
            Value<bool> isDirty = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfileCachesCompanion(
            id: id,
            name: name,
            dateOfBirth: dateOfBirth,
            timeOfBirth: timeOfBirth,
            placeName: placeName,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            isPrimary: isPrimary,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            isDirty: isDirty,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String dateOfBirth,
            required String timeOfBirth,
            required String placeName,
            required double latitude,
            required double longitude,
            required String timezone,
            required bool isPrimary,
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> syncedAt = const Value.absent(),
            required bool isDirty,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProfileCachesCompanion.insert(
            id: id,
            name: name,
            dateOfBirth: dateOfBirth,
            timeOfBirth: timeOfBirth,
            placeName: placeName,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone,
            isPrimary: isPrimary,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncedAt: syncedAt,
            isDirty: isDirty,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProfileCachesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProfileCachesTable,
    ProfileCache,
    $$ProfileCachesTableFilterComposer,
    $$ProfileCachesTableOrderingComposer,
    $$ProfileCachesTableAnnotationComposer,
    $$ProfileCachesTableCreateCompanionBuilder,
    $$ProfileCachesTableUpdateCompanionBuilder,
    (
      ProfileCache,
      BaseReferences<_$AppDatabase, $ProfileCachesTable, ProfileCache>
    ),
    ProfileCache,
    PrefetchHooks Function()>;
typedef $$ChartCachesTableCreateCompanionBuilder = ChartCachesCompanion
    Function({
  required String chartId,
  required String profileId,
  required String ayanamsa,
  required String houseSystem,
  required String chartFactsJson,
  required DateTime calculatedAt,
  Value<int> rowid,
});
typedef $$ChartCachesTableUpdateCompanionBuilder = ChartCachesCompanion
    Function({
  Value<String> chartId,
  Value<String> profileId,
  Value<String> ayanamsa,
  Value<String> houseSystem,
  Value<String> chartFactsJson,
  Value<DateTime> calculatedAt,
  Value<int> rowid,
});

class $$ChartCachesTableFilterComposer
    extends Composer<_$AppDatabase, $ChartCachesTable> {
  $$ChartCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chartId => $composableBuilder(
      column: $table.chartId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ayanamsa => $composableBuilder(
      column: $table.ayanamsa, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get houseSystem => $composableBuilder(
      column: $table.houseSystem, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chartFactsJson => $composableBuilder(
      column: $table.chartFactsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get calculatedAt => $composableBuilder(
      column: $table.calculatedAt, builder: (column) => ColumnFilters(column));
}

class $$ChartCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChartCachesTable> {
  $$ChartCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chartId => $composableBuilder(
      column: $table.chartId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileId => $composableBuilder(
      column: $table.profileId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ayanamsa => $composableBuilder(
      column: $table.ayanamsa, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get houseSystem => $composableBuilder(
      column: $table.houseSystem, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chartFactsJson => $composableBuilder(
      column: $table.chartFactsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get calculatedAt => $composableBuilder(
      column: $table.calculatedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$ChartCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChartCachesTable> {
  $$ChartCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chartId =>
      $composableBuilder(column: $table.chartId, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get ayanamsa =>
      $composableBuilder(column: $table.ayanamsa, builder: (column) => column);

  GeneratedColumn<String> get houseSystem => $composableBuilder(
      column: $table.houseSystem, builder: (column) => column);

  GeneratedColumn<String> get chartFactsJson => $composableBuilder(
      column: $table.chartFactsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get calculatedAt => $composableBuilder(
      column: $table.calculatedAt, builder: (column) => column);
}

class $$ChartCachesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChartCachesTable,
    ChartCache,
    $$ChartCachesTableFilterComposer,
    $$ChartCachesTableOrderingComposer,
    $$ChartCachesTableAnnotationComposer,
    $$ChartCachesTableCreateCompanionBuilder,
    $$ChartCachesTableUpdateCompanionBuilder,
    (ChartCache, BaseReferences<_$AppDatabase, $ChartCachesTable, ChartCache>),
    ChartCache,
    PrefetchHooks Function()> {
  $$ChartCachesTableTableManager(_$AppDatabase db, $ChartCachesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChartCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChartCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChartCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> chartId = const Value.absent(),
            Value<String> profileId = const Value.absent(),
            Value<String> ayanamsa = const Value.absent(),
            Value<String> houseSystem = const Value.absent(),
            Value<String> chartFactsJson = const Value.absent(),
            Value<DateTime> calculatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChartCachesCompanion(
            chartId: chartId,
            profileId: profileId,
            ayanamsa: ayanamsa,
            houseSystem: houseSystem,
            chartFactsJson: chartFactsJson,
            calculatedAt: calculatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String chartId,
            required String profileId,
            required String ayanamsa,
            required String houseSystem,
            required String chartFactsJson,
            required DateTime calculatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChartCachesCompanion.insert(
            chartId: chartId,
            profileId: profileId,
            ayanamsa: ayanamsa,
            houseSystem: houseSystem,
            chartFactsJson: chartFactsJson,
            calculatedAt: calculatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChartCachesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChartCachesTable,
    ChartCache,
    $$ChartCachesTableFilterComposer,
    $$ChartCachesTableOrderingComposer,
    $$ChartCachesTableAnnotationComposer,
    $$ChartCachesTableCreateCompanionBuilder,
    $$ChartCachesTableUpdateCompanionBuilder,
    (ChartCache, BaseReferences<_$AppDatabase, $ChartCachesTable, ChartCache>),
    ChartCache,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProfileCachesTableTableManager get profileCaches =>
      $$ProfileCachesTableTableManager(_db, _db.profileCaches);
  $$ChartCachesTableTableManager get chartCaches =>
      $$ChartCachesTableTableManager(_db, _db.chartCaches);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'63ee888947c6b70ff7ffbf17b8b09651fda53b06';

/// Riverpod provider for the database instance.
///
/// Copied from [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = AutoDisposeProvider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = AutoDisposeProviderRef<AppDatabase>;
String _$cachedProfilesStreamHash() =>
    r'5fb607f9ff3c9ed8cd9e2c631d0c222eecadb430';

/// Provider for reactive profile list from local cache.
///
/// Copied from [cachedProfilesStream].
@ProviderFor(cachedProfilesStream)
final cachedProfilesStreamProvider =
    AutoDisposeStreamProvider<List<BirthProfile>>.internal(
  cachedProfilesStream,
  name: r'cachedProfilesStreamProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cachedProfilesStreamHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CachedProfilesStreamRef
    = AutoDisposeStreamProviderRef<List<BirthProfile>>;
String _$cachedProfilesFutureHash() =>
    r'ef7aa9ebdce7122993b9a2031f506f96c6cab3dd';

/// Provider for one-time fetch of cached profiles.
///
/// Copied from [cachedProfilesFuture].
@ProviderFor(cachedProfilesFuture)
final cachedProfilesFutureProvider =
    AutoDisposeFutureProvider<List<BirthProfile>>.internal(
  cachedProfilesFuture,
  name: r'cachedProfilesFutureProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cachedProfilesFutureHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CachedProfilesFutureRef
    = AutoDisposeFutureProviderRef<List<BirthProfile>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
