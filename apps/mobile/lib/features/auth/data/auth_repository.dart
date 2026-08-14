/// Auth Data Layer — Firebase Auth + Backend Token Verification
library;

import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:grahvani/core/api_client.dart';

class PhoneAuthSession {
  final String? verificationId;
  final ConfirmationResult? confirmationResult;
  final int? resendToken;

  const PhoneAuthSession({
    this.verificationId,
    this.confirmationResult,
    this.resendToken,
  });

  bool get isWeb => confirmationResult != null;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(dio: ref.watch(apiClientProvider)),
);

class AuthRepository {
  AuthRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// In-memory flag: null = unknown (not yet fetched), false = no consent,
  /// true = consent already given. Drives router redirect without extra calls.
  final ValueNotifier<bool?> consentStateNotifier = ValueNotifier<bool?>(null);

  /// Update FCM Push Notification token on backend
  Future<void> updateFcmToken(String token) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/notifications/fcm-token',
        data: {'fcm_token': token},
      );
    } catch (_) {}
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────

  /// Sign in with Google OAuth2 → Firebase credential → backend verify-token.
  Future<Map<String, dynamic>> signInWithGoogle() async {
    UserCredential userCredential;
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      userCredential = await _firebaseAuth.signInWithPopup(googleProvider);
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign-In cancelled.');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      userCredential = await _firebaseAuth.signInWithCredential(credential);
    }
    return _verifyWithBackend(userCredential);
  }

  /// Send Phone OTP — supports native Android/iOS (verifyPhoneNumber) and Web (signInWithPhoneNumber).
  Future<PhoneAuthSession> sendPhoneOtp(String phoneNumber) async {
    if (kIsWeb) {
      final confirmationResult =
          await _firebaseAuth.signInWithPhoneNumber(phoneNumber);
      return PhoneAuthSession(confirmationResult: confirmationResult);
    } else {
      final completer = Completer<PhoneAuthSession>();

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential =
                await _firebaseAuth.signInWithCredential(credential);
            await _verifyWithBackend(userCredential);
          } catch (_) {}
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!completer.isCompleted) {
            completer.complete(PhoneAuthSession(
              verificationId: verificationId,
              resendToken: resendToken,
            ));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      return completer.future;
    }
  }

  /// Verify OTP code — Firebase Phone Auth step 2.
  Future<Map<String, dynamic>> verifyPhoneOtp(
    PhoneAuthSession session,
    String smsCode,
  ) async {
    UserCredential userCredential;
    if (session.isWeb) {
      userCredential = await session.confirmationResult!.confirm(smsCode);
    } else {
      final credential = PhoneAuthProvider.credential(
        verificationId: session.verificationId!,
        smsCode: smsCode,
      );
      userCredential = await _firebaseAuth.signInWithCredential(credential);
    }
    return _verifyWithBackend(userCredential);
  }

  /// Verify current session with backend on startup.
  /// Caches consent state from response.
  Future<void> checkCurrentUserSession() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      consentStateNotifier.value = null;
      return;
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/verify-token',
      );
      final data = response.data ?? {};
      final userData = data['data'] as Map<String, dynamic>? ?? {};
      consentStateNotifier.value = userData['consent_given_at'] != null;
    } catch (_) {
      // If network is offline or unverified, fallback to true so app doesn't hang
      consentStateNotifier.value = true;
    }
  }

  /// Call backend /auth/verify-token to create or retrieve the user record.
  /// Caches consent state from the response so the router can redirect
  /// to the consent screen without an additional round-trip.
  Future<Map<String, dynamic>> _verifyWithBackend(
    UserCredential credential,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/verify-token',
      );
      final data = response.data ?? {};

      // Cache consent state from the verify-token response.
      final userData = data['data'] as Map<String, dynamic>? ?? {};
      consentStateNotifier.value = userData['consent_given_at'] != null;

      return data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Consent (DPDP Act 2023) ──────────────────────────────────────────────

  /// Record explicit consent to the backend.
  /// Idempotent: safe to call even if consent was already given.
  /// Updates [consentStateNotifier] to `true` on success.
  Future<void> grantConsent({String consentVersion = '1.0'}) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/api/v1/auth/consent',
        data: {'consent_version': consentVersion},
      );
      consentStateNotifier.value = true;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    consentStateNotifier.value = null; // Reset consent cache on logout.
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ─── Current User ─────────────────────────────────────────────────────────

  User? get currentFirebaseUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
