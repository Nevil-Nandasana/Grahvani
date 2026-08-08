/// Notification Provider - State Management
/// Manages notification preferences, FCM token, and notification state

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grahvani/core/api_client.dart';
import 'package:grahvani/features/notifications/data/fcm_service.dart';
import 'package:grahvani/features/notifications/data/notification_repository.dart';
import 'package:grahvani/features/notifications/domain/notification_model.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(dio: ref.watch(apiClientProvider)),
);

// ─── FCM Token State ─────────────────────────────────────────────────────────
final fcmTokenProvider = StateProvider<String?>((ref) => null);

// ─── Notification Preferences Provider ───────────────────────────────────────
class NotificationPreferencesNotifier extends StateNotifier<AsyncValue<ProfileNotificationStatus>> {
  NotificationPreferencesNotifier(this._repository) : super(const AsyncValue.loading());

  final NotificationRepository _repository;

  Future<void> loadPreferences(String profileId) async {
    state = const AsyncValue.loading();
    try {
      final status = await _repository.getNotificationPreferences(profileId);
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePreferences(
    String profileId,
    NotificationPreferences preferences,
  ) async {
    state = const AsyncValue.loading();
    try {
      final status = await _repository.updateNotificationPreferences(profileId, preferences);
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleNotifications(String profileId) async {
    state = const AsyncValue.loading();
    try {
      final status = await _repository.toggleNotifications(profileId);
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendTestNotification(String profileId) async {
    try {
      await _repository.sendTestNotification(profileId);
    } catch (e) {
      rethrow;
    }
  }
}

final notificationPreferencesProvider = StateNotifierProvider.autoDispose
    .family<NotificationPreferencesNotifier, AsyncValue<ProfileNotificationStatus>, String>(
  (ref, profileId) {
    final repository = ref.watch(notificationRepositoryProvider);
    final notifier = NotificationPreferencesNotifier(repository);
    notifier.loadPreferences(profileId);
    return notifier;
  },
);

// ─── Sade Sati Status Provider ───────────────────────────────────────────────
class SadeSatiStatusNotifier extends StateNotifier<AsyncValue<SadeSatiInfo>> {
  SadeSatiStatusNotifier() : super(const AsyncValue.loading());

  Future<void> calculateSadeSati({
    required String moonSign,
    required String saturnSign,
  }) async {
    state = const AsyncValue.loading();
    try {
      // This would ideally be a backend call, but for now we calculate locally
      final isActive = _isSaturnInSadeSati(moonSign, saturnSign);
      final phase = isActive ? _getSadeSatiPhase(moonSign, saturnSign) : null;
      
      final info = SadeSatiInfo(
        isActive: isActive,
        phase: phase ?? '',
        moonSign: moonSign,
        saturnSign: saturnSign,
        description: isActive ? _getSadeSatiPhaseDescription(phase!) : '',
      );
      
      state = AsyncValue.data(info);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  bool _isSaturnInSadeSati(String moonSign, String saturnSign) {
    const zodiacOrder = [
      'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
      'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
    ];
    
    final moonIdx = zodiacOrder.indexOf(moonSign);
    final saturnIdx = zodiacOrder.indexOf(saturnSign);
    
    if (moonIdx == -1 || saturnIdx == -1) return false;
    
    final diff = (saturnIdx - moonIdx) % 12;
    return diff == 11 || diff == 0 || diff == 1;
  }

  String? _getSadeSatiPhase(String moonSign, String saturnSign) {
    const zodiacOrder = [
      'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo',
      'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'
    ];
    
    final moonIdx = zodiacOrder.indexOf(moonSign);
    final saturnIdx = zodiacOrder.indexOf(saturnSign);
    
    if (moonIdx == -1 || saturnIdx == -1) return null;
    
    final diff = (saturnIdx - moonIdx) % 12;
    if (diff == 11) return 'first_phase';
    if (diff == 0) return 'second_phase';
    if (diff == 1) return 'third_phase';
    return null;
  }

  String _getSadeSatiPhaseDescription(String phase) {
    switch (phase) {
      case 'first_phase':
        return 'Saturn is transiting the 12th house from your Moon sign. This is the first phase of Sade Sati — a time of preparation and inner work.';
      case 'second_phase':
        return 'Saturn is transiting directly over your Moon sign. This is the peak phase of Sade Sati — intense transformation and karmic lessons.';
      case 'third_phase':
        return 'Saturn is transiting the 2nd house from your Moon sign. This is the final phase of Sade Sati — integration and harvesting results.';
      default:
        return '';
    }
  }
}

final sadeSatiStatusProvider = StateNotifierProvider.autoDispose<SadeSatiStatusNotifier, AsyncValue<SadeSatiInfo>>(
  (ref) => SadeSatiStatusNotifier(),
);

// ─── Dasha Transition Provider ───────────────────────────────────────────────
class DashaTransitionNotifier extends StateNotifier<AsyncValue<DashaTransitionInfo?>> {
  DashaTransitionNotifier() : super(const AsyncValue.loading());

  Future<void> checkDashaTransitions(String profileId) async {
    state = const AsyncValue.loading();
    // This would call the backend API
    // For now, return null
    state = const AsyncValue.data(null);
  }
}

final dashaTransitionProvider = StateNotifierProvider.autoDispose
    .family<DashaTransitionNotifier, AsyncValue<DashaTransitionInfo?>, String>(
  (ref, profileId) => DashaTransitionNotifier(),
);

// ─── FCM Initialization Provider ─────────────────────────────────────────────
final fcmInitializedProvider = FutureProvider<void>((ref) async {
  await FCMService.initialize();
  
  // Set up token callback
  FCMService.onTokenRefresh = (token) {
    ref.read(fcmTokenProvider.notifier).state = token;
    // Send token to backend
    // This will be handled by the auth repository
  };
});