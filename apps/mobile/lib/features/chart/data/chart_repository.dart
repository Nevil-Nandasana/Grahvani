/// Chart Data Layer — repository wrapping the birth chart API
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api_client.dart';
import '../domain/chart_model.dart';

part 'chart_repository.g.dart';

@riverpod
ChartRepository chartRepository(Ref ref) {
  return ChartRepository(dio: ref.watch(apiClientProvider));
}

class ChartRepository {
  const ChartRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// POST /api/v1/charts/calculate — enqueue chart calculation job.
  /// Returns immediately with chart_id to poll.
  Future<String> triggerCalculation(String profileId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/charts/calculate',
        data: {'profile_id': profileId, 'ayanamsa': 'lahiri'},
      );
      return response.data!['chart_id'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /api/v1/charts/{chartId}/status — poll calculation status.
  Future<String> getChartStatus(String chartId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/charts/$chartId/status',
      );
      return response.data!['status'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// GET /api/v1/charts/{chartId} — fetch completed chart facts.
  Future<BirthChartFacts> getChart(String chartId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/charts/$chartId',
      );
      final data = response.data!;
      final facts = data['chart_facts'] as Map<String, dynamic>?;
      if (facts == null) throw Exception('Chart not yet calculated.');
      return BirthChartFacts.fromJson(chartId, facts);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
