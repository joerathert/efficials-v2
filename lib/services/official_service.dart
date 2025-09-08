import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firebase_constants.dart';

class OfficialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Debug flag - set to false to reduce console noise
  static const bool _debugEnabled = false;

  // Helper method for conditional debug prints
  void _debugPrint(String message) {
    if (_debugEnabled) {
      print(message);
    }
  }

  /// Get officials with filters applied
  Future<List<Map<String, dynamic>>> getFilteredOfficials({
    required String sport,
    String? ihsaLevel,
    int? minYears,
    List<String>? levels,
    int? radius,
    Map<String, dynamic>? locationData,
  }) async {
    try {
      _debugPrint('🔍 OfficialService: Filtering for sport: $sport');
      _debugPrint(
          '🔍 Filters: ihsaLevel=$ihsaLevel, minYears=$minYears, levels=$levels, radius=$radius');

      // Query users collection for officials
      Query query = _firestore
          .collection(FirebaseCollections.users)
          .where(FirebaseFields.role, isEqualTo: FirebaseValues.roleOfficial);

      final snapshot = await query.get();
      _debugPrint('🔍 Found ${snapshot.docs.length} officials in database');

      // Filter results in memory (Firestore has limitations with complex nested queries)
      final filteredOfficials = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final officialProfile =
            data['officialProfile'] as Map<String, dynamic>?;

        if (officialProfile == null) {
          _debugPrint('❌ Official ${data['email']} has no officialProfile');
          return false;
        }

        // IHSA level filter - check sport-specific data
        if (ihsaLevel != null) {
          final sportsData =
              officialProfile['sportsData'] as Map<String, dynamic>?;
          if (sportsData == null) {
            _debugPrint('❌ Official ${data['email']} has no sportsData');
            _debugPrint(
                '🔍 Official ${data['email']} officialProfile keys: ${officialProfile.keys.toList()}');
            return false;
          }

          _debugPrint(
              '🔍 Official ${data['email']} sportsData keys: ${sportsData.keys.toList()}');

          // Check the sport-specific data
          final sportData = sportsData[sport] as Map<String, dynamic>?;
          if (sportData == null) {
            _debugPrint(
                '❌ Official ${data['email']} has no data for sport: $sport');
            _debugPrint('   Available sports: ${sportsData.keys.toList()}');
            return false;
          }

          // Debug: Show the actual sport data structure
          _debugPrint(
              '🔍 Official ${data['email']} sport data keys: ${sportData.keys.toList()}');
          _debugPrint(
              '🔍 Official ${data['email']} full sport data: $sportData');

          final officialIhsaLevel = sportData['certification'];
          if (officialIhsaLevel == null) {
            _debugPrint(
                '❌ Official ${data['email']} has no certification for $sport');
            return false;
          }

          _debugPrint(
              '✅ Official ${data['email']} certification: $officialIhsaLevel (filtering for: $ihsaLevel)');

          // Handle different certification formats
          final normalizedIhsaLevel =
              officialIhsaLevel.toString().toLowerCase();

          switch (ihsaLevel) {
            case 'registered':
              if (!normalizedIhsaLevel.contains('registered') &&
                  !normalizedIhsaLevel.contains('recognized') &&
                  !normalizedIhsaLevel.contains('certified')) {
                print(
                    '❌ Official ${data['email']} certification $officialIhsaLevel not in registered tier');
                return false;
              }
              break;
            case 'recognized':
              if (!normalizedIhsaLevel.contains('recognized') &&
                  !normalizedIhsaLevel.contains('certified')) {
                print(
                    '❌ Official ${data['email']} certification $officialIhsaLevel not in recognized tier');
                return false;
              }
              break;
            case 'certified':
              if (!normalizedIhsaLevel.contains('certified')) {
                _debugPrint(
                    '❌ Official ${data['email']} certification $officialIhsaLevel is not certified');
                return false;
              }
              break;
          }
        }

        // Experience filter - check sport-specific data
        if (minYears != null && minYears > 0) {
          final sportsData =
              officialProfile['sportsData'] as Map<String, dynamic>?;
          if (sportsData == null) {
            _debugPrint(
                '❌ Official ${data['email']} has no sportsData for experience filter');
            return false;
          }

          final sportData = sportsData[sport] as Map<String, dynamic>?;
          if (sportData == null) {
            _debugPrint(
                '❌ Official ${data['email']} has no data for sport: $sport (experience filter)');
            return false;
          }

          final experience = sportData['experience'];
          if (experience == null) {
            _debugPrint(
                '❌ Official ${data['email']} has no experience for $sport');
            return false;
          }

          _debugPrint(
              '✅ Official ${data['email']} experience: $experience years (min required: $minYears)');

          if (experience < minYears) {
            _debugPrint(
                '❌ Official ${data['email']} experience $experience < required $minYears');
            return false;
          }
        }

        // Competition levels filter - check sport-specific data
        if (levels != null && levels.isNotEmpty) {
          final sportsData =
              officialProfile['sportsData'] as Map<String, dynamic>?;
          if (sportsData == null) {
            _debugPrint(
                '❌ Official ${data['email']} has no sportsData for competition levels filter');
            return false;
          }

          final sportData = sportsData[sport] as Map<String, dynamic>?;
          if (sportData == null) {
            _debugPrint(
                '❌ Official ${data['email']} has no data for sport: $sport (competition levels filter)');
            return false;
          }

          final officialLevels =
              sportData['competitionLevels'] as List<dynamic>?;
          if (officialLevels == null || officialLevels.isEmpty) {
            _debugPrint(
                '❌ Official ${data['email']} has no competitionLevels for $sport');
            return false;
          }

          _debugPrint(
              '✅ Official ${data['email']} competition levels: $officialLevels');
          _debugPrint('   Required levels: $levels');

          // Check if the official has at least one of the required competition levels
          // Handle both full names (e.g., "Varsity (17U-18U)") and short names (e.g., "Varsity")
          final hasRequiredLevel = levels.any((requiredLevel) {
            return officialLevels.any((officialLevel) {
              // Check for exact match first
              if (officialLevel == requiredLevel) return true;

              // Check if the official's level contains the required level name
              if (officialLevel
                  .toString()
                  .toLowerCase()
                  .contains(requiredLevel.toString().toLowerCase())) {
                return true;
              }

              // Handle mapping for common cases
              if (requiredLevel == 'Varsity' &&
                  officialLevel.contains('Varsity')) return true;
              if (requiredLevel == 'JV' &&
                  officialLevel.toLowerCase().contains('varsity')) return true;
              if (requiredLevel == 'JV' && officialLevel.contains('16U-17U'))
                return true;
              if (requiredLevel == 'Underclass' &&
                  officialLevel.contains('15U-16U')) return true;
              if (requiredLevel == 'Middle School' &&
                  officialLevel.contains('11U-14U')) return true;
              if (requiredLevel == 'Grade School' &&
                  officialLevel.contains('6U-11U')) return true;

              return false;
            });
          });

          if (!hasRequiredLevel) {
            _debugPrint(
                '❌ Official ${data['email']} does not have any required competition levels');
            _debugPrint('   Official has: $officialLevels');
            _debugPrint('   Looking for: $levels');
            return false;
          }
        }

        // Radius filter - check if official is within specified distance
        if (radius != null && radius > 0 && locationData != null) {
          final officialDistance = officialProfile['distance'] as num?;
          if (officialDistance == null || officialDistance > radius)
            return false;
        }

        return true;
      }).toList();

      _debugPrint(
          '🔍 After filtering: ${filteredOfficials.length} officials passed all filters');

      return filteredOfficials.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final officialProfile =
            data['officialProfile'] as Map<String, dynamic>? ?? {};

        return {
          'id': doc.id,
          'firstName': profile['firstName'] ?? '',
          'lastName': profile['lastName'] ?? '',
          'name': '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
              .trim(),
          'email': data['email'] ?? '',
          'phone': profile['phone'] ?? '',
          'address': officialProfile['address'] ?? '',
          'city': officialProfile['city'] ?? '',
          'state': officialProfile['state'] ?? '',
          'cityState': officialProfile['city'] != null &&
                  officialProfile['state'] != null
              ? '${officialProfile['city']}, ${officialProfile['state']}'
              : '',
          'zipCode': officialProfile['zipCode'] ?? '',
          'distance': officialProfile['distance'] ?? 0.0,
          'yearsExperience': (officialProfile['sportsData']
                  as Map<String, dynamic>?)?[sport]?['experience'] ??
              0,
          'ihsaLevel': (officialProfile['sportsData']
                  as Map<String, dynamic>?)?[sport]?['certification'] ??
              'registered',
          'competitionLevels': (officialProfile['sportsData']
                  as Map<String, dynamic>?)?[sport]?['competitionLevels'] ??
              [],
          'sports': officialProfile['sports'] ?? [sport],
          'sportsData': officialProfile['sportsData'] ?? {},
          'isActive': data['isActive'] ?? true,
          'availabilityStatus':
              officialProfile['availabilityStatus'] ?? 'available',
        };
      }).toList();
    } catch (e) {
      _debugPrint('Error querying officials: $e');
      return [];
    }
  }

  /// Get all officials (for simple queries without complex filtering)
  Future<List<Map<String, dynamic>>> getAllOfficials() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'official')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final profile = data['profile'] as Map<String, dynamic>? ?? {};
        final officialProfile =
            data['officialProfile'] as Map<String, dynamic>? ?? {};

        return {
          'id': doc.id,
          'firstName': profile['firstName'] ?? '',
          'lastName': profile['lastName'] ?? '',
          'name': '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'
              .trim(),
          'email': data['email'] ?? '',
          'phone': profile['phone'] ?? '',
          'address': officialProfile['address'] ?? '',
          'city': officialProfile['city'] ?? '',
          'state': officialProfile['state'] ?? '',
          'cityState': officialProfile['city'] != null &&
                  officialProfile['state'] != null
              ? '${officialProfile['city']}, ${officialProfile['state']}'
              : '',
          'zipCode': officialProfile['zipCode'] ?? '',
          'distance': officialProfile['distance'] ?? 0.0,
          'yearsExperience': (officialProfile['sportsData']
                  as Map<String, dynamic>?)?['Football']?['experience'] ??
              0,
          'ihsaLevel': (officialProfile['sportsData']
                  as Map<String, dynamic>?)?['Football']?['certification'] ??
              'registered',
          'competitionLevels': (officialProfile['sportsData']
                      as Map<String, dynamic>?)?['Football']
                  ?['competitionLevels'] ??
              [],
          'sports': officialProfile['sports'] ?? ['Football'],
          'sportsData': officialProfile['sportsData'] ?? {},
          'isActive': data['isActive'] ?? true,
          'availabilityStatus':
              officialProfile['availabilityStatus'] ?? 'available',
        };
      }).toList();
    } catch (e) {
      print('Error getting all officials: $e');
      return [];
    }
  }
}
