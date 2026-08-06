/// Subscriptions Domain — Riverpod provider for entitlements
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/subscription_repository.dart';

part 'subscription_provider.g.dart';

@riverpod
Future<Entitlements> entitlements(Ref ref) async {
  return ref.read(subscriptionRepositoryProvider).getEntitlements();
}
