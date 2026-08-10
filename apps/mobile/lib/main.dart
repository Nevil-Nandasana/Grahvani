import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:freerasp/freerasp.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grahvani/core/api_client.dart';
import 'package:grahvani/core/database/app_database.dart';
import 'package:grahvani/core/theme/app_theme.dart';
import 'package:grahvani/features/auth/data/auth_repository.dart';
import 'package:grahvani/features/auth/domain/auth_provider.dart';
import 'package:grahvani/features/notifications/data/fcm_service.dart';
import 'package:grahvani/features/notifications/domain/notification_provider.dart';
import 'package:grahvani/firebase_options.dart';
import 'package:grahvani/router/app_router.dart';

Future<void> initSecurityGuard() async {
  // FreeRASP App setup for production
  final config = TalsecConfig(
    androidConfig: AndroidConfig(
      packageName: 'com.grahvani.app',
      signingCertHashes: ['dummy_cert_hash_placeholder'], // Update before prod deploy
      supportedAlternativeStores: ['com.sec.android.app.samsungapps'],
    ),
    iosConfig: IOSConfig(
      bundleIds: ['com.grahvani.app'],
      teamId: 'dummy_team_id', // Update before prod deploy
    ),
    watcherMail: 'security@grahvani.app',
    isProd: true, // enforce strict checks
  );

  // Callbacks to kill app if threat is detected
  final callback = ThreatCallback(
    onAppIntegrity: () => exit(0),
    onObfuscationIssues: () => exit(0),
    onDebug: () => exit(0),
    onDeviceBinding: () => exit(0),
    onDeviceID: () => exit(0),
    onHooks: () => exit(0),
    onPasscodeValidation: () => exit(0),
    onPrivilegedAccess: () => exit(0), // Root/Jailbreak
    onSecureHardwareNotAvailable: () => exit(0),
    onSimulator: () => exit(0),
    onUnofficialStore: () => exit(0),
  );

  Talsec.instance.attachListener(callback);
  await Talsec.instance.start(config);
}

Future<void> main() async {
  final ref = ProviderContainer();
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize OWASP Hardening Threat Detector
    await initSecurityGuard();

    // Initialize FCM
    await FCMService.initialize();

    // Initialize database
    await ref.read(databaseProvider).initialize();

    // Initialize auth state
    ref.read(authProvider.notifier).initialize();

    // Set up FCM token callback
    FCMService.onTokenRefresh = (token) {
      ref.read(authRepositoryProvider).updateFcmToken(token);
    };

    runApp(const ProviderScope(child: GrahvaniApp()));
  } finally {
    ref.dispose();
  }


class GrahvaniApp extends ConsumerWidget {
  const GrahvaniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    
    // OWASP Hardening: Block screenshots and screen recording on Android
    if (Platform.isAndroid) {
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
    
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'Grahvani',
      theme: theme.lightTheme,
      darkTheme: theme.darkTheme,
      themeMode: theme.themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}