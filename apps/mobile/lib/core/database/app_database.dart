/// Grahvani — Drift SQLite Database
/// Local offline cache for birth profiles with reactive queries.
library;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:grahvani/core/database/connection/connection.dart';
import 'package:grahvani/features/profile/domain/profile_model.dart';

part 'app_database.g.dart';

/// Drift table for cached birth profiles.
@DataClassName('ProfileCache')
class ProfileCaches extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get dateOfBirth => text().named('date_of_birth')();
  TextColumn get timeOfBirth => text().named('time_of_birth')();
  TextColumn get placeName => text().named('place_name')();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get timezone => text()();
  BoolColumn get isPrimary => boolean().named('is_primary')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  DateTimeColumn get syncedAt => dateTime().nullable().named('synced_at')();
  BoolColumn get isDirty => boolean().named('is_dirty')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for cached birth charts.
@DataClassName('ChartCache')
class ChartCaches extends Table {
  TextColumn get chartId => text().named('chart_id')();
  TextColumn get profileId => text().named('profile_id')();
  TextColumn get ayanamsa => text()();
  TextColumn get houseSystem => text().named('house_system')();
  TextColumn get chartFactsJson => text().named('chart_facts_json')();
  DateTimeColumn get calculatedAt => dateTime().named('calculated_at')();

  @override
  Set<Column> get primaryKey => {chartId};
}

/// Database access class.
@DriftDatabase(tables: [ProfileCaches, ChartCaches])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Future migrations go here
        },
      );

  // ─── Profile Cache Operations ────────────────────────────────────────────

  /// Insert or update a profile in local cache.
  Future<void> upsertProfile(BirthProfile profile, {bool isDirty = false}) async {
    final now = DateTime.now();
    await into(profileCaches).insertOnConflictUpdate(
      ProfileCachesCompanion.insert(
        id: profile.id,
        name: profile.name,
        dateOfBirth: profile.dateOfBirth,
        timeOfBirth: profile.timeOfBirth,
        placeName: profile.placeName,
        latitude: profile.latitude,
        longitude: profile.longitude,
        timezone: profile.timezone,
        isPrimary: profile.isPrimary,
        createdAt: now,
        updatedAt: now,
        syncedAt: isDirty ? const Value.absent() : Value(now),
        isDirty: isDirty,
      ),
    );
  }

  /// Initialize database connection
  Future<void> initialize() async {}

  /// Get all cached profiles as a reactive stream.
  Stream<List<BirthProfile>> watchAllProfiles() {
    return (select(profileCaches)
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPrimary),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .watch()
        .map((rows) => rows.map(_profileFromRow).toList());
  }

  /// Get all cached profiles as a one-time future.
  Future<List<BirthProfile>> getAllProfiles() async {
    final rows = await (select(profileCaches)
          ..orderBy([
            (t) => OrderingTerm.desc(t.isPrimary),
            (t) => OrderingTerm.desc(t.updatedAt),
          ]))
        .get();
    return rows.map(_profileFromRow).toList();
  }

  /// Get a single profile by ID.
  Future<BirthProfile?> getProfile(String id) async {
    final row = await (select(profileCaches)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _profileFromRow(row) : null;
  }

  /// Get the primary profile.
  Future<BirthProfile?> getPrimaryProfile() async {
    final row = await (select(profileCaches)..where((t) => t.isPrimary.equals(true)))
        .getSingleOrNull();
    return row != null ? _profileFromRow(row) : null;
  }

  /// Mark profile as synced with server.
  Future<void> markSynced(String id) async {
    await (update(profileCaches)..where((t) => t.id.equals(id))).write(
      ProfileCachesCompanion(
        syncedAt: Value(DateTime.now()),
        isDirty: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Mark profile as dirty (needs sync).
  Future<void> markDirty(String id) async {
    await (update(profileCaches)..where((t) => t.id.equals(id))).write(
      ProfileCachesCompanion(
        isDirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Get all dirty profiles that need syncing.
  Future<List<BirthProfile>> getDirtyProfiles() async {
    final rows = await (select(profileCaches)..where((t) => t.isDirty.equals(true)))
        .get();
    return rows.map(_profileFromRow).toList();
  }

  /// Delete a profile from local cache.
  Future<void> deleteProfile(String id) async {
    await (delete(profileCaches)..where((t) => t.id.equals(id))).go();
  }

  /// Clear all cached profiles and charts (used on sign out).
  Future<void> clearAll() async {
    await delete(profileCaches).go();
    await delete(chartCaches).go();
  }

  // ─── Chart Cache Operations ──────────────────────────────────────────────

  /// Insert or update chart facts in local cache.
  Future<void> upsertChart({
    required String chartId,
    required String profileId,
    required String ayanamsa,
    required String houseSystem,
    required String chartFactsJson,
  }) async {
    final now = DateTime.now();
    await into(chartCaches).insertOnConflictUpdate(
      ChartCachesCompanion.insert(
        chartId: chartId,
        profileId: profileId,
        ayanamsa: ayanamsa,
        houseSystem: houseSystem,
        chartFactsJson: chartFactsJson,
        calculatedAt: now,
      ),
    );
  }

  /// Get cached chart by chartId.
  Future<ChartCache?> getChart(String chartId) async {
    return (select(chartCaches)..where((t) => t.chartId.equals(chartId))).getSingleOrNull();
  }

  /// Get cached chart by profileId.
  Future<ChartCache?> getChartByProfileId(String profileId) async {
    final rows = await (select(chartCaches)
          ..where((t) => t.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.calculatedAt)]))
        .get();
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Delete a chart from local cache.
  Future<void> deleteChart(String chartId) async {
    await (delete(chartCaches)..where((t) => t.chartId.equals(chartId))).go();
  }

  /// Convert Drift row to BirthProfile domain model.
  BirthProfile _profileFromRow(ProfileCache row) {
    return BirthProfile(
      id: row.id,
      name: row.name,
      dateOfBirth: row.dateOfBirth,
      timeOfBirth: row.timeOfBirth,
      placeName: row.placeName,
      latitude: row.latitude,
      longitude: row.longitude,
      timezone: row.timezone,
      isPrimary: row.isPrimary,
    );
  }
}

/// Riverpod provider for the database instance.
@riverpod
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
}

final databaseProvider = appDatabaseProvider;

/// Provider for reactive profile list from local cache.
@riverpod
Stream<List<BirthProfile>> cachedProfilesStream(Ref ref) {
  return ref.watch(appDatabaseProvider).watchAllProfiles();
}

/// Provider for one-time fetch of cached profiles.
@riverpod
Future<List<BirthProfile>> cachedProfilesFuture(Ref ref) {
  return ref.watch(appDatabaseProvider).getAllProfiles();
}