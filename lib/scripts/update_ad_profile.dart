import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  try {
    // Update the AD user to have a schedulerProfile
    final userId = 'baxZCfpSB1Uhc8zDuZZDEtlG94V2'; // The AD user ID from logs

    await firestore.collection('users').doc(userId).update({
      'schedulerProfile': {
        'type': 'Athletic Director',
        'teamName': 'St. James Crusaders',
        'schoolName': 'St. James High School',
        'schoolAddress': '123 School St, Belleville, IL 62220',
      }
    });

    print('✅ Successfully updated AD user profile with schedulerProfile');
    print('Team Name: St. James Crusaders');
    print('Now games created by this AD should have homeTeam populated and appear for officials.');

  } catch (e) {
    print('❌ Error updating AD profile: $e');
  }
}
