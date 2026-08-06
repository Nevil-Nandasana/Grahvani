/// Grahvani — App Router
/// Wires all feature screens to go_router routes with Firebase auth guard.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/consent_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/chart/presentation/chart_screen.dart';
import '../features/chart/presentation/kundali_milan_screen.dart';
import '../features/chart/presentation/sade_sati_screen.dart';
import '../features/chart/presentation/synastry_screen.dart';
import '../features/chart/presentation/varshaphal_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/chat/presentation/voice_qa_screen.dart';
import '../features/notifications/presentation/notification_center_screen.dart';
import '../features/notifications/presentation/notification_settings_screen.dart';
import '../features/profile/presentation/add_profile_screen.dart';
import '../features/profile/presentation/profiles_screen.dart';
import '../features/subscriptions/presentation/paywall_sheet.dart';
import '../features/auth/data/auth_repository.dart';

part 'app_router.g.dart';

// ─── Route Paths ──────────────────────────────────────────────────────────────────────────────
class AppRoutes {
  static const splash               = '/';
  static const login                = '/login';
  static const consent              = '/consent';
  static const home                 = '/home';
  static const profiles             = '/home/profiles';
  static const addProfile           = '/home/profiles/add';
  static const chart                = '/home/charts/:chartId';
  static const chat                 = '/home/chat/:chartId';
  static const sadeSati             = '/home/sade-sati/:profileId';
  static const notificationSettings = '/home/notifications/settings/:profileId';
  static const notificationCenter   = '/home/notifications/center';
  static const kundaliMilan         = '/home/kundali-milan';
  static const varshaphal           = '/home/varshaphal/:profileId';
  static const synastry             = '/home/synastry';
  static const voiceQA              = '/home/voice-qa/:chartId';
}

