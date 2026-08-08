/// Notification Repository - API Layer
/// Handles all notification-related API calls

import 'package:dio/dio.dart';
import 'package:grahvani/core/api_client.dart';
import 'package:grahvani/features/notifications/domain/notification_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_repository.g.dart';

class NotificationRepository {
  NotificationRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  /// Update FCM token on backend
  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.post(
        '/api/v1/notifications/fcm-token',
        data: {'fcm_token': token},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get notification preferences for a profile
  Future<ProfileNotificationStatus> getNotificationPreferences(String profileId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/notifications/preferences/$profileId',
      );
      final data = response.data?['data'] ?? response.data ?? {};
      return ProfileNotificationStatus.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Update notification preferences for a profile
  Future<ProfileNotificationStatus> updateNotificationPreferences(
    String profileId,
    NotificationPreferences preferences,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/api/v1/notifications/preferences/$profileId',
        data: preferences.toJson(),
      );
      final data = response.data?['data'] ?? response.data ?? {};
      return ProfileNotificationStatus.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Toggle all notifications for a profile
  Future<ProfileNotificationStatus> toggleNotifications(String profileId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/notifications/preferences/$profileId/toggle',
      );
      final data = response.data?['data'] ?? response.data ?? {};
      return ProfileNotificationStatus.fromJson(data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Send test notification
  Future<void> sendTestNotification(String profileId) async {
    try {
      await _dio.post(
        '/api/v1/notifications/test/$profileId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get notification history (placeholder)
  Future<List<PushNotification>> getNotificationHistory(
    String profileId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v1/notifications/history/$profileId',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      final data = response.data?['data'] ?? response.data ?? {};
      final notifications = data['notifications'] as List? ?? [];
      return notifications.map((n) => PushNotification.fromJson(n)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

@riverpod
NotificationRepository notificationRepository(Ref ref) {
  return NotificationRepository(dio: ref.watch(apiClientProvider));
}