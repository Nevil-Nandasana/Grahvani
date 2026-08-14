import 'dart:io' show Platform, exit;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freerasp/freerasp.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grahvani/core/theme/app_theme.dart';
import 'package:grahvani/features/notifications/data/fcm_service.dart';
import 'package:grahvani/firebase_options.dart';
import 'package:grahvani/router/app_router.dart';

Future<void> initSecurityGuard() async {
  if (kIsWeb) return;
  try {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final config = TalsecConfig(
      androidConfig: AndroidConfig(
        packageName: 'com.grahvani.app',
        signingCertHashes: ['dummy_cert_hash_placeholder'],
      ),
      iosConfig: IOSConfig(
        bundleIds: ['com.grahvani.app'],
        teamId: 'dummy_team_id',
      ),
      watcherMail: 'security@grahvani.app',
      isProd: true,
    );

    final callback = ThreatCallback(
      onAppIntegrity: () => exit(0),
      onObfuscationIssues: () => exit(0),
      onDebug: () => exit(0),
      onDeviceBinding: () => exit(0),
      onDeviceID: () => exit(0),
      onHooks: () => exit(0),
      onPrivilegedAccess: () => exit(0),
      onSecureHardwareNotAvailable: () => exit(0),
      onSimulator: () => exit(0),
      onUnofficialStore: () => exit(0),
    );

    Talsec.instance.attachListener(callback);
    await Talsec.instance.start(config);
  } catch (_) {
    // Gracefully handle security guard init failures on non-mobile platforms
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  // Initialize OWASP Hardening Threat Detector on Mobile platforms
  if (!kIsWeb) {
    await initSecurityGuard();
  }

  // Initialize FCM Push Notifications
  try {
    await FCMService.initialize();
  } catch (_) {}

  runApp(const ProviderScope(child: GrahvaniApp()));
}

class GrahvaniApp extends ConsumerWidget {
  const GrahvaniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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