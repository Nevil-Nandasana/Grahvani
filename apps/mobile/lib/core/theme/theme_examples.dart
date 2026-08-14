/// Grahvani Theme Application Examples
/// This file shows practical examples of how to use the theme throughout the app
library;

import 'package:flutter/material.dart';
import 'app_colors.dart';

// ============================================================================
// EXAMPLE 1: Basic Button Usage
// ============================================================================

class ButtonExamples extends StatelessWidget {
  const ButtonExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary Button (uses theme automatically)
        ElevatedButton(
          onPressed: () {},
          child: const Text('Primary Button'),
        ),

        // Customized Primary Button with AppColors
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBurgundy,
            foregroundColor: AppColors.lightBgWhite,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          onPressed: () {},
          child: const Text('Custom Primary'),
        ),

        // Secondary Button with Rose color
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.rose100,
            foregroundColor: AppColors.primaryBurgundy,
          ),
          onPressed: () {},
          child: const Text('Secondary Button'),
        ),

        // Outlined Button
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primaryBurgundy, width: 2),
            foregroundColor: AppColors.primaryBurgundy,
          ),
          onPressed: () {},
          child: const Text('Outlined Button'),
        ),

        // Text Button
        TextButton(
          onPressed: () {},
          child: const Text('Text Button'),
        ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 2: Card Styling
// ============================================================================

class CardExamples extends StatelessWidget {
  const CardExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Basic Card (uses theme)
        Card(
          child: ListTile(
            title: const Text('Basic Card'),
            subtitle: const Text('Uses theme colors automatically'),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {},
            ),
          ),
        ),

        // Premium Card with Gold accent
        Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.gold, width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.goldLighter,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: AppColors.goldDark,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Premium Feature',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'This is a premium card with gold accent',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),

        // AI Feature Card
        Card(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientAI,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.lightBgWhite,
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  'AI-Powered Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.lightBgWhite,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get intelligent astrology interpretations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightBgWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 3: Input Fields
// ============================================================================

class InputFieldExamples extends StatelessWidget {
  const InputFieldExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Basic Text Field (uses theme)
        TextField(
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
            prefixIcon: const Icon(Icons.person),
          ),
        ),

        // Email Field with custom styling
        TextField(
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'your@email.com',
            prefixIcon: const Icon(Icons.email),
            filled: true,
            fillColor: AppColors.lightBgSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.rose300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.primaryBurgundy,
                width: 2,
              ),
            ),
          ),
        ),

        // Search Field with rose accent
        TextField(
          decoration: InputDecoration(
            hintText: 'Search charts...',
            prefixIcon: Icon(Icons.search, color: AppColors.primaryBurgundy),
            filled: true,
            fillColor: AppColors.lightBgSecondary,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.rose300),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 4: Text Styling
// ============================================================================

class TextStylingExamples extends StatelessWidget {
  const TextStylingExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Using theme text styles
          Text(
            'Headline Large',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text(
            'Headline Medium',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            'Title Large',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            'Body Large',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            'Body Medium',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            'Body Small',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Label Large',
            style: Theme.of(context).textTheme.labelLarge,
          ),

          const SizedBox(height: 20),

          // Custom colored text
          Text(
            'Primary Text',
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 16,
            ),
          ),
          Text(
            'Secondary Text',
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
          Text(
            'Muted Text',
            style: TextStyle(
              color: AppColors.textMutedLight,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),

          // Rich text with multiple colors
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Burgundy ',
                  style: TextStyle(
                    color: AppColors.primaryBurgundy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'Rose ',
                  style: TextStyle(color: AppColors.rose100),
                ),
                TextSpan(
                  text: 'Gold ',
                  style: TextStyle(color: AppColors.gold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Background Colors
// ============================================================================

class BackgroundColorExamples extends StatelessWidget {
  const BackgroundColorExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Light Mode Backgrounds
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.lightBg,
            child: const Text('Main Light Background (#FCF5EE)'),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.lightBgSecondary,
            child: const Text('Secondary Light Background (#FFF9F5)'),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.lightBgRose,
            child: const Text('Rose Light Background (#FFF2F3)'),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.lightBgWhite,
            child: const Text('White Background (#FFFFFF)'),
          ),

          const SizedBox(height: 20),

          // Dark Mode Backgrounds
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.darkBg,
            child: Text(
              'Main Dark Background (#18070E)',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.darkBgPrimary,
            child: Text(
              'Primary Dark Surface (#250914)',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.darkBgSecondary,
            child: Text(
              'Secondary Dark Surface (#350B1B)',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.darkBgElevated,
            child: Text(
              'Elevated Dark Surface (#421126)',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 6: Gradients
// ============================================================================

class GradientExamples extends StatelessWidget {
  const GradientExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary Gradient
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientPrimary,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Primary Gradient\nBurgundy → Rose',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.lightBgWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Deep Burgundy Gradient
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientDeepBurgundy,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Deep Burgundy Gradient\nDarkest → Main',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.lightBgWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Rose Gradient
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientRose,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Rose Gradient\nRose100 → Rose300',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primaryBurgundy,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // AI Gradient
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientAI,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'AI Gradient\nPurple → Deep Purple',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.lightBgWhite,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Gold Gradient
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradientGold,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'Gold Gradient\nDark → Light',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.darkBg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 7: Status/Semantic Colors
// ============================================================================

class SemanticColorExamples extends StatelessWidget {
  const SemanticColorExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Success
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            border: Border.all(color: AppColors.success),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Success: Your profile has been updated',
                  style: TextStyle(color: AppColors.success),
                ),
              ),
            ],
          ),
        ),

        // Warning
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            border: Border.all(color: AppColors.warning),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: AppColors.warning),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Warning: Your trial expires soon',
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
            ],
          ),
        ),

        // Error
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            border: Border.all(color: AppColors.error),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.error, color: AppColors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Error: Failed to load charts',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),

        // Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            border: Border.all(color: AppColors.info),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: AppColors.info),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Info: New astrology features available',
                  style: TextStyle(color: AppColors.info),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 8: Icon Coloring
// ============================================================================

class IconColoringExamples extends StatelessWidget {
  const IconColoringExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          children: [
            Icon(Icons.star, color: AppColors.primaryBurgundy, size: 32),
            const SizedBox(height: 8),
            const Text('Primary'),
          ],
        ),
        Column(
          children: [
            Icon(Icons.favorite, color: AppColors.rose100, size: 32),
            const SizedBox(height: 8),
            const Text('Rose'),
          ],
        ),
        Column(
          children: [
            Icon(Icons.diamond, color: AppColors.gold, size: 32),
            const SizedBox(height: 8),
            const Text('Gold'),
          ],
        ),
        Column(
          children: [
            Icon(Icons.auto_awesome, color: AppColors.aiSecondary, size: 32),
            const SizedBox(height: 8),
            const Text('AI'),
          ],
        ),
        Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(height: 8),
            const Text('Success'),
          ],
        ),
        Column(
          children: [
            Icon(Icons.warning, color: AppColors.warning, size: 32),
            const SizedBox(height: 8),
            const Text('Warning'),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// EXAMPLE 9: Complex Layout with Multiple Colors
// ============================================================================

class AstrologyCardExample extends StatelessWidget {
  const AstrologyCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.lightBgWhite, AppColors.lightBgRose],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: AppColors.rose300.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gold accent
            Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kundali Milan',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(color: AppColors.primaryBurgundy),
                      ),
                      Text(
                        'Compatibility Analysis',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.goldLighter,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '85%',
                    style: TextStyle(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Content
            Text(
              'Your compatibility score based on detailed astrological analysis',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('View Details'),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 10: Dark Mode Example
// ============================================================================

class DarkModeExample extends StatelessWidget {
  const DarkModeExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dark Mode Examples',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: AppColors.textPrimaryDark),
          ),
          const SizedBox(height: 16),
          // Card in dark mode
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkBgPrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.darkBgStrong,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode Card',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This card uses dark burgundy surfaces instead of generic black',
                  style: TextStyle(color: AppColors.textSecondaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Dark mode button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBurgundy,
              ),
              onPressed: () {},
              child: const Text('Dark Mode Button'),
            ),
          ),
        ],
      ),
    );
  }
}
