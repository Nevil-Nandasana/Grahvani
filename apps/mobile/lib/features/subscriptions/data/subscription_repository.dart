/// Subscriptions Data Layer
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api_client.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(dio: ref.watch(apiClientProvider)),
);

class Entitlements {
  const Entitlements({
    required this.tier,
    required this.isActive,
    required this.dailyQueriesLimit,
    required this.queriesRemaining,
    this.expiresAt,
  });

  final String tier;
  final bool isActive;
  final int dailyQueriesLimit;
  final int queriesRemaining;
  final DateTime? expiresAt;

  bool get isPremium => tier != 'free';

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    return Entitlements(
      tier: json['tier'] as String? ?? 'free',
      isActive: json['is_active'] as bool? ?? false,
      dailyQueriesLimit: json['daily_queries_limit'] as int? ?? 5,
      queriesRemaining: json['queries_remaining'] as int? ?? 5,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
    );
  }
}

class SubscriptionRepository {
  const SubscriptionRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// GET /api/v1/billing/entitlements
  Future<Entitlements> getEntitlements() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/billing/entitlements',
      );
      final data = response.data?['data'] ?? response.data ?? {};
      return Entitlements.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
