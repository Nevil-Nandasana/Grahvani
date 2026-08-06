/// Notification Settings Screen
/// UI for managing notification preferences per profile

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grahvani/core/theme/app_theme.dart';
import 'package:grahvani/features/notifications/domain/notification_model.dart';
import 'package:grahvani/features/notifications/domain/notification_provider.dart';
import 'package:grahvani/features/profile/domain/profile_model.dart';
import 'package:grahvani/shared/widgets/loading_indicator.dart';
import 'package:grahvani/shared/widgets/switch_tile.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key, required this.profile});

  final BirthProfile profile;
  static const routeName = '/notifications/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preferencesAsync = ref.watch(
      notificationPreferencesProvider(profile.id),
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications for ${profile.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: preferencesAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error', style: theme.textTheme.bodyMedium),
        ),
        data: (status) => _buildSettings(context, ref, status),
      ),
    );
  }

  Widget _buildSettings(
    BuildContext context,
    WidgetRef ref,
    ProfileNotificationStatus status,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(
      notificationPreferencesProvider(profile.id).notifier,
    );
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Master toggle
        Card(
          child: SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Turn on/off all notifications for this profile'),
            value: status.notificationEnabled,
            onChanged: (value) => notifier.toggleNotifications(profile.id),
          ),
        ),
        const SizedBox(height: 16),
        
        // Notification types
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Types',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPreferenceSwitch(
                  context,
                  ref,
                  title: 'Transit Alerts',
                  subtitle: 'General planetary transit notifications',
                  value: status.preferences.transitAlerts,
                  onChanged: (value) => notifier.updatePreferences(
                    profile.id,
                    status.preferences.copyWith(transitAlerts: value),
                  ),
                ),
                _buildPreferenceSwitch(
                  context,
                  ref,
                  title: 'Sade Sati Alerts',
                  subtitle: 'Saturn transit phases (7.5 year cycle)',
                  value: status.preferences.sadeSatiAlerts,
                  onChanged: (value) => notifier.updatePreferences(
                    profile.id,
                    status.preferences.copyWith(sadeSatiAlerts: value),
                  ),
                ),
                _buildPreferenceSwitch(
                  context,
                  ref,
                  title: 'Dasha Alerts',
                  subtitle: 'Maha Dasha changes and transitions',
                  value: status.preferences.dashaAlerts,
                  onChanged: (value) => notifier.updatePreferences(
                    profile.id,
                    status.preferences.copyWith(dashaAlerts: value),
                  ),
                ),
                _buildPreferenceSwitch(
                  context,
                  ref,
                  title: 'Major Transit Alerts',
                  subtitle: 'Jupiter returns, Rahu/Ketu transits',
                  value: status.preferences.majorTransitAlerts,
                  onChanged: (value) => notifier.updatePreferences(
                    profile.id,
                    status.preferences.copyWith(majorTransitAlerts: value),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Quiet hours
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiet Hours',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Notifications will be silenced during these hours',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePicker(
                        context,
                        label: 'Start Time',
                        value: status.preferences.quietHoursStart,
                        onChanged: (value) => notifier.updatePreferences(
                          profile.id,
                          status.preferences.copyWith(quietHoursStart: value),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimePicker(
                        context,
                        label: 'End Time',
                        value: status.preferences.quietHoursEnd,
                        onChanged: (value) => notifier.updatePreferences(
                          profile.id,
                          status.preferences.copyWith(quietHoursEnd: value),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Test notification
        Card(
          child: ListTile(
            title: const Text('Send Test Notification'),
            subtitle: const Text('Verify your notification setup'),
            trailing: const Icon(Icons.send, size: 20),
            onTap: () => _sendTestNotification(context, ref),
          ),
        ),
        const SizedBox(height: 16),
        
        // Sade Sati status
        _buildSadeSatiStatus(context, ref),
      ],
    );
  }

  Widget _buildPreferenceSwitch(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchTile(
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                hour: int.parse(value.split(':')[0]),
                minute: int.parse(value.split(':')[1]),
              ),
            );
            if (time != null) {
              onChanged('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
            }
          },
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildSadeSatiStatus(BuildContext context, WidgetRef ref) {
    final sadeSatiAsync = ref.watch(sadeSatiStatusProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sade Sati Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            sadeSatiAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Text('Error: $error'),
              data: (info) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (info.isActive) ...[
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Sade Sati Active: ${info.phase.replaceAll('_', ' ').titleCase}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(info.description),
                    const SizedBox(height: 12),
                    Text(
                      'Moon Sign: ${info.moonSign}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Saturn in: ${info.saturnSign}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'No Active Sade Sati',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Saturn is not currently in a Sade Sati phase for this profile.'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendTestNotification(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(
      notificationPreferencesProvider(profile.id).notifier,
    );
    
    try {
      await notifier.sendTestNotification(profile.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification sent! Check your device.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test notification: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sade Sati is a 7.5-year period when Saturn transits through the 12th, 1st, and 2nd houses from your Moon sign. It brings challenges and growth opportunities.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Transit Alerts: General planetary movements'),
              Text('• Sade Sati Alerts: Saturn transit phases'),
              Text('• Dasha Alerts: Maha Dasha changes'),
              Text('• Quiet Hours: Silence notifications overnight'),
              SizedBox(height: 12),
              Text(
                'Note: Notifications are sent daily at 6 AM IST if enabled.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String get titleCase =>
      split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
}