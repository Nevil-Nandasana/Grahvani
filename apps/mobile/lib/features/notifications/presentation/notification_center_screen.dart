/// Notification Center Screen
/// UI for viewing and managing in-app notifications

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grahvani/core/theme/app_theme.dart';
import 'package:grahvani/features/notifications/domain/notification_model.dart';
import 'package:grahvani/features/notifications/domain/notification_provider.dart';
import 'package:grahvani/shared/widgets/empty_state.dart';
import 'package:grahvani/shared/widgets/loading_indicator.dart';
import 'package:intl/intl.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  static const routeName = '/notifications/center';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Placeholder - would use a real notification history provider
    final notifications = <PushNotification>[]; // Would come from provider
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_all_read),
            onPressed: () => _markAllRead(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateToSettings(context),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off,
              title: 'No Notifications',
              subtitle: 'You have no notifications yet',
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) => _buildNotificationItem(
                context,
                notifications[index],
              ),
            ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, PushNotification notification) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, h:mm a');
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(color: Colors.red.withOpacity(0.1)),
      onDismissed: (direction) => _dismissNotification(context, notification),
      child: ListTile(
        leading: _getNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(notification.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _handleNotificationTap(context, notification),
      ),
    );
  }

  Widget _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.sadeSati:
        return const Icon(Icons.warning_amber, color: Colors.orange);
      case NotificationType.dashaTransition:
        return const Icon(Icons.autorenew, color: Colors.blue);
      case NotificationType.majorTransit:
        return const Icon(Icons.star, color: Colors.purple);
      case NotificationType.test:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  void _handleNotificationTap(BuildContext context, PushNotification notification) {
    // Handle deep linking based on notification type
    switch (notification.type) {
      case NotificationType.sadeSati:
        // Navigate to Sade Sati detail screen
        Navigator.pushNamed(
          context,
          '/chart/sade-sati',
          arguments: notification.profileId,
        );
        break;
      case NotificationType.dashaTransition:
        // Navigate to Dasha detail screen
        Navigator.pushNamed(
          context,
          '/chart/dasha',
          arguments: notification.profileId,
        );
        break;
      case NotificationType.majorTransit:
        // Navigate to transit detail screen
        Navigator.pushNamed(
          context,
          '/chart/transits',
          arguments: notification.profileId,
        );
        break;
      case NotificationType.test:
        // Just show a snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test notification: ${notification.body}'),
          ),
        );
        break;
    }
  }

  void _dismissNotification(BuildContext context, PushNotification notification) {
    // Would call a provider to remove the notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification dismissed: ${notification.title}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _markAllRead(BuildContext context) {
    // Would call a provider to mark all as read
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    // Navigate to notification settings
    // Would need to pass the current profile
    Navigator.pushNamed(context, '/notifications/settings');
  }
}

// Placeholder for notification history provider
final notificationHistoryProvider = FutureProvider.autoDispose<List<PushNotification>>((ref) async {
  // Would fetch from repository
  return [];
});