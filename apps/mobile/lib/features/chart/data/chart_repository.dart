/// Chart Data Layer — repository wrapping the birth chart API
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';
import '../../../core/database/app_database.dart';
import '../domain/chart_model.dart';

final chartRepositoryProvider = Provider<ChartRepository>(
  (ref) => ChartRepository(
    dio: ref.watch(apiClientProvider),
    database: ref.watch(appDatabaseProvider),
  ),
);

class ChartRepository {
  const ChartRepository({
    required Dio dio,
    required AppDatabase database,
  })  : _dio = dio,
        _database = database;

  final Dio _dio;
  final AppDatabase _database;

  /// Fetch cached chart facts by profile ID for instant offline rendering.
  Future<BirthChartFacts?> getCachedChartForProfile(String profileId) async {
    final cached = await _database.getChartByProfileId(profileId);
    if (cached == null) return null;
    try {
      final factsMap = jsonDecode(cached.chartFactsJson) as Map<String, dynamic>;
      return BirthChartFacts.fromJson(cached.chartId, factsMap);
    } catch (_) {
      return null;
    }
  }

  /// POST /api/v1/charts/calculate — enqueue chart calculation job.
  /// Returns immediately with chart_id to poll.
  Future<String> triggerCalculation(String profileId) async {
    try {
      final response = await _dio.post(
        '/api/v1/charts/calculate',
        data: {'profile_id': profileId, 'ayanamsa': 'lahiri'},
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is Map
          ? (raw.containsKey('data') && raw['data'] is Map
              ? Map<String, dynamic>.from(raw['data'] as Map)
              : Map<String, dynamic>.from(raw))
          : {};
      return (data['chart_id'] ?? '') as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /api/v1/charts/{chartId}/status — poll calculation status.
  Future<String> getChartStatus(String chartId) async {
    try {
      final response = await _dio.get(
        '/api/v1/charts/$chartId/status',
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is Map
          ? (raw.containsKey('data') && raw['data'] is Map
              ? Map<String, dynamic>.from(raw['data'] as Map)
              : Map<String, dynamic>.from(raw))
          : {};
      return (data['status'] ?? 'pending') as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /api/v1/charts/{chartId} — fetch completed chart facts & update local cache.
  Future<BirthChartFacts> getChart(String chartId, {String? profileId}) async {
    try {
      final response = await _dio.get(
        '/api/v1/charts/$chartId',
      );
      final dynamic raw = response.data;
      final Map<String, dynamic> data = raw is Map
          ? (raw.containsKey('data') && raw['data'] is Map
              ? Map<String, dynamic>.from(raw['data'] as Map)
              : Map<String, dynamic>.from(raw))
          : {};
      final dynamic rawFacts = data['chart_facts'];
      final Map<String, dynamic>? facts = rawFacts is Map ? Map<String, dynamic>.from(rawFacts) : null;
      if (facts == null) throw Exception('Chart not yet calculated.');

      final birthChartFacts = BirthChartFacts.fromJson(chartId, facts);

      // Save to Drift local SQLite cache for offline availability
      if (profileId != null) {
        await _database.upsertChart(
          chartId: chartId,
          profileId: profileId,
          ayanamsa: birthChartFacts.ayanamsa,
          houseSystem: 'P',
          chartFactsJson: jsonEncode(facts),
        );
      }

      return birthChartFacts;
    } on DioException catch (e) {
      // If network fails and profileId is provided, try returning cached chart
      if (profileId != null) {
        final cached = await getCachedChartForProfile(profileId);
        if (cached != null) return cached;
      }
      throw ApiException.fromDioException(e);
    }
  }
}
