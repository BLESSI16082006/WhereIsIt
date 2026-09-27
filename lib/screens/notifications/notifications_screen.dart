import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  final NotificationService _notificationService =
      NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: _notificationService.getUserNotifications(),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];

              final hasUnread = notifications.any(
                (notification) => !notification.isRead,
              );

              if (!hasUnread) {
                return const SizedBox.shrink();
              }

              return TextButton(
                onPressed: () async {
                  try {
                    await _notificationService.markAllAsRead();
                  } catch (_) {
                    // Keep the notification screen usable even if
                    // marking notifications as read fails.
                  }
                },
                child: const Text(
                  'Mark all read',
                ),
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotifications(),

        builder: (context, snapshot) {
          // ----------------------------------------------------
          // LOADING
          // ----------------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ----------------------------------------------------
          // ERROR
          // ----------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 60,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please try again later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<NotificationModel> notifications =
              snapshot.data ?? [];

          // ----------------------------------------------------
          // EMPTY NOTIFICATIONS
          // ----------------------------------------------------

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // ----------------------------------------------------
          // NOTIFICATION LIST
          // ----------------------------------------------------

          return RefreshIndicator(
            onRefresh: () async {
              // Firestore StreamBuilder updates automatically.
              // This small delay gives RefreshIndicator a smooth
              // pull-to-refresh experience.
              await Future<void>.delayed(
                const Duration(milliseconds: 400),
              );
            },

            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24,
              ),

              itemCount: notifications.length,

              separatorBuilder: (context, index) {
                return const SizedBox(height: 10);
              },

              itemBuilder: (context, index) {
                final NotificationModel notification =
                    notifications[index];

                return _NotificationCard(
                  notification: notification,
                  onTap: () async {
                    if (!notification.isRead) {
                      await _notificationService.markAsRead(
                        notification.notificationId,
                      );
                    }

                    // ------------------------------------------------
                    // IMPORTANT:
                    // No navigation happens here.
                    //
                    // Tapping a notification only marks it as read.
                    // ------------------------------------------------
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No notifications yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Important updates about your account,\n'
              'items, and recoveries will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// NOTIFICATION CARD
// =================================================================

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor =
        _getNotificationColor(notification.type);

    final IconData icon =
        _getNotificationIcon(notification.type);

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,

        borderRadius: BorderRadius.circular(16),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : Colors.teal.withValues(alpha: 0.06),

            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.shade200
                  : Colors.teal.withValues(alpha: 0.25),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ----------------------------------------------------
              // ICON
              // ----------------------------------------------------

              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color: iconColor,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              // ----------------------------------------------------
              // CONTENT
              // ----------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                            ),
                          ),
                        ),

                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(
                              top: 5,
                              left: 8,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.teal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _formatDateTime(
                        notification.createdAt,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
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

  // ------------------------------------------------------------
  // NOTIFICATION ICON
  // ------------------------------------------------------------

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'account_created':
        return Icons.person_add_alt_1_rounded;

      case 'item_confirmation':
        return Icons.inventory_2_outlined;

      case 'recovery_confirmation':
        return Icons.handshake_outlined;

      case 'recovery_waiting':
        return Icons.hourglass_empty_rounded;

      case 'recovery_success':
        return Icons.check_circle_outline_rounded;

      case 'ownership_verification':
        return Icons.verified_outlined;

      default:
        return Icons.notifications_outlined;
    }
  }

  // ------------------------------------------------------------
  // NOTIFICATION COLOR
  // ------------------------------------------------------------

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'account_created':
        return Colors.blue;

      case 'item_confirmation':
        return Colors.orange;

      case 'recovery_confirmation':
        return Colors.deepPurple;

      case 'recovery_waiting':
        return Colors.amber.shade800;

      case 'recovery_success':
        return Colors.green;

      case 'ownership_verification':
        return Colors.teal;

      default:
        return Colors.blueGrey;
    }
  }

  // ------------------------------------------------------------
  // DATE/TIME FORMAT
  // ------------------------------------------------------------

  String _formatDateTime(DateTime dateTime) {
    final DateTime now = DateTime.now();

    final Duration difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final int minutes = difference.inMinutes;

      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    if (difference.inHours < 24) {
      final int hours = difference.inHours;

      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    final String day =
        dateTime.day.toString().padLeft(2, '0');

    final String month =
        dateTime.month.toString().padLeft(2, '0');

    final String year =
        dateTime.year.toString();

    return '$day/$month/$year';
  }
}