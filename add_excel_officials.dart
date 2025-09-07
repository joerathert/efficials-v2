import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efficials_v2/firebase_options.dart';
import 'test_officials_template.dart';

/// Add Excel officials data to Firebase
Future<void> addExcelOfficials() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;

    print('Adding Excel officials to Firebase...');

    // Add officials to Firestore
    final batch = firestore.batch();
    final officialsCollection = firestore.collection('officials');

    for (final official in testOfficialsFromExcel) {
      final docRef = officialsCollection.doc();
      batch.set(docRef, official);
      print(
          'Adding official: ${official['firstName']} ${official['lastName']}');
    }

    await batch.commit();

    print('\n✅ Excel officials added successfully!');
    print('Added ${testOfficialsFromExcel.length} officials to the database.');
    print('\nOfficials include:');
    print(
        '• ${testOfficialsFromExcel.where((o) => o['ihsaLevel'] == 'certified').length} Certified officials');
    print(
        '• ${testOfficialsFromExcel.where((o) => o['ihsaLevel'] == 'recognized').length} Recognized officials');
    print(
        '• ${testOfficialsFromExcel.where((o) => o['ihsaLevel'] == 'registered').length} Registered officials');
    print(
        '• Experience ranges from ${testOfficialsFromExcel.map((o) => o['yearsExperience'] as int).reduce((a, b) => a < b ? a : b)} to ${testOfficialsFromExcel.map((o) => o['yearsExperience'] as int).reduce((a, b) => a > b ? a : b)} years');
    print('• Locations span multiple Illinois cities');

    print('\n🎯 Ready for testing!');
    print('You can now test the filter system with these realistic officials.');
  } catch (e) {
    print('❌ Error adding officials: $e');
  }
}

void main() async {
  await addExcelOfficials();
}
