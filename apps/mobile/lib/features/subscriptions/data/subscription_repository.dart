/// Subscriptions Data Layer
library;

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/api_client.dart';

part 'subscription_repository.g.dart';

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository(dio: ref.watch(apiClientProvider));
}

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
      tier: json['tier'] as String,
      isActive: json['is_active'] as bool,
      dailyQueriesLimit: json['daily_queries_limit'] as int,
      queriesRemaining: json['queries_remaining'] as int,
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
      return Entitlements.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
