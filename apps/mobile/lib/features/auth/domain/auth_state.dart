/// Auth Domain — Riverpod AsyncNotifier for authentication state
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

/// Watches Firebase Auth state stream. Null = unauthenticated.
final authStateStreamProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Notifier for performing auth actions (sign in / sign out).
class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  AuthNotifier(this._repository) : super(const AsyncData(null));

  final AuthRepository _repository;

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signInWithGoogle(),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signOut(),
    );
  }

  /// Phone OTP step 1 — returns ConfirmationResult stored locally.
  Future<ConfirmationResult?> sendPhoneOtp(String phone) async {
    state = const AsyncLoading();
    ConfirmationResult? result;
    state = await AsyncValue.guard(() async {
      result = await _repository.sendPhoneOtp(phone);
    });
    return result;
  }

  /// Phone OTP step 2 — verify SMS code.
  Future<void> verifyOtp(ConfirmationResult confirmationResult, String code) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.verifyPhoneOtp(confirmationResult, code),
    );
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
