/// FCM Service for Push Notifications
/// Handles Firebase Cloud Messaging integration

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  /// Initialize FCM - request permissions, get token, set up handlers
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Request permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: Permission granted');
      } else {
        debugPrint('FCM: Permission status: ${settings.authorizationStatus}');
      }
      
      // Get FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
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
    } catch (e) {
      debugPrint('FCM initialization error: $e');
    }
  }
  
  static void _sendTokenToBackend(String token) {
    FCMService.onTokenRefresh?.call(token);
  }
  
  // Callback for token refresh - set by provider
  static void Function(String)? onTokenRefresh;
  
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM Foreground: ${message.notification?.title} - ${message.notification?.body}');
  }
  
  static void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('FCM Background: ${message.notification?.title} - ${message.notification?.body}');
    _handleDeepLink(message.data);
  }
  
  static void _handleDeepLink(Map<String, dynamic> data) {
    final type = data['type'];
    final profileId = data['profile_id'];
    debugPrint('Deep link: type=$type, profileId=$profileId');
  }
  
  static void _createNotificationChannel() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
  
  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('FCM subscribe error: $e');
    }
  }
  
  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('FCM unsubscribe error: $e');
    }
  }
  
  /// Get current FCM token
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      return null;
    }
  }
  
  /// Delete FCM token (on logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('FCM delete token error: $e');
    }
  }
}

/// Provider for FCM token callback
final fcmTokenCallbackProvider = Provider<void Function(String)?>((ref) {
  return (token) async {
    debugPrint('FCM token callback: $token');
  };
});