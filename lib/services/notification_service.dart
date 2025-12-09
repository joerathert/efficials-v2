import '../models/notification_model.dart';
import '../constants/firebase_constants.dart';
import 'base_service.dart';

class NotificationService extends BaseService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  NotificationService._internal();
  factory NotificationService() => _instance;

  /// Create a notification for game cancellation/deletion
  Future<bool> notifyGameCancellation({
    required String gameId,
    required String schedulerId,
    required List<String> officialIds,
    required bool isDeletion, // true for deletion, false for cancellation
  }) async {
    try {
      debugPrint('🔔 NOTIFICATION SERVICE: Creating ${isDeletion ? 'deletion' : 'cancellation'} notifications for game $gameId, scheduler $schedulerId, officials $officialIds');

      // Get game details
      final gameDoc = await firestore.collection(FirebaseCollections.games).doc(gameId).get();
      if (!gameDoc.exists) {
        debugPrint('❌ NOTIFICATION SERVICE: Game $gameId not found');
        return false;
      }

      final gameData = gameDoc.data()!;
      final gameTitle = _formatGameTitle(gameData);

      // Get scheduler details
      final schedulerDoc = await firestore.collection(FirebaseCollections.users).doc(schedulerId).get();
      if (!schedulerDoc.exists) {
        debugPrint('❌ NOTIFICATION SERVICE: Scheduler $schedulerId not found');
        return false;
      }

      final schedulerData = schedulerDoc.data()!;
      final schedulerProfile = schedulerData['profile'] as Map<String, dynamic>? ?? {};
      final schedulerName = '${schedulerProfile['firstName'] ?? 'Scheduler'} ${schedulerProfile['lastName'] ?? ''}'.trim();
      final schedulerEmail = schedulerData['email'] ?? '';
      final schedulerPhone = schedulerProfile['phone'] ?? '';

      // Create notifications for each confirmed official
      final batch = firestore.batch();
      final notificationIds = <String>[];

      for (final officialId in officialIds) {
        final notificationId = '${gameId}_${officialId}_${DateTime.now().millisecondsSinceEpoch}';
        notificationIds.add(notificationId);

        final notification = isDeletion
            ? NotificationModel.gameDeleted(
                id: notificationId,
                userId: officialId,
                gameTitle: gameTitle,
                schedulerName: schedulerName,
                schedulerEmail: schedulerEmail,
                schedulerPhone: schedulerPhone,
                gameId: gameId,
                schedulerId: schedulerId,
              )
            : NotificationModel.gameCanceled(
                id: notificationId,
                userId: officialId,
                gameTitle: gameTitle,
                schedulerName: schedulerName,
                schedulerEmail: schedulerEmail,
                schedulerPhone: schedulerPhone,
                gameId: gameId,
                schedulerId: schedulerId,
              );

        debugPrint('📝 NOTIFICATION SERVICE: Creating notification $notificationId for user $officialId');
        final notificationRef = firestore.collection(FirebaseCollections.notifications).doc(notificationId);
        batch.set(notificationRef, notification.toMap());
      }

      debugPrint('💾 NOTIFICATION SERVICE: Committing batch with ${notificationIds.length} notifications');
      await batch.commit();
      debugPrint('✅ NOTIFICATION SERVICE: Batch committed successfully');

      // Verify notifications were created
      for (final notificationId in notificationIds) {
        final doc = await firestore.collection(FirebaseCollections.notifications).doc(notificationId).get();
        if (doc.exists) {
          debugPrint('✅ NOTIFICATION SERVICE: Verified notification $notificationId exists in Firestore');
        } else {
          debugPrint('❌ NOTIFICATION SERVICE: Notification $notificationId NOT found in Firestore after creation!');
        }
      }

      debugPrint('✅ NOTIFICATION SERVICE: Created ${notificationIds.length} notifications for game $gameId');
      return true;
    } catch (e) {
      debugPrint('❌ NOTIFICATION SERVICE: Error creating notifications: $e');
      return false;
    }
  }

  /// Notify confirmed officials about game updates
  Future<bool> notifyGameUpdate({
    required String gameId,
    required String schedulerId,
    required List<String> officialIds,
    required List<String> changes,
  }) async {
    try {
      debugPrint('🔔 NOTIFICATION SERVICE: Creating game update notifications for game $gameId');

      // Get game details
      final gameDoc = await firestore.collection('games').doc(gameId).get();
      if (!gameDoc.exists) {
        debugPrint('❌ NOTIFICATION SERVICE: Game $gameId not found');
        return false;
      }

      final gameData = gameDoc.data()!;
      final gameTitle = _formatGameTitle(gameData);

      // Get scheduler details
      final schedulerDoc = await firestore.collection('users').doc(schedulerId).get();
      if (!schedulerDoc.exists) {
        debugPrint('❌ NOTIFICATION SERVICE: Scheduler $schedulerId not found');
        return false;
      }

      final schedulerData = schedulerDoc.data()!;
      final schedulerProfile = schedulerData['profile'] as Map<String, dynamic>? ?? {};
      final schedulerName = '${schedulerProfile['firstName'] ?? 'Scheduler'} ${schedulerProfile['lastName'] ?? ''}'.trim();
      final schedulerEmail = schedulerData['email'] ?? '';
      final schedulerPhone = schedulerProfile['phone'] ?? '';

      // Create notifications for each confirmed official
      final batch = firestore.batch();
      final notificationIds = <String>[];

      for (final officialId in officialIds) {
        final notificationId = '${gameId}_${officialId}_update_${DateTime.now().millisecondsSinceEpoch}';
        notificationIds.add(notificationId);

        final notification = NotificationModel.gameUpdated(
          id: notificationId,
          userId: officialId,
          gameTitle: gameTitle,
          schedulerName: schedulerName,
          schedulerEmail: schedulerEmail,
          schedulerPhone: schedulerPhone,
          changes: changes,
          gameId: gameId,
          schedulerId: schedulerId,
        );

        final notificationRef = firestore.collection(FirebaseCollections.notifications).doc(notificationId);
        batch.set(notificationRef, notification.toMap());
      }

      await batch.commit();

      debugPrint('✅ NOTIFICATION SERVICE: Created ${notificationIds.length} update notifications for game $gameId');
      return true;
    } catch (e) {
      debugPrint('❌ NOTIFICATION SERVICE: Error creating update notifications: $e');
      return false;
    }
  }

  /// Get notifications for a user
  Future<List<NotificationModel>> getUserNotifications(String userId, {int limit = 50}) async {
    try {
      debugPrint('🔍 NOTIFICATION SERVICE: Getting notifications for user $userId');

      final querySnapshot = await firestore
          .collection(FirebaseCollections.notifications)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final notifications = querySnapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();

      debugPrint('✅ NOTIFICATION SERVICE: Retrieved ${notifications.length} notifications for user $userId');
      return notifications;
    } catch (e) {
      debugPrint('❌ NOTIFICATION SERVICE: Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      await firestore.collection(FirebaseCollections.notifications).doc(notificationId).update({
        'isRead': true,
      });
      return true;
    } catch (e) {
      debugPrint('❌ NOTIFICATION SERVICE: Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = firestore.batch();

      final querySnapshot = await firestore
          .collection(FirebaseCollections.notifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('❌ NOTIFICATION SERVICE: Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await firestore.collection(FirebaseCollections.notifications).doc(notificationId).delete();
      return true;
    } catch (e) {
      debugPrint('❌ NOTIFICATION SERVICE: Error deleting notification: $e');
      return false;
    }
  }

  /// Get unread notification count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await firestore
          .collection(FirebaseCollections.notifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      debugPrint('❌ NOTIFICATION SERVICE: Error getting unread count: $e');
      return 0;
    }
  }

  /// Helper method to format game title
  String _formatGameTitle(Map<String, dynamic> gameData) {
    final opponent = gameData['opponent'] as String?;
    final homeTeam = gameData['homeTeam'] as String?;
    final sport = gameData['sport'] as String?;

    if (opponent != null && homeTeam != null) {
      return '$opponent vs $homeTeam';
    } else if (opponent != null) {
      return opponent;
    } else if (sport != null) {
      return '$sport Game';
    } else {
      return 'Game';
    }
  }
}
