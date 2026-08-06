import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

Future<void> main() async {
  final ref = ProviderContainer();
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize FCM
    await FCMService.initialize();

    // Initialize API client
    await ref.read(apiClientProvider).initialize();

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