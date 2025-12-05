import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  await Firebase.initializeApp();

  // Query for the user
  final query = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: 'joe.rathert@efficials.com')
      .get();

  if (query.docs.isNotEmpty) {
    final userDoc = query.docs.first;
    final userData = userDoc.data();

    print('User ID: ${userDoc.id}');
    print('User Data: $userData');

    if (userData.containsKey('officialProfile')) {
      final officialProfile = userData['officialProfile'] as Map<String, dynamic>;
      print('Official Profile: $officialProfile');

      if (officialProfile.containsKey('sportsData')) {
        final sportsData = officialProfile['sportsData'] as Map<String, dynamic>;
        print('Sports Data: $sportsData');
      } else {
        print('No sportsData found in officialProfile');
      }
    } else {
      print('No officialProfile found');
    }
  } else {
    print('User not found');
  }
}
