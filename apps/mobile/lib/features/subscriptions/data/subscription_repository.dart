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
    this.isTrial = false,
    this.trialExpiresAt,
    this.trialEligible = true,
  });

  final String tier;
  final bool isActive;
  final int dailyQueriesLimit;
  final int queriesRemaining;
  final DateTime? expiresAt;
  final bool isTrial;
  final DateTime? trialExpiresAt;
  final bool trialEligible;

  bool get isPremium => tier != 'free';

  /// True if user is currently in an active 7-day trial period
  bool get isTrialActive =>
      isPremium &&
      isTrial &&
      trialExpiresAt != null &&
      trialExpiresAt!.isAfter(DateTime.now());

  /// Number of trial days remaining
  int get remainingTrialDays {
    if (trialExpiresAt == null) return 0;
    final now = DateTime.now();
    if (!trialExpiresAt!.isAfter(now)) return 0;
    final diffInSeconds = trialExpiresAt!.difference(now).inSeconds;
    final days = (diffInSeconds / 86400).ceil();
    return days <= 0 ? 1 : days;
  }

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    return Entitlements(
      tier: json['tier'] as String? ?? 'free',
      isActive: json['is_active'] as bool? ?? false,
      dailyQueriesLimit: json['daily_queries_limit'] as int? ?? 5,
      queriesRemaining: json['queries_remaining'] as int? ?? 5,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      isTrial: json['is_trial'] as bool? ?? false,
      trialExpiresAt: json['trial_expires_at'] != null
          ? DateTime.tryParse(json['trial_expires_at'] as String)
          : null,
      trialEligible: json['trial_eligible'] as bool? ??
          !(json['has_used_trial'] as bool? ?? false),
    );
  }
}

class TrialActivationResult {
  const TrialActivationResult({
    required this.status,
    required this.trialStartedAt,
    required this.trialExpiresAt,
    required this.isTrial,
  });

  final String status;
  final DateTime trialStartedAt;
  final DateTime trialExpiresAt;
  final bool isTrial;

  factory TrialActivationResult.fromJson(Map<String, dynamic> json) {
    return TrialActivationResult(
      status: json['status'] as String? ?? 'success',
      trialStartedAt: json['trial_started_at'] != null
          ? DateTime.parse(json['trial_started_at'] as String)
          : DateTime.now(),
      trialExpiresAt: json['trial_expires_at'] != null
          ? DateTime.parse(json['trial_expires_at'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      isTrial: json['is_trial'] as bool? ?? true,
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

  /// POST /api/v1/billing/trial/activate
  Future<TrialActivationResult> activateTrial() async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/billing/trial/activate',
      );
      final data = response.data?['data'] ?? response.data ?? {};
      return TrialActivationResult.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
