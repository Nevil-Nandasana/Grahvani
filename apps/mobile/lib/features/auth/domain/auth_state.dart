/// Auth Domain — Riverpod AsyncNotifier for authentication state
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/auth_repository.dart';

part 'auth_state.g.dart';

/// Watches Firebase Auth state stream. Null = unauthenticated.
@riverpod
Stream<User?> authStateStream(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

/// Notifier for performing auth actions (sign in / sign out).
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signOut(),
    );
  }

  /// Phone OTP step 1 — returns ConfirmationResult stored locally.
  Future<ConfirmationResult?> sendPhoneOtp(String phone) async {
    state = const AsyncLoading();
    ConfirmationResult? result;
    state = await AsyncValue.guard(() async {
      result = await ref.read(authRepositoryProvider).sendPhoneOtp(phone);
    });
    return result;
  }

  /// Phone OTP step 2 — verify SMS code.
  Future<void> verifyOtp(ConfirmationResult confirmationResult, String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).verifyPhoneOtp(confirmationResult, code),
    );
  }
}
