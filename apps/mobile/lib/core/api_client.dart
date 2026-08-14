/// Grahvani — Shared Dio HTTP Client
/// Singleton with Firebase JWT bearer token injection and JSON envelope unwrapping.
library;

import 'dart:io' show HttpClient, Platform, X509Certificate;
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves the default API base URL depending on platform.
/// - Web / Windows Desktop: http://localhost:8000
/// - Android Emulator: http://10.0.2.2:8000
String get defaultApiBaseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  if (envUrl.isNotEmpty) return envUrl;

  if (kIsWeb) {
    return 'http://localhost:8000';
  }

  try {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
  } catch (_) {}

  return 'http://localhost:8000';
}

/// Dio singleton provider — shared across all repository classes.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: defaultApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // OWASP Hardening: Strictly reject bad certificates on native platforms
  if (!kIsWeb) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => false;
        return client;
      },
    );
  }

  // Intercept every request: attach a fresh Firebase ID token as Bearer token.
  dio.interceptors.add(_FirebaseAuthInterceptor());

  // Unwrap the standard { "success": true, "data": {...} } response envelope.
  dio.interceptors.add(_EnvelopeInterceptor());

  return dio;
});

/// Injects the current Firebase user's ID token into the Authorization header.
/// Automatically refreshes expired tokens before each request.
class _FirebaseAuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken(false);
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final freshToken = await user.getIdToken(true);
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $freshToken';
          final retryResponse = await Dio().fetch(opts);
          handler.resolve(retryResponse);
          return;
        }
      } catch (_) {}
    }
    handler.next(err);
  }
}

/// Unwraps `{ "success": true, "data": <payload> }` envelopes automatically.
/// Converts API errors (`{ "success": false, "error": {...} }`) into DioExceptions.
class _EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final data = response.data;

    if (data is Map && data.containsKey('success')) {
      if (data['success'] == true) {
        response.data = data['data'];
      } else {
        final error = data['error'] is Map ? data['error'] as Map : {};
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            type: DioExceptionType.badResponse,
            message: error['message'] as String? ?? 'Unknown API error',
            error: error,
          ),
        );
        return;
      }
    }

    handler.next(response);
  }
}

/// Typed API exception extracted from the Grahvani error envelope.
class ApiException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  const ApiException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  factory ApiException.fromDioException(DioException e) {
    final response = e.response;
    final errorBody = response?.data;
    if (errorBody is Map<String, dynamic> && errorBody.containsKey('error')) {
      final err = errorBody['error'] as Map<String, dynamic>;
      return ApiException(
        code: err['code'] as String? ?? 'UNKNOWN',
        message: err['message'] as String? ?? e.message ?? 'Request failed',
        statusCode: response?.statusCode ?? 0,
      );
    }
    return ApiException(
      code: 'NETWORK_ERROR',
      message: e.message ?? 'Network error',
      statusCode: response?.statusCode ?? 0,
    );
  }

  bool get isEntitlementError => code == 'ENTITLEMENT_REQUIRED';
  bool get isAuthError => code == 'AUTHENTICATION_ERROR';

  @override
  String toString() => 'ApiException($code): $message';
}
