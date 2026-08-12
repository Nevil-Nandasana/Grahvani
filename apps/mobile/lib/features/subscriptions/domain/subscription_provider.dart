/// Subscriptions Domain — Riverpod provider for entitlements & trial management
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../data/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(dio: ref.watch(apiClientProvider)),
);

class EntitlementsNotifier extends StateNotifier<AsyncValue<Entitlements>> {
  EntitlementsNotifier(this._repository) : super(const AsyncValue.loading()) {
    fetchEntitlements();
  }

  final SubscriptionRepository _repository;

  Future<void> fetchEntitlements() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getEntitlements());
  }

  /// Activates 7-day free trial and refreshes entitlement state on success.
  Future<TrialActivationResult> activateTrial() async {
    try {
      final result = await _repository.activateTrial();
      await fetchEntitlements();
      return result;
    } catch (e) {
      rethrow;
    }
  }
}

final entitlementsNotifierProvider =
    StateNotifierProvider<EntitlementsNotifier, AsyncValue<Entitlements>>((ref) {
  return EntitlementsNotifier(ref.watch(subscriptionRepositoryProvider));
});

/// Convenience provider for reading current entitlements state
final entitlementsProvider = Provider<AsyncValue<Entitlements>>((ref) {
  return ref.watch(entitlementsNotifierProvider);
});
