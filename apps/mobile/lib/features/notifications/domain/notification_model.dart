/// Notification Domain Models
/// Data models for push notifications and preferences

import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    @Default(true) bool transitAlerts,
    @Default(true) bool sadeSatiAlerts,
    @Default(true) bool dashaAlerts,
    @Default(true) bool majorTransitAlerts,
    @Default('22:00') String quietHoursStart,
    @Default('07:00') String quietHoursEnd,
    @Default({}) Map<String, String> lastSadeSatiNotification,
    @Default('') String lastDashaNotification,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);
}

@freezed
class PushNotification with _$PushNotification {
  const factory PushNotification({
    required String id,
    required String profileId,
    required String profileName,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required DateTime timestamp,
    @Default(false) bool isRead,
  }) = _PushNotification;

  factory PushNotification.fromJson(Map<String, dynamic> json) =>
      _$PushNotificationFromJson(json);
}

enum NotificationType {
  @JsonValue('sade_sati')
  sadeSati,
  @JsonValue('dasha_transition')
  dashaTransition,
  @JsonValue('major_transit')
  majorTransit,
  @JsonValue('test')
  test,
}

@freezed
class SadeSatiInfo with _$SadeSatiInfo {
  const factory SadeSatiInfo({
    required bool isActive,
    required String phase, // first_phase, second_phase, third_phase
    required String moonSign,
    required String saturnSign,
    required String description,
    DateTime? phaseStartDate,
    DateTime? phaseEndDate,
  }) = _SadeSatiInfo;

  factory SadeSatiInfo.fromJson(Map<String, dynamic> json) =>
      _$SadeSatiInfoFromJson(json);
}

@freezed
class DashaTransitionInfo with _$DashaTransitionInfo {
  const factory DashaTransitionInfo({
    required bool isUpcoming,
    required String transitionType, // maha_change, maha_ending
    required String planet,
    required String date,
    required int daysUntil,
    String? fromPlanet,
  }) = _DashaTransitionInfo;

  factory DashaTransitionInfo.fromJson(Map<String, dynamic> json) =>
      _$DashaTransitionInfoFromJson(json);
}

@freezed
class ProfileNotificationStatus with _$ProfileNotificationStatus {
  const factory ProfileNotificationStatus({
    required String profileId,
    required String profileName,
    required bool notificationEnabled,
    required NotificationPreferences preferences,
  }) = _ProfileNotificationStatus;

  factory ProfileNotificationStatus.fromJson(Map<String, dynamic> json) =>
      _$ProfileNotificationStatusFromJson(json);
}