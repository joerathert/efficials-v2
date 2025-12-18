import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

/// Screen displaying all notifications for the scheduler
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      _currentUserId = _authService.currentUser?.uid;
      if (_currentUserId == null) {
        debugPrint('⚠️ NOTIFICATIONS: No authenticated user found');
        setState(() => _isLoading = false);
        return;
      }

      // Fetch all notifications for the current user
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('timestamp', descending: true)
          .get();

      final notifications = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'id': doc.id,
        };
      }).toList();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      debugPrint(
          '✅ NOTIFICATIONS: Loaded ${notifications.length} notifications');
    } catch (e) {
      debugPrint('🔴 NOTIFICATIONS: Error loading notifications: $e');
      // Try without orderBy in case index doesn't exist
      try {
        final querySnapshot = await _firestore
            .collection('notifications')
            .where('userId', isEqualTo: _currentUserId)
            .get();

        final notifications = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            ...data,
            'id': doc.id,
          };
        }).toList();

        // Sort in memory
        notifications.sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      } catch (e2) {
        debugPrint('🔴 NOTIFICATIONS: Fallback also failed: $e2');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('🔴 NOTIFICATIONS: Error marking as read: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;

    // Mark as read
    if (notification['id'] != null) {
      _markAsRead(notification['id']);
    }

    switch (type) {
      case 'official_backed_out':
        // Navigate to backout notifications screen
        Navigator.pushNamed(context, '/backout-notifications').then((_) {
          _loadNotifications(); // Refresh when returning
        });
        break;
      case 'game_removed':
        // Could navigate to a game details or just show info
        _showNotificationDetails(notification);
        break;
      case 'backout_excused':
        // Show info about the excused backout
        _showNotificationDetails(notification);
        break;
      default:
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          notification['title'] ?? 'Notification',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          notification['message'] ?? '',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = notification['title'] ?? 'Notification';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Notification',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$title"? This action cannot be undone.',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final notificationId = notification['id'];
              if (notificationId != null) {
                _deleteNotification(notificationId);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllReadConfirmation() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final readCount = _notifications
        .where((notification) => notification['isRead'] == true)
        .length;

    if (readCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No read notifications to delete'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete All Read Notifications',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all $readCount read notification${readCount == 1 ? '' : 's'}? This action cannot be undone.',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAllReadNotifications();
            },
            child:
                const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    _markAllAsRead();
                    break;
                  case 'delete_all_read':
                    _showDeleteAllReadConfirmation();
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Delete all read'),
                    ],
                  ),
                ),
              ],
              icon: Icon(
                Icons.more_vert,
                color: colorScheme.onSurface,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : _notifications.isEmpty
              ? _buildEmptyState(colorScheme)
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: colorScheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationTile(notification, colorScheme);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
      Map<String, dynamic> notification, ColorScheme colorScheme) {
    final type = notification['type'] as String?;
    final title = notification['title'] as String? ?? 'Notification';
    final isRead = notification['isRead'] as bool? ?? false;
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    // Format timestamp
    String timeAgo = '';
    if (notification['timestamp'] != null &&
        notification['timestamp'] is Timestamp) {
      final timestamp = (notification['timestamp'] as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes}m ago';
      } else {
        timeAgo = 'Just now';
      }
    }

    // Get display info based on type
    IconData icon;
    Color iconColor;
    String displayMessage;

    switch (type) {
      case 'official_backed_out':
        icon = Icons.person_remove;
        iconColor = Colors.red;
        final officialName = data['officialName'] ?? 'An official';
        displayMessage = '$officialName backed out of a game.';
        break;
      case 'game_removed':
        icon = Icons.event_busy;
        iconColor = Colors.orange;
        displayMessage = 'A game has been removed from the schedule.';
        break;
      case 'backout_excused':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        displayMessage = 'Your backout was excused.';
        break;
      default:
        icon = Icons.notifications;
        iconColor = colorScheme.primary;
        displayMessage = notification['message'] ?? title;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: isRead ? colorScheme.surface : colorScheme.surfaceVariant,
      elevation: isRead ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead
            ? BorderSide.none
            : BorderSide(color: iconColor.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: iconColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.7),
                              ),
                              onPressed: () =>
                                  _showDeleteConfirmation(notification),
                              tooltip: 'Delete notification',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                        if (type == 'official_backed_out') ...[
                          const Spacer(),
                          Text(
                            'Tap to view details',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: colorScheme.primary,
                          ),
                        ],
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

  Future<void> _markAllAsRead() async {
    try {
      final batch = _firestore.batch();

      for (final notification in _notifications) {
        if (notification['isRead'] != true && notification['id'] != null) {
          final docRef =
              _firestore.collection('notifications').doc(notification['id']);
          batch.update(docRef, {'isRead': true});
        }
      }

      await batch.commit();
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications marked as read'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 NOTIFICATIONS: Error marking all as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      setState(() {
        _notifications.removeWhere(
            (notification) => notification['id'] == notificationId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 NOTIFICATIONS: Error deleting notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAllReadNotifications() async {
    try {
      final readNotifications = _notifications
          .where((notification) =>
              notification['isRead'] == true && notification['id'] != null)
          .toList();

      if (readNotifications.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No read notifications to delete'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final batch = _firestore.batch();
      for (final notification in readNotifications) {
        final docRef =
            _firestore.collection('notifications').doc(notification['id']);
        batch.delete(docRef);
      }

      await batch.commit();
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Deleted ${readNotifications.length} read notification${readNotifications.length == 1 ? '' : 's'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 NOTIFICATIONS: Error deleting all read notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
