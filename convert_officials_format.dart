import 'test_officials_template.dart';

/// Convert officials data from simple format to UserModel format
List<Map<String, dynamic>> convertToUserModelFormat() {
  return testOfficialsFromExcel.map((official) {
    // Generate a simple ID based on name
    final firstName = official['firstName'] as String;
    final lastName = official['lastName'] as String;
    final id = 'official_${firstName.toLowerCase()}_${lastName.toLowerCase()}';

    return {
      'id': id,
      'email': official['email'],
      'role': 'official',
      'isActive': official['isActive'] ?? true,
      'createdAt': official['createdAt'],
      'updatedAt': official['updatedAt'],
      'profile': {
        'firstName': firstName,
        'lastName': lastName,
        'phone': official['phone'],
      },
      'officialProfile': {
        'city': official['cityState']?.split(', ')[0] ?? '',
        'state': official['cityState']?.split(', ')[1] ?? 'IL',
        'zipCode': official['zipCode'] ?? '',
        'address': official['address'] ?? '',
        'distance': official['distance'] ?? 0.0,
        'experienceYears': official['yearsExperience'] ?? 0,
        'certificationLevel': official['ihsaLevel'] ?? 'registered',
        'competitionLevels': official['competitionLevels'] ?? [],
        'sports': official['sports'] ?? ['Football'],
        'availabilityStatus': 'available',
        'followThroughRate': 100.0,
        'totalAcceptedGames': 0,
        'totalBackedOutGames': 0,
      },
    };
  }).toList();
}

void main() {
  final converted = convertToUserModelFormat();
  print('Converted ${converted.length} officials to UserModel format');
  print('First official:');
  print(converted[0]);
}
