/// FCM Service for Push Notifications
/// Handles Firebase Cloud Messaging integration

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grahvani/features/auth/data/auth_repository.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Initialize FCM - request permissions, get token, set up handlers
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Request permissions (iOS)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: Permission granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('FCM: Provisional permission granted');
    } else {
      debugPrint('FCM: Permission denied');
      return;
    }
    
    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      // Token will be sent to backend via auth repository
      _sendTokenToBackend(token);
    }
    
    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      _sendTokenToBackend(newToken);
    });
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages (app opened from notification)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Handle terminated state messages
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
    
    // Create notification channel for Android
    _createNotificationChannel();
    
    _initialized = true;
  }
  
  static void _sendTokenToBackend(String token) {
    // This will be called via the auth repository provider
    // The provider will be set up in main.dart
    FCMService.onTokenRefresh?.call(token);
  }
  
  // Callback for token refresh - set by provider
  static void Function(String)? onTokenRefresh;
  
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM Foreground: ${message.notification?.title} - ${message.notification?.body}');
    debugPrint('FCM Data: ${message.data}');
    
    // Show local notification or update UI
    // Could use flutter_local_notifications for in-app display
  }
  
  static void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('FCM Background: ${message.notification?.title} - ${message.notification?.body}');
    debugPrint('FCM Data: ${message.data}');
    
    // Handle deep linking based on notification data
    _handleDeepLink(message.data);
  }
  
  static void _handleDeepLink(Map<String, dynamic> data) {
    final type = data['type'];
    final profileId = data['profile_id'];
    
    // Navigation will be handled by the app router
    // This is just a placeholder - actual navigation happens in the UI layer
    debugPrint('Deep link: type=$type, profileId=$profileId');
  }
  
  static void _createNotificationChannel() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'transit_alerts',
        'Transit Alerts',
        description: 'Notifications for planetary transits, Sade Sati, and Dasha changes',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );
      
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
  
  /// Subscribe to a topic (e.g., per-profile transit alerts)
  static Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }
  
  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }
  
  /// Get current FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
  
  /// Delete FCM token (on logout)
  static Future<void> deleteToken() async {
    await _messaging.deleteToken();
    debugPrint('FCM token deleted');
  }
}

/// Provider for FCM token callback
final fcmTokenCallbackProvider = Provider<void Function(String)?>((ref) {
  return (token) async {
    // This will be implemented to call the auth repository
    debugPrint('FCM token callback: $token');
  };
});