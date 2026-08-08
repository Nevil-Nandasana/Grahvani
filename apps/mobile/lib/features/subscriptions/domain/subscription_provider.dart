/// Subscriptions Domain — Riverpod provider for entitlements
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../data/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>(
  (ref) => SubscriptionRepository(dio: ref.watch(apiClientProvider)),
);

final entitlementsProvider = FutureProvider<Entitlements>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getEntitlements();
});
