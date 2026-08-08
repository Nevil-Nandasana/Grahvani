/// Transit Data Layer — Repository for Sade Sati and transit-related API calls
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

final transitRepositoryProvider = Provider<TransitRepository>(
  (ref) => TransitRepository(dio: ref.watch(apiClientProvider)),
);

class TransitRepository {
  const TransitRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Get current Sade Sati status for a profile
  Future<SadeSatiStatus> getSadeSatiStatus(String profileId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/transits/sade-sati/$profileId',
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return SadeSatiStatus.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

/// Sade Sati Status Model
class SadeSatiStatus {
  final bool isSadeSati;
  final String? phase;
  final String moonSign;
  final String saturnSign;
  final String? description;
  final String? startDate;
  final String? endDate;
  final int? daysRemaining;

  SadeSatiStatus({
    required this.isSadeSati,
    required this.phase,
    required this.moonSign,
    required this.saturnSign,
    this.description,
    this.startDate,
    this.endDate,
    this.daysRemaining,
  });

  factory SadeSatiStatus.fromJson(Map<String, dynamic> json) {
    return SadeSatiStatus(
      isSadeSati: json['is_sade_sati'] as bool,
      phase: json['phase'] as String?,
      moonSign: json['moon_sign'] as String,
      saturnSign: json['saturn_sign'] as String,
      description: json['description'] as String?,
      startDate: json['start_date'] as String?,
      endDate: json['end_date'] as String?,
      daysRemaining: json['days_remaining'] as int?,
    );
  }
}