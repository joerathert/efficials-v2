import 'package:cloud_firestore/cloud_firestore.dart';

/// Script to identify and clean up orphaned games in Firestore
/// Run this from the command line: dart lib/scripts/cleanup_orphaned_games.dart

void main() async {
  print('🔍 Starting orphaned games cleanup...');

  final firestore = FirebaseFirestore.instance;

  try {
    // Get all games
    final gamesSnapshot = await firestore.collection('games').get();
    print('📊 Found ${gamesSnapshot.docs.length} total games in database');

    // Get all users
    final usersSnapshot = await firestore.collection('users').get();
    final existingUserIds = usersSnapshot.docs.map((doc) => doc.id).toSet();
    print('👥 Found ${existingUserIds.length} users in database');

    // Categorize games
    final orphanedGames = <QueryDocumentSnapshot>[];
    final gamesWithValidUsers = <QueryDocumentSnapshot>[];
    final gamesWithMissingUserFields = <QueryDocumentSnapshot>[];

    for (final gameDoc in gamesSnapshot.docs) {
      final data = gameDoc.data();
      final schedulerId = data['schedulerId'] as String?;
      final userId = data['userId'] as String?;
      final gameId = gameDoc.id;

      // Check if game has user identification
      if (schedulerId == null && userId == null) {
        gamesWithMissingUserFields.add(gameDoc);
        print('❌ Game $gameId: Missing both schedulerId and userId');
      } else {
        // Check if the user still exists
        final effectiveUserId = schedulerId ?? userId;
        if (existingUserIds.contains(effectiveUserId)) {
          gamesWithValidUsers.add(gameDoc);
        } else {
          orphanedGames.add(gameDoc);
          print('🗑️ Game $gameId: User $effectiveUserId no longer exists');
        }
      }
    }

    // Summary
    print('\n📈 SUMMARY:');
    print('✅ Games with valid users: ${gamesWithValidUsers.length}');
    print(
        '❌ Games with missing user fields: ${gamesWithMissingUserFields.length}');
    print('🗑️ Orphaned games (user deleted): ${orphanedGames.length}');

    // Ask user what to do
    print('\n🔧 CLEANUP OPTIONS:');
    print('1. Delete orphaned games (user accounts deleted)');
    print('2. Show details of games with missing user fields');
    print('3. Exit without changes');

    // For now, just show the information
    if (gamesWithMissingUserFields.isNotEmpty) {
      print('\n📋 Games with missing user identification:');
      for (final game in gamesWithMissingUserFields) {
        final data = game.data() as Map<String, dynamic>;
        print('  - Game ID: ${game.id}');
        print('    Sport: ${data['sport']}');
        print('    Opponent: ${data['opponent']}');
        print('    Date: ${data['date']}');
        print('    Status: ${data['status']}');
        print('');
      }
    }

    print(
        '🚨 To delete orphaned games, uncomment the deletion code below and run again');

    // Uncomment the code below to actually delete orphaned games
    /*
    print('🗑️ Deleting ${orphanedGames.length} orphaned games...');
    for (final game in orphanedGames) {
      await firestore.collection('games').doc(game.id).delete();
      print('  Deleted game: ${game.id}');
    }
    print('✅ Deleted ${orphanedGames.length} orphaned games');
    */

    // Also uncomment to delete games with missing user fields
    /*
    print('🗑️ Deleting ${gamesWithMissingUserFields.length} games with missing user fields...');
    for (final game in gamesWithMissingUserFields) {
      await firestore.collection('games').doc(game.id).delete();
      print('  Deleted game: ${game.id}');
    }
    print('✅ Deleted ${gamesWithMissingUserFields.length} games with missing user fields');
    */
  } catch (e) {
    print('❌ Error during cleanup: $e');
  }
}
