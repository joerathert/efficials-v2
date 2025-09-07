import 'test_officials_template.dart';

/// Convert all officials to sport-specific structure
List<Map<String, dynamic>> convertAllToSportSpecific() {
  return testOfficialsFromExcel.map((official) {
    final officialProfile = official['officialProfile'] as Map<String, dynamic>;

    // Create sportsData structure
    final sportsData = <String, Map<String, dynamic>>{};
    final sports = officialProfile['sports'] as List<dynamic>;

    for (final sport in sports) {
      sportsData[sport as String] = {
        'experienceYears': officialProfile['experienceYears'] ?? 0,
        'certificationLevel':
            officialProfile['certificationLevel'] ?? 'registered',
        'competitionLevels': officialProfile['competitionLevels'] ?? [],
      };
    }

    // Return updated official with sportsData
    return {
      ...official,
      'officialProfile': {
        ...officialProfile,
        'sportsData': sportsData,
        // Remove the old top-level fields
        'experienceYears': null,
        'certificationLevel': null,
        'competitionLevels': null,
      }..removeWhere((key, value) => value == null),
    };
  }).toList();
}

void main() {
  final converted = convertAllToSportSpecific();
  print('Converted ${converted.length} officials to sport-specific structure');

  // Print first official as example
  print('\nExample - First official:');
  print(converted[0]);
}
