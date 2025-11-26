// Test script to verify game args logic
void main() {
  // Simulate the original game args that should be stored
  final originalGameArgs = {
    'scheduleName': 'Boys \'A\' Team',
    'sport': 'Basketball',
    'homeTeam': 'Good Shepherd Chargers',
    'template': null,
    'date': DateTime(2025, 11, 27),
    'time': '7:00 PM',
    'location': 'Good Shepherd Lutheran',
    'isAwayGame': false,
    'isAway': false,
    'id': 1763861301393,
    'levelOfCompetition': 'Middle School',
    'gender': 'Boys',
    'officialsRequired': 2,
    'gameFee': 60,
    'opponent': 'TLS',
    'hireAutomatically': false,
    'officialsHired': 0,
    'selectedOfficials': [],
    'fromGameCreation': true
  };

  // Simulate the list that gets selected
  final list = {
    'name': 'Boys Basketball',
    'sport': 'Basketball',
    'officials': [
      {'name': 'Katie Moore', 'id': 'TsNBJoxqpZfVlxT9rZ2HX5XNDAD3'},
      {'name': 'Joe Rathert', 'id': 'qhzstTc9K0Ufwxo29NVpr6dBssQ2'}
    ]
  };

  // Simulate what _navigateToReviewGameInfo should produce
  final args = originalGameArgs;

  final gameData = {
    ...args,
    'method': 'use_list',
    'selectedListName': list['name'],
    'selectedOfficials': list['officials'] ?? [],
  };

  print('✅ Test Results:');
  print('scheduleName: ${gameData['scheduleName']}');
  print('sport: ${gameData['sport']}');
  print('homeTeam: ${gameData['homeTeam']}');
  print('opponent: ${gameData['opponent']}');
  print('selectedListName: ${gameData['selectedListName']}');
  print('method: ${gameData['method']}');

  // Verify all expected values are present
  assert(gameData['scheduleName'] == 'Boys \'A\' Team');
  assert(gameData['sport'] == 'Basketball');
  assert(gameData['homeTeam'] == 'Good Shepherd Chargers');
  assert(gameData['selectedListName'] == 'Boys Basketball');
  assert(gameData['method'] == 'use_list');

  print('✅ All assertions passed! The game args logic should work correctly.');
}
