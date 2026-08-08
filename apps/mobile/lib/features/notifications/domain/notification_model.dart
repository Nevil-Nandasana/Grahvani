/// Notification Domain Models
/// Data models for push notifications and preferences

enum NotificationType {
  sadeSati,
  dashaTransition,
  majorTransit,
  test;

  static NotificationType fromString(String val) {
    switch (val) {
      case 'sade_sati':
        return NotificationType.sadeSati;
      case 'dasha_transition':
        return NotificationType.dashaTransition;
      case 'major_transit':
        return NotificationType.majorTransit;
      default:
        return NotificationType.test;
    }
  }

  String toJson() {
    switch (this) {
      case NotificationType.sadeSati:
        return 'sade_sati';
      case NotificationType.dashaTransition:
        return 'dasha_transition';
      case NotificationType.majorTransit:
        return 'major_transit';
      case NotificationType.test:
        return 'test';
    }
  }
}

class NotificationPreferences {
  final bool transitAlerts;
  final bool sadeSatiAlerts;
  final bool dashaAlerts;
  final bool majorTransitAlerts;
  final String quietHoursStart;
  final String quietHoursEnd;
  final Map<String, String> lastSadeSatiNotification;
  final String lastDashaNotification;

  const NotificationPreferences({
    this.transitAlerts = true,
    this.sadeSatiAlerts = true,
    this.dashaAlerts = true,
    this.majorTransitAlerts = true,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '07:00',
    this.lastSadeSatiNotification = const {},
    this.lastDashaNotification = '',
  });

  NotificationPreferences copyWith({
    bool? transitAlerts,
    bool? sadeSatiAlerts,
    bool? dashaAlerts,
    bool? majorTransitAlerts,
    String? quietHoursStart,
    String? quietHoursEnd,
    Map<String, String>? lastSadeSatiNotification,
    String? lastDashaNotification,
  }) {
    return NotificationPreferences(
      transitAlerts: transitAlerts ?? this.transitAlerts,
      sadeSatiAlerts: sadeSatiAlerts ?? this.sadeSatiAlerts,
      dashaAlerts: dashaAlerts ?? this.dashaAlerts,
      majorTransitAlerts: majorTransitAlerts ?? this.majorTransitAlerts,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      lastSadeSatiNotification:
          lastSadeSatiNotification ?? this.lastSadeSatiNotification,
      lastDashaNotification:
          lastDashaNotification ?? this.lastDashaNotification,
    );
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      transitAlerts: json['transitAlerts'] as bool? ?? true,
      sadeSatiAlerts: json['sadeSatiAlerts'] as bool? ?? true,
      dashaAlerts: json['dashaAlerts'] as bool? ?? true,
      majorTransitAlerts: json['majorTransitAlerts'] as bool? ?? true,
      quietHoursStart: json['quietHoursStart'] as String? ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? '07:00',
      lastSadeSatiNotification: Map<String, String>.from(
          json['lastSadeSatiNotification'] as Map? ?? {}),
      lastDashaNotification: json['lastDashaNotification'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transitAlerts': transitAlerts,
      'sadeSatiAlerts': sadeSatiAlerts,
      'dashaAlerts': dashaAlerts,
      'majorTransitAlerts': majorTransitAlerts,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'lastSadeSatiNotification': lastSadeSatiNotification,
      'lastDashaNotification': lastDashaNotification,
    };
  }
}

class PushNotification {
  final String id;
  final String profileId;
  final String profileName;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;

  const PushNotification({
    required this.id,
    required this.profileId,
    required this.profileName,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
    this.isRead = false,
  });

  PushNotification copyWith({
    String? id,
    String? profileId,
    String? profileName,
    NotificationType? type,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return PushNotification(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      profileName: profileName ?? this.profileName,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  factory PushNotification.fromJson(Map<String, dynamic> json) {
    return PushNotification(
      id: json['id'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      profileName: json['profileName'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String? ?? 'test'),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: Map<String, dynamic>.from(json['data'] as Map? ?? {}),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profileId': profileId,
      'profileName': profileName,
      'type': type.toJson(),
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class SadeSatiInfo {
  final bool isActive;
  final String phase;
  final String moonSign;
  final String saturnSign;
  final String description;
  final DateTime? phaseStartDate;
  final DateTime? phaseEndDate;

  const SadeSatiInfo({
    required this.isActive,
    required this.phase,
    required this.moonSign,
    required this.saturnSign,
    required this.description,
    this.phaseStartDate,
    this.phaseEndDate,
  });

  factory SadeSatiInfo.fromJson(Map<String, dynamic> json) {
    return SadeSatiInfo(
      isActive: json['isActive'] as bool? ?? false,
      phase: json['phase'] as String? ?? '',
      moonSign: json['moonSign'] as String? ?? '',
      saturnSign: json['saturnSign'] as String? ?? '',
      description: json['description'] as String? ?? '',
      phaseStartDate: json['phaseStartDate'] != null
          ? DateTime.parse(json['phaseStartDate'] as String)
          : null,
      phaseEndDate: json['phaseEndDate'] != null
          ? DateTime.parse(json['phaseEndDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'phase': phase,
      'moonSign': moonSign,
      'saturnSign': saturnSign,
      'description': description,
      'phaseStartDate': phaseStartDate?.toIso8601String(),
      'phaseEndDate': phaseEndDate?.toIso8601String(),
    };
  }
}

class DashaTransitionInfo {
  final bool isUpcoming;
  final String transitionType;
  final String planet;
  final String date;
  final int daysUntil;
  final String? fromPlanet;

  const DashaTransitionInfo({
    required this.isUpcoming,
    required this.transitionType,
    required this.planet,
    required this.date,
    required this.daysUntil,
    this.fromPlanet,
  });

  factory DashaTransitionInfo.fromJson(Map<String, dynamic> json) {
    return DashaTransitionInfo(
      isUpcoming: json['isUpcoming'] as bool? ?? false,
      transitionType: json['transitionType'] as String? ?? '',
      planet: json['planet'] as String? ?? '',
      date: json['date'] as String? ?? '',
      daysUntil: json['daysUntil'] as int? ?? 0,
      fromPlanet: json['fromPlanet'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isUpcoming': isUpcoming,
      'transitionType': transitionType,
      'planet': planet,
      'date': date,
      'daysUntil': daysUntil,
      'fromPlanet': fromPlanet,
    };
  }
}

class ProfileNotificationStatus {
  final String profileId;
  final String profileName;
  final bool notificationEnabled;
  final NotificationPreferences preferences;

  const ProfileNotificationStatus({
    required this.profileId,
    required this.profileName,
    required this.notificationEnabled,
    required this.preferences,
  });

  factory ProfileNotificationStatus.fromJson(Map<String, dynamic> json) {
    return ProfileNotificationStatus(
      profileId: json['profileId'] as String? ?? '',
      profileName: json['profileName'] as String? ?? '',
      notificationEnabled: json['notificationEnabled'] as bool? ?? false,
      preferences: json['preferences'] != null
          ? NotificationPreferences.fromJson(
              json['preferences'] as Map<String, dynamic>)
          : const NotificationPreferences(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileId': profileId,
      'profileName': profileName,
      'notificationEnabled': notificationEnabled,
      'preferences': preferences.toJson(),
    };
  }
}