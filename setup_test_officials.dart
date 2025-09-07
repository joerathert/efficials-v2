import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efficials_v2/firebase_options.dart';

/// Setup script to create test officials for development and testing
/// Run this to populate the database with test officials for filter testing
Future<void> setupTestOfficials() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final firestore = FirebaseFirestore.instance;

    print('Setting up test officials...');

    // Test officials data with various attributes for filter testing
    final testOfficials = [
      {
        'name': 'John Smith',
        'email': 'john.smith@email.com',
        'phone': '(555) 123-4567',
        'cityState': 'Springfield, IL',
        'distance': 5.2,
        'yearsExperience': 8,
        'ihsaLevel': 'registered',
        'competitionLevels': ['Grade School', 'Middle School', 'JV', 'Varsity'],
        'sports': ['Football', 'Basketball'],
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'name': 'Sarah Johnson',
        'email': 'sarah.johnson@email.com',
        'phone': '(555) 234-5678',
        'cityState': 'Champaign, IL',
        'distance': 12.8,
        'yearsExperience': 5,
        'ihsaLevel': 'recognized',
        'competitionLevels': ['JV', 'Varsity', 'College'],
        'sports': ['Football', 'Soccer'],
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'name': 'Mike Davis',
        'email': 'mike.davis@email.com',
        'phone': '(555) 345-6789',
        'cityState': 'Decatur, IL',
        'distance': 25.1,
        'yearsExperience': 12,
        'ihsaLevel': 'certified',
        'competitionLevels': ['Varsity', 'College', 'Adult'],
        'sports': ['Football', 'Basketball', 'Baseball'],
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'name': 'Emily Wilson',
        'email': 'emily.wilson@email.com',
        'phone': '(555) 456-7890',
        'cityState': 'Bloomington, IL',
        'distance': 8.9,
        'yearsExperience': 6,
        'ihsaLevel': 'registered',
        'competitionLevels': ['Grade School', 'Middle School', 'Underclass'],
        'sports': ['Soccer', 'Volleyball'],
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'name': 'David Brown',
        'email': 'david.brown@email.com',
        'phone': '(555) 567-8901',
        'cityState': 'Peoria, IL',
        'distance': 18.3,
        'yearsExperience': 10,
        'ihsaLevel': 'recognized',
        'competitionLevels': ['JV', 'Varsity', 'College'],
        'sports': ['Football', 'Wrestling', 'Track'],
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'name': 'Lisa Garcia',
        'email': 'lisa.garcia@email.com',
        'phone': '(555) 678-9012',
        'cityState': 'Normal, IL',
        'distance': 15.7,
        'yearsExperience': 7,
        'ihsaLevel': 'certified',
        'competitionLevels': ['Middle School', 'JV', 'Varsity'],
        'sports': ['Basketball', 'Soccer', 'Softball'],
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'name': 'Robert Taylor',
        'email': 'robert.taylor@email.com',
        'phone': '(555) 789-0123',
        'cityState': 'Urbana, IL',
        'distance': 22.4,
        'yearsExperience': 15,
        'ihsaLevel': 'certified',
        'competitionLevels': ['Varsity', 'College', 'Adult'],
        'sports': ['Football', 'Basketball', 'Baseball'],
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'name': 'Jennifer Martinez',
        'email': 'jennifer.martinez@email.com',
        'phone': '(555) 890-1234',
        'cityState': 'Danville, IL',
        'distance': 35.2,
        'yearsExperience': 3,
        'ihsaLevel': 'registered',
        'competitionLevels': ['Grade School', 'Middle School'],
        'sports': ['Soccer', 'Volleyball'],
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
    ];

    // Add officials to Firestore
    final batch = firestore.batch();
    final officialsCollection = firestore.collection('officials');

    for (final official in testOfficials) {
      final docRef = officialsCollection.doc();
      batch.set(docRef, official);
      print('Adding official: ${official['name']}');
    }

    await batch.commit();

    print('\n✅ Test officials setup complete!');
    print('Added ${testOfficials.length} test officials to the database.');
    print('\nTest officials include:');
    print(
        '• Various IHSA certification levels (registered, recognized, certified)');
    print('• Different experience levels (3-15 years)');
    print('• Multiple competition levels (Grade School through Adult)');
    print('• Different sports (Football, Basketball, Soccer, etc.)');
    print('• Various distances from Springfield, IL (5-35 miles)');

    print('\nTo test filtering:');
    print('1. Navigate to Populate Roster screen');
    print('2. Click "Apply Filters"');
    print('3. Try different filter combinations to see how they work');
  } catch (e) {
    print('❌ Error setting up test officials: $e');
  }
}

void main() async {
  await setupTestOfficials();
}
