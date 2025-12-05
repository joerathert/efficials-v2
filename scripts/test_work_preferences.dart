import '../lib/models/user_model.dart';

void main() {
  print('=== Testing Work Preferences in OfficialProfile ===');

  // Test 1: Create OfficialProfile with work preferences
  final profile = OfficialProfile(
    city: 'Test City',
    state: 'IL',
    ratePerGame: 50.0,
    maxTravelDistance: 100,
  );

  print('✅ OfficialProfile created successfully');
  print('Rate per Game: \$${profile.ratePerGame}');
  print('Max Travel Distance: ${profile.maxTravelDistance} miles');

  // Test 2: Convert to map and back
  final map = profile.toMap();
  print('\n✅ Converted to map:');
  print('ratePerGame: ${map['ratePerGame']}');
  print('maxTravelDistance: ${map['maxTravelDistance']}');

  // Test 3: Create from map
  final profileFromMap = OfficialProfile.fromMap(map);
  print('\n✅ Created from map:');
  print('Rate per Game: \$${profileFromMap.ratePerGame}');
  print('Max Travel Distance: ${profileFromMap.maxTravelDistance} miles');

  // Test 4: Verify values match
  if (profile.ratePerGame == profileFromMap.ratePerGame &&
      profile.maxTravelDistance == profileFromMap.maxTravelDistance) {
    print('\n✅ SUCCESS: Work preferences are correctly saved and retrieved!');
  } else {
    print('\n❌ FAILURE: Values don\'t match after conversion');
  }

  // Test 5: Test with null values
  final profileWithNulls = OfficialProfile(
    city: 'Test City',
    state: 'IL',
    // ratePerGame and maxTravelDistance are null by default
  );

  print('\n✅ Profile with null work preferences:');
  print('Rate per Game: ${profileWithNulls.ratePerGame}');
  print('Max Travel Distance: ${profileWithNulls.maxTravelDistance}');

  print('\n=== Test Complete ===');
}
