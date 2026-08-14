import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';

class AppTheme {
  // LIGHT THEME
  ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.lightBg,
        primaryColor: AppColors.primaryBurgundy,
        
        // Color Scheme
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryBurgundy,
          onPrimary: AppColors.lightBgWhite,
          primaryContainer: AppColors.rose400,
          onPrimaryContainer: AppColors.primaryBurgundy,
          secondary: AppColors.rose100,
          onSecondary: AppColors.lightBgWhite,
          secondaryContainer: AppColors.rose300,
          onSecondaryContainer: AppColors.primaryBurgundyDark,
          tertiary: AppColors.gold,
          onTertiary: AppColors.lightBgWhite,
          tertiaryContainer: AppColors.goldLighter,
          onTertiaryContainer: AppColors.goldDark,
          error: AppColors.error,
          onError: AppColors.lightBgWhite,
          errorContainer: AppColors.error.withOpacity(0.1),
          onErrorContainer: AppColors.error,
          surface: AppColors.lightBgWhite,
          onSurface: AppColors.textPrimaryLight,
          surfaceContainerHighest: AppColors.lightBgSecondary,
          outline: AppColors.rose300.withOpacity(0.5),
          outlineVariant: AppColors.primaryBurgundy.withOpacity(0.2),
        ),
        
        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightBgWhite,
          foregroundColor: AppColors.textPrimaryLight,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Button Themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBurgundy,
            foregroundColor: AppColors.lightBgWhite,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBurgundy,
            side: const BorderSide(color: AppColors.primaryBurgundy, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBurgundy,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        // Card Theme
        cardTheme: CardThemeData(
          color: AppColors.lightBgWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero,
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightBgSecondary,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.rose300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.rose300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryBurgundy, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: TextStyle(color: AppColors.textSecondaryLight),
          hintStyle: TextStyle(color: AppColors.textMutedLight),
        ),
        
        // Text Theme
        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          displaySmall: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: AppColors.textMutedLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: AppColors.textMutedLight,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // DARK THEME
  ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.darkBg,
        primaryColor: AppColors.primaryBurgundy,
        
        // Color Scheme
        colorScheme: ColorScheme.dark(
          primary: AppColors.primaryBurgundy,
          onPrimary: AppColors.lightBgWhite,
          primaryContainer: AppColors.primaryBurgundyDark,
          onPrimaryContainer: AppColors.rose100,
          secondary: AppColors.rose100,
          onSecondary: AppColors.darkBg,
          secondaryContainer: AppColors.rose200,
          onSecondaryContainer: AppColors.rose100,
          tertiary: AppColors.goldLight,
          onTertiary: AppColors.darkBg,
          tertiaryContainer: AppColors.goldDark,
          onTertiaryContainer: AppColors.goldLight,
          error: AppColors.error,
          onError: AppColors.darkBg,
          errorContainer: AppColors.error.withOpacity(0.2),
          onErrorContainer: AppColors.error,
          surface: AppColors.darkBgPrimary,
          onSurface: AppColors.textPrimaryDark,
          surfaceContainerHighest: AppColors.darkBgSecondary,
          outline: AppColors.darkBgStrong,
          outlineVariant: AppColors.primaryBurgundy.withOpacity(0.3),
        ),
        
        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkBgPrimary,
          foregroundColor: AppColors.textPrimaryDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Button Themes
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBurgundy,
            foregroundColor: AppColors.lightBgWhite,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBurgundy,
            side: const BorderSide(color: AppColors.primaryBurgundy, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryBurgundy,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        // Card Theme
        cardTheme: CardThemeData(
          color: AppColors.darkBgPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.zero,
        ),
        
        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkBgElevated,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkBgStrong, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.darkBgStrong, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primaryBurgundy, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          labelStyle: TextStyle(color: AppColors.textSecondaryDark),
          hintStyle: TextStyle(color: AppColors.textMutedDark),
        ),
        
        // Text Theme
        textTheme: TextTheme(
          displayLarge: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
          displayMedium: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          displaySmall: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          headlineLarge: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          headlineSmall: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: AppColors.textMutedDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: AppColors.textMutedDark,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          labelLarge: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  ThemeMode get themeMode => ThemeMode.dark;
}

final themeProvider = Provider<AppTheme>((ref) => AppTheme());
