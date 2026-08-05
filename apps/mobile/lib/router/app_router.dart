import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

// ─── Route Paths ──────────────────────────────────────────────────────────────
class AppRoutes {
  static const splash    = '/';
  static const login     = '/login';
  static const home      = '/home';
  static const profiles  = '/profiles';
  static const addProfile = '/profiles/add';
  static const chart     = '/charts/:chartId';
  static const chat      = '/chat/:sessionId';
  static const settings  = '/settings';
}

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'profiles',
            builder: (context, state) => const ProfilesScreen(),
          ),
          GoRoute(
            path: 'profiles/add',
            builder: (context, state) => const AddProfileScreen(),
          ),
          GoRoute(
            path: 'charts/:chartId',
            builder: (context, state) => ChartScreen(chartId: state.pathParameters['chartId']!),
          ),
          GoRoute(
            path: 'chat/:sessionId',
            builder: (context, state) => ChatScreen(sessionId: state.pathParameters['sessionId']!),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
}

// ─── Placeholder Screens (to be replaced with actual feature screens) ─────────

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0D0D1A),
    body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🪐', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 16),
        Text('Grahvani', style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          color: Colors.white, fontWeight: FontWeight.bold,
        )),
        const SizedBox(height: 8),
        Text('Vedic Astrology, Precisely.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.white60,
        )),
      ]),
    ),
  );
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Login Screen')));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Home Dashboard')));
}

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('My Profiles')));
}

class AddProfileScreen extends StatelessWidget {
  const AddProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Add Birth Profile')));
}

class ChartScreen extends StatelessWidget {
  final String chartId;
  const ChartScreen({super.key, required this.chartId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Chart: $chartId')));
}

class ChatScreen extends StatelessWidget {
  final String sessionId;
  const ChatScreen({super.key, required this.sessionId});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text('Chat: $sessionId')));
}
