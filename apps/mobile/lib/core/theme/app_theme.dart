import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppTheme {
  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F4FA),
        primaryColor: const Color(0xFF7C6EFA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6EFA),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        primaryColor: const Color(0xFF7C6EFA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6EFA),
          brightness: Brightness.dark,
          surface: const Color(0xFF0A0A1A),
        ),
        useMaterial3: true,
      );

  ThemeMode get themeMode => ThemeMode.dark;
}

final themeProvider = Provider<AppTheme>((ref) => AppTheme());
