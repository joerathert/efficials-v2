import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of notifications
enum NotificationType {
  gameCanceled,
  gameDeleted,
  gameUpdated,
  gameAssigned,
  gameUnassigned,
  crewInvitation,
  general
}

/// Notification model for user notifications
class NotificationModel {
  /// Format a phone number to (###) ###-#### format
  static String _formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';

    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Check if we have exactly 10 digits (US phone number)
    if (digitsOnly.length == 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }

    // If not 10 digits, return as-is but cleaned
    return digitsOnly;
  }
  final String id;
  final String userId; // The user who should receive this notification
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data; // Additional data like game info, scheduler contact, etc.
  final DateTime createdAt;
  final bool isRead;
  final String? gameId; // Reference to related game if applicable
  final String? schedulerId; // Reference to scheduler who triggered the notification

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.createdAt,
    this.isRead = false,
    this.gameId,
    this.schedulerId,
  });

  /// Create a notification for game cancellation
  factory NotificationModel.gameCanceled({
    required String id,
    required String userId,
    required String gameTitle,
    required String schedulerName,
    required String schedulerEmail,
    required String schedulerPhone,
    String? gameId,
    String? schedulerId,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: NotificationType.gameCanceled,
      title: 'Game Canceled',
      message: 'This game has been canceled by $schedulerName.',
      data: {
        'gameTitle': gameTitle,
        'schedulerName': schedulerName,
        'schedulerEmail': schedulerEmail,
        'schedulerPhone': schedulerPhone,
        'contactInfo': 'Email: $schedulerEmail\nPhone: ${_formatPhoneNumber(schedulerPhone)}',
      },
      createdAt: DateTime.now(),
      gameId: gameId,
      schedulerId: schedulerId,
    );
  }

  /// Create a notification for game deletion
  factory NotificationModel.gameDeleted({
    required String id,
    required String userId,
    required String gameTitle,
    required String schedulerName,
    required String schedulerEmail,
    required String schedulerPhone,
    String? gameId,
    String? schedulerId,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      type: NotificationType.gameDeleted,
      title: 'Game Deleted',
      message: 'This game has been deleted by $schedulerName.',
      data: {
        'gameTitle': gameTitle,
        'schedulerName': schedulerName,
        'schedulerEmail': schedulerEmail,
        'schedulerPhone': schedulerPhone,
        'contactInfo': 'Email: $schedulerEmail\nPhone: ${_formatPhoneNumber(schedulerPhone)}',
      },
      createdAt: DateTime.now(),
      gameId: gameId,
      schedulerId: schedulerId,
    );
  }

  /// Create a notification for game updates
  factory NotificationModel.gameUpdated({
    required String id,
    required String userId,
    required String gameTitle,
    required String schedulerName,
    required String schedulerEmail,
    required String schedulerPhone,
    required List<String> changes,
    String? gameId,
    String? schedulerId,
  }) {
    final changesText = changes.join(', ');
    return NotificationModel(
      id: id,
      userId: userId,
      type: NotificationType.gameUpdated,
      title: 'Game Updated',
      message: 'This game has been updated by $schedulerName. Changes: $changesText.',
      data: {
        'gameTitle': gameTitle,
        'schedulerName': schedulerName,
        'schedulerEmail': schedulerEmail,
        'schedulerPhone': schedulerPhone,
        'changes': changes,
        'contactInfo': 'Email: $schedulerEmail\nPhone: ${_formatPhoneNumber(schedulerPhone)}',
      },
      createdAt: DateTime.now(),
      gameId: gameId,
      schedulerId: schedulerId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last, // Store as string
      'title': title,
      'message': message,
      'data': data,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'gameId': gameId,
      'schedulerId': schedulerId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    // Parse the type string back to enum
    NotificationType type;
    switch (map['type']) {
      case 'gameCanceled':
        type = NotificationType.gameCanceled;
        break;
      case 'gameDeleted':
        type = NotificationType.gameDeleted;
        break;
      case 'gameUpdated':
        type = NotificationType.gameUpdated;
        break;
      case 'gameAssigned':
        type = NotificationType.gameAssigned;
        break;
      case 'gameUnassigned':
        type = NotificationType.gameUnassigned;
        break;
      case 'crewInvitation':
        type = NotificationType.crewInvitation;
        break;
      default:
        type = NotificationType.general;
    }

    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: type,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      data: map['data'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      gameId: map['gameId'],
      schedulerId: map['schedulerId'],
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    bool? isRead,
    String? gameId,
    String? schedulerId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      gameId: gameId ?? this.gameId,
      schedulerId: schedulerId ?? this.schedulerId,
    );
  }

  /// Get the contact information for display
  String get contactInfo {
    if (data?['contactInfo'] != null) {
      return data!['contactInfo'] as String;
    }
    return '';
  }

  /// Get the scheduler name
  String get schedulerName {
    if (data?['schedulerName'] != null) {
      return data!['schedulerName'] as String;
    }
    return 'Scheduler';
  }
}
