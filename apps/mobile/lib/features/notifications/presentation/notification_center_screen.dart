/// Notification Center Screen — Full History List
/// Displays chronological push notification history with mark-as-read,
/// swipe-to-dismiss, deep-link navigation, and unread badge.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/notification_model.dart';

// ─── Notification History StateNotifier ───────────────────────────────────────
// In production this would persist to Drift/Hive; here uses in-memory state.

class _NotificationHistoryNotifier extends StateNotifier<List<PushNotification>> {
  _NotificationHistoryNotifier() : super(_mockHistory());

  static List<PushNotification> _mockHistory() {
    final now = DateTime.now();
    return [
      PushNotification(
        id: '1',
        profileId: 'default',
        profileName: 'Primary Profile',
        type: NotificationType.sadeSati,
        title: 'Sade Sati Phase Alert',
        body:
            'Saturn has entered Aquarius. Your Sade Sati second phase begins today. Expect introspection and discipline.',
        data: const {'phase': 'second_phase'},
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      PushNotification(
        id: '2',
        profileId: 'default',
        profileName: 'Primary Profile',
        type: NotificationType.dashaTransition,
        title: 'Dasha Transition in 14 Days',
        body:
            'Your Jupiter Maha Dasha ends in 14 days. Prepare for the Saturn Maha Dasha transition.',
        data: const {'fromPlanet': 'Jupiter', 'toPlanet': 'Saturn'},
        timestamp: now.subtract(const Duration(hours: 18)),
        isRead: true,
      ),
      PushNotification(
        id: '3',
        profileId: 'default',
        profileName: 'Primary Profile',
        type: NotificationType.majorTransit,
        title: 'Jupiter Enters Taurus',
        body:
            'Jupiter transits into Taurus, aspecting your 7th house of partnerships. Favorable for relationships.',
        data: const {'planet': 'Jupiter', 'sign': 'Taurus'},
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
      PushNotification(
        id: '4',
        profileId: 'default',
        profileName: 'Primary Profile',
        type: NotificationType.dashaTransition,
        title: 'Antar Dasha Change',
        body:
            'Your Venus Antar Dasha within Jupiter Maha Dasha has begun. Venus rules beauty, art, and relationships.',
        data: const {'planet': 'Venus', 'type': 'antar_change'},
        timestamp: now.subtract(const Duration(days: 5)),
        isRead: true,
      ),
      PushNotification(
        id: '5',
        profileId: 'default',
        profileName: 'Primary Profile',
        type: NotificationType.majorTransit,
        title: 'Mars Transit Alert',
        body:
            'Mars transits over your natal Moon. Emotional intensity is high — channel energy constructively.',
        data: const {'planet': 'Mars'},
        timestamp: now.subtract(const Duration(days: 9)),
        isRead: true,
      ),
    ];
  }

  void markAsRead(String id) {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void dismiss(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() => state = [];
}

final notificationHistoryProvider =
    StateNotifierProvider<_NotificationHistoryNotifier, List<PushNotification>>(
  (_) => _NotificationHistoryNotifier(),
);

// ─── Screen ───────────────────────────────────────────────────────────────────

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  static const routeName = '/notifications/center';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationHistoryProvider);
    final notifier = ref.read(notificationHistoryProvider.notifier);
    final unread = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6EFA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Color(0xFF7C6EFA), fontSize: 12),
              ),
            ),
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              color: const Color(0xFF16163A),
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              onSelected: (value) {
                if (value == 'clear') notifier.clearAll();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep,
                          color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Clear all',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _EmptyState()
          : ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notifications[i];
                return _NotificationCard(
                  notification: n,
                  onTap: () {
                    notifier.markAsRead(n.id);
                    _deepLink(context, n);
                  },
                  onDismiss: () => notifier.dismiss(n.id),
                );
              },
            ),
    );
  }

  void _deepLink(BuildContext context, PushNotification n) {
    switch (n.type) {
      case NotificationType.sadeSati:
        context.push('/home/sade-sati/${n.profileId}');
        break;
      case NotificationType.dashaTransition:
      case NotificationType.majorTransit:
        context.push('/home/charts/${n.profileId}');
        break;
      case NotificationType.test:
        break;
    }
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final PushNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  static const _meta = {
    NotificationType.sadeSati: ('🪐', Color(0xFF87CEEB), 'SADE SATI'),
    NotificationType.dashaTransition: ('⏳', Color(0xFFFFD700), 'DASHA'),
    NotificationType.majorTransit: ('🌟', Color(0xFF64FF8A), 'TRANSIT'),
    NotificationType.test: ('🔔', Color(0xFF9B93CC), 'TEST'),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) =
        _meta[notification.type] ?? ('🔔', const Color(0xFF9B93CC), 'ALERT');
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.redAccent),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnread
                ? const Color(0xFF12122A)
                : const Color(0xFF0E0E20),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread
                  ? color.withOpacity(0.4)
                  : const Color(0xFF1A1A30),
              width: isUnread ? 1.2 : 1,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.08),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color:
                                  isUnread ? Colors.white : Colors.white70,
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin:
                                const EdgeInsets.only(left: 6, top: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        color: Color(0xFF6B6B99),
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(label,
                            style: TextStyle(
                              color: color.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            )),
                        const SizedBox(width: 6),
                        Text(
                          '• ${_timeAgo(notification.timestamp)}',
                          style: const TextStyle(
                            color: Color(0xFF4A4A6A),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF5B4FDB).withOpacity(0.1),
            ),
            child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'All caught up!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Planetary alerts and dasha transitions\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF6B6B99), fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}