@riverpod
GoRouter appRouter(Ref ref) {
  // Listen to Firebase auth state for redirect guard.
  final authNotifier = ValueNotifier<User?>(
    FirebaseAuth.instance.currentUser,
  );
  FirebaseAuth.instance.authStateChanges().listen((user) {
    authNotifier.value = user;
  });

  // Listen to consent state changes from repository.
  final consentNotifier = ref.read(authRepositoryProvider).consentStateNotifier;

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: Listenable.merge([authNotifier, consentNotifier]),

    // ── Auth Redirect Guard ──────────────────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final String loc = state.matchedLocation;
      
      // Consent state from backend cache (null = unknown, false = no consent, true = consent given)
      final bool? hasConsent = consentNotifier.value;

      if (loc == AppRoutes.splash) {
        if (!isLoggedIn) return AppRoutes.login;
        if (hasConsent == false) return AppRoutes.consent;
        if (hasConsent == true) return AppRoutes.home;
        return null; // Stay on splash while loading/verifying
      }

      if (!isLoggedIn && loc != AppRoutes.login) {
        return AppRoutes.login;
      }

      if (isLoggedIn) {
        if (loc == AppRoutes.login) {
          return (hasConsent == true) ? AppRoutes.home : AppRoutes.consent;
        }
        
        // If logged in, but backend returned consent_given_at=null, force consent gate
        if (hasConsent == false && loc != AppRoutes.consent) {
          return AppRoutes.consent;
        }
      }

      return null; // No redirect
    },

    routes: <RouteBase>[
      // ── Splash ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const _SplashScreen(),
      ),

      // ── Login ───────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      
      // ── Consent ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.consent,
        builder: (context, state) => const ConsentScreen(),
      ),

      // ── Home (shell with nested routes) ────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _HomeScreen(),
        routes: [
          // Birth Profiles
          GoRoute(
            path: 'profiles',
            builder: (BuildContext context, GoRouterState state) =>
                const ProfilesScreen(),
          ),
          GoRoute(
            path: 'profiles/add',
            builder: (BuildContext context, GoRouterState state) =>
                const AddProfileScreen(),
          ),

          // Birth Chart (uses profileId to trigger/load chart)
          GoRoute(
            path: 'charts/:chartId',
            builder: (BuildContext context, GoRouterState state) =>
                ChartScreen(
                  chartId: state.pathParameters['chartId']!,
                ),
          ),

          // AI Chat (chartId passed to create a session)
          GoRoute(
            path: 'chat/:chartId',
            builder: (BuildContext context, GoRouterState state) {
              final String chartId = state.pathParameters['chartId']!;
              return ChatScreen(chartId: chartId);
            },
          ),

          // Sade Sati Tracker
          GoRoute(
            path: 'sade-sati/:profileId',
            builder: (BuildContext context, GoRouterState state) {
              final String profileId = state.pathParameters['profileId']!;
              return SadeSatiScreen(profileId: profileId);
            },
          ),

          // Notification Settings
          GoRoute(
            path: 'notifications/settings/:profileId',
            builder: (BuildContext context, GoRouterState state) {
              final String profileId = state.pathParameters['profileId']!;
              return NotificationSettingsScreen(profileId: profileId);
            },
          ),

          // Notification Center History
          GoRoute(
            path: 'notifications/center',
            builder: (BuildContext context, GoRouterState state) =>
                const NotificationCenterScreen(),
          ),

          // Kundali Milan Matchmaking
          GoRoute(
            path: 'kundali-milan',
            builder: (BuildContext context, GoRouterState state) =>
                const KundaliMilanScreen(),
          ),

          // Varshaphal (Solar Return)
          GoRoute(
            path: 'varshaphal/:profileId',
            builder: (BuildContext context, GoRouterState state) {
              final String profileId = state.pathParameters['profileId']!;
              return VarshaphalScreen(profileId: profileId);
            },
          ),

          // Synastry Dual-Chart Overlay
          GoRoute(
            path: 'synastry',
            builder: (BuildContext context, GoRouterState state) =>
                const SynastryScreen(),
          ),

          // Voice AI Q&A
          GoRoute(
            path: 'voice-qa/:chartId',
            builder: (BuildContext context, GoRouterState state) {
              final String chartId = state.pathParameters['chartId']!;
              return VoiceQAScreen(chartId: chartId);
            },
          ),

          // Paywall (presented as a full-screen sheet)
          GoRoute(
            path: 'upgrade',
            builder: (BuildContext context, GoRouterState state) =>
                const _PaywallPage(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌑', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: const TextStyle(color: Color(0xFF6B6B99), fontSize: 12),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Splash Screen ─────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF7C6EFA), Color(0xFF3B2FBE)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B4FDB).withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: const Center(
                  child: Text('🪐', style: TextStyle(fontSize: 38)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Grahvani',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vedic Astrology, Precisely.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF7C6EFA),
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── Home Dashboard ─────────────────────────────────────────────────────────

class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        title: const Row(
          children: [
            Text('🪐', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text(
              'Grahvani',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Color(0xFF9B93CC)),
            tooltip: 'Notification Center',
            onPressed: () => context.push('/home/notifications/center'),
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium, color: Color(0xFF7C6EFA)),
            tooltip: 'Upgrade',
            onPressed: () => context.push('/home/upgrade'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your Vedic birth chart awaits.',
                style: TextStyle(color: Color(0xFF6B6B99)),
              ),
              const SizedBox(height: 32),
              _HomeCard(
                icon: '🌙',
                title: 'Birth Profiles',
                subtitle: 'Manage and view saved charts',
                onTap: () => context.push('/home/profiles'),
              ),
              const SizedBox(height: 14),
              _HomeCard(
                icon: '💬',
                title: 'AI Interpretation',
                subtitle: 'Chat with Grahvani AI',
                onTap: () => context.push('/home/profiles'),
              ),
              const SizedBox(height: 14),
              _HomeCard(
                icon: '❤️',
                title: 'Kundali Milan',
                subtitle: 'Ashtakoot compatibility matching',
                onTap: () => context.push('/home/kundali-milan'),
              ),
              const SizedBox(height: 14),
              _HomeCard(
                icon: '🔭',
                title: 'Synastry',
                subtitle: 'Dual-chart aspect overlay',
                onTap: () => context.push('/home/synastry'),
              ),
              const SizedBox(height: 14),
              _HomeCard(
                icon: '☀️',
                title: 'Varshaphal',
                subtitle: 'Annual Solar Return chart',
                onTap: () => context.push('/home/profiles'),
              ),
              const SizedBox(height: 14),
              _HomeCard(
                icon: '⭐',
                title: 'Upgrade to Premium',
                subtitle: '100 daily AI interpretations',
                highlight: true,
                onTap: () => PaywallSheet.show(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: highlight
              ? const LinearGradient(
                  colors: [Color(0xFF3B2FBE), Color(0xFF5B4FDB)],
                )
              : null,
          color: highlight ? null : const Color(0xFF12122A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: highlight
                ? const Color(0xFF7C6EFA)
                : const Color(0xFF2A2A4A),
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF9B93CC), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF3D3266)),
          ],
        ),
      ),
    );
  }
}

// ─── Paywall Wrapper Page ──────────────────────────────────────────────────

class _PaywallPage extends StatelessWidget {
  const _PaywallPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            const Expanded(child: PaywallSheet()),
          ],
        ),
      ),
    );
  }
}
