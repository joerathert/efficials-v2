import 'package:cloud_firestore/cloud_firestore.dart';

class OfficialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Query users collection for officials
      Query query =
          _firestore.collection('users').where('role', isEqualTo: 'official');

      final snapshot = await query.get();

      // Filter results in memory (Firestore has limitations with complex nested queries)
      final filteredOfficials = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final officialProfile =
            data['officialProfile'] as Map<String, dynamic>?;

        if (officialProfile == null) return false;

        // IHSA level filter - check sport-specific data
        if (ihsaLevel != null) {
          final sportsData =
              officialProfile['sportsData'] as Map<String, dynamic>?;
          if (sportsData == null) return false;

          // For football, check the certification level
          final footballData = sportsData['Football'] as Map<String, dynamic>?;
          if (footballData == null) return false;

          final officialIhsaLevel = footballData['certificationLevel'];
          if (officialIhsaLevel == null) return false;

          switch (ihsaLevel) {
            case 'registered':
              if (!['registered', 'recognized', 'certified']
                  .contains(officialIhsaLevel)) return false;
              break;
            case 'recognized':
              if (!['recognized', 'certified'].contains(officialIhsaLevel))
                return false;
              break;
            case 'certified':
              if (officialIhsaLevel != 'certified') return false;
              break;
          }
        }

        // Experience filter - check sport-specific data
        if (minYears != null && minYears > 0) {
          final sportsData =
              officialProfile['sportsData'] as Map<String, dynamic>?;
          if (sportsData == null) return false;

          final footballData = sportsData['Football'] as Map<String, dynamic>?;
          if (footballData == null) return false;

          final experience = footballData['experienceYears'];
          if (experience == null || experience < minYears) return false;
        }

        return true;
      }).toList();

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
                  as Map<String, dynamic>?)?['Football']?['experienceYears'] ??
              0,
          'ihsaLevel': (officialProfile['sportsData']
                      as Map<String, dynamic>?)?['Football']
                  ?['certificationLevel'] ??
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
      print('Error querying officials: $e');
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
                  as Map<String, dynamic>?)?['Football']?['experienceYears'] ??
              0,
          'ihsaLevel': (officialProfile['sportsData']
                      as Map<String, dynamic>?)?['Football']
                  ?['certificationLevel'] ??
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
