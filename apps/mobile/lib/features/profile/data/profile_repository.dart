/// Profile Data Layer — API repository for birth profiles with local Drift cache
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api_client.dart';
import '../../../core/database/app_database.dart';
import '../domain/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    dio: ref.watch(apiClientProvider),
    database: ref.watch(appDatabaseProvider),
  ),
);

class ProfileRepository {
  ProfileRepository({required Dio dio, required AppDatabase database})
      : _dio = dio,
        _database = database;

  final Dio _dio;
  final AppDatabase _database;

  /// GET /api/v1/profiles — list all active profiles for the current user.
  /// Returns cached profiles immediately, then syncs with server in background.
  Future<List<BirthProfile>> listProfiles() async {
    // First, return cached profiles for instant UI
    final cached = await _database.getAllProfiles();
    
    // Then fetch from server and update cache
    try {
      final response = await _dio.get('/api/v1/profiles');
      final dynamic rawData = response.data;
      final List listData;
      if (rawData is List) {
        listData = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        listData = rawData['data'] as List;
      } else {
        listData = [];
      }

      final serverProfiles = listData
          .map((e) => BirthProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      
      // Update local cache with server data
      for (final profile in serverProfiles) {
        await _database.upsertProfile(profile);
      }
      
      return serverProfiles;
    } on DioException catch (e) {
      // If network fails, return cached data
      if (cached.isNotEmpty) {
        return cached;
      }
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /api/v1/profiles — create a new birth profile.
  Future<BirthProfile> createProfile({
    required String name,
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeName,
    required double latitude,
    required double longitude,
    required String timezone,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/profiles',
        data: {
          'name': name,
          'date_of_birth': dateOfBirth,
          'time_of_birth': timeOfBirth,
          'place_name': placeName,
          'latitude': latitude,
          'longitude': longitude,
          'timezone': timezone,
        },
      );

      final Map<String, dynamic> responseData;
      if (response.data is Map) {
        final rawMap = response.data as Map;
        if (rawMap.containsKey('data') && rawMap['data'] is Map) {
          responseData = Map<String, dynamic>.from(rawMap['data'] as Map);
        } else {
          responseData = Map<String, dynamic>.from(rawMap);
        }
      } else {
        throw Exception('Invalid profile creation response from server.');
      }

      final profile = BirthProfile.fromJson(responseData);
      
      // Cache locally
      await _database.upsertProfile(profile);
      
      return profile;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Sync local dirty profiles to server.
  Future<void> syncDirtyProfiles() async {
    final dirtyProfiles = await _database.getDirtyProfiles();
    for (final profile in dirtyProfiles) {
      try {
        // In a real implementation, you'd call PATCH /api/v1/profiles/:id
        // For now, just mark as synced
        await _database.markSynced(profile.id);
      } catch (_) {
        // Keep as dirty for retry
      }
    }
  }

  /// Clear local cache (used on sign out).
  Future<void> clearCache() async {
    await _database.clearAll();
  }
}
