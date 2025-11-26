import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'dart:convert';
import 'dart:io';

/// Script to export games data from Firestore to JSON
/// Run this from the command line: dart lib/scripts/export_games_data.dart

void main() async {
  print('🔍 Starting games data export...');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  try {
    // Get all games
    final gamesSnapshot = await firestore.collection('games').get();
    print('📊 Found ${gamesSnapshot.docs.length} games in database');

    // Get all users for validation
    final usersSnapshot = await firestore.collection('users').get();
    final existingUserIds = usersSnapshot.docs.map((doc) => doc.id).toSet();
    print('👥 Found ${existingUserIds.length} users in database');

    // Convert games to JSON
    final gamesData = <Map<String, dynamic>>[];

    for (final gameDoc in gamesSnapshot.docs) {
      final data = gameDoc.data();
      final gameWithId = {
        'documentId': gameDoc.id,
        ...data,
      };
      gamesData.add(gameWithId);
    }

    // Categorize games
    final orphanedGames = <Map<String, dynamic>>[];
    final gamesWithValidUsers = <Map<String, dynamic>>[];
    final gamesWithMissingUserFields = <Map<String, dynamic>>[];

    for (final game in gamesData) {
      final schedulerId = game['schedulerId'] as String?;
      final userId = game['userId'] as String?;
      final gameId = game['documentId'];

      // Check if game has user identification
      if (schedulerId == null && userId == null) {
        gamesWithMissingUserFields.add(game);
        print('❌ Game $gameId: Missing both schedulerId and userId');
      } else {
        // Check if the user still exists
        final effectiveUserId = schedulerId ?? userId;
        if (existingUserIds.contains(effectiveUserId)) {
          gamesWithValidUsers.add(game);
        } else {
          orphanedGames.add(game);
          print('🗑️ Game $gameId: User $effectiveUserId no longer exists');
        }
      }
    }

    // Create export data
    final exportData = {
      'summary': {
        'totalGames': gamesSnapshot.docs.length,
        'totalUsers': existingUserIds.length,
        'gamesWithValidUsers': gamesWithValidUsers.length,
        'gamesWithMissingUserFields': gamesWithMissingUserFields.length,
        'orphanedGames': orphanedGames.length,
      },
      'games': gamesData,
      'orphanedGames': orphanedGames,
      'gamesWithMissingUserFields': gamesWithMissingUserFields,
      'existingUserIds': existingUserIds.toList(),
    };

    // Write to JSON file
    final jsonString = JsonEncoder.withIndent('  ').convert(exportData);
    final file = File('games_export.json');
    await file.writeAsString(jsonString);

    print('\n📈 SUMMARY:');
    print('✅ Games with valid users: ${gamesWithValidUsers.length}');
    print('❌ Games with missing user fields: ${gamesWithMissingUserFields.length}');
    print('🗑️ Orphaned games (user deleted): ${orphanedGames.length}');

    print('\n💾 Data exported to: games_export.json');

    if (orphanedGames.isNotEmpty) {
      print('\n🗑️ Orphaned games that can be safely deleted:');
      for (final game in orphanedGames) {
        final gameId = game['documentId'];
        final opponent = game['opponent'] ?? 'Unknown';
        final date = game['date'] ?? 'No date';
        print('  - Game ID: $gameId, Opponent: $opponent, Date: $date');
      }
    }

    if (gamesWithMissingUserFields.isNotEmpty) {
      print('\n❌ Games with missing user fields:');
      for (final game in gamesWithMissingUserFields) {
        final gameId = game['documentId'];
        final opponent = game['opponent'] ?? 'Unknown';
        final date = game['date'] ?? 'No date';
        print('  - Game ID: $gameId, Opponent: $opponent, Date: $date');
      }
    }

  } catch (e) {
    print('❌ Error during export: $e');
  }
}
