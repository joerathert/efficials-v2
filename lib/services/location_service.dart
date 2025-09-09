import '../services/auth_service.dart';
import '../constants/firebase_constants.dart';
import 'base_service.dart';

class LocationService extends BaseService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  LocationService._internal();
  factory LocationService() => _instance;

  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> createLocation({
    required String name,
    required String address,
    required String city,
    required String state,
    required String zip,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final locationData = {
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'createdBy': currentUser.uid,
        'createdAt': DateTime.now(),
      };

      final docRef = await firestore
          .collection(FirebaseCollections.locations)
          .add(locationData);

      return {
        'id': docRef.id,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
      };
    } catch (e) {
      throw Exception('Failed to create location: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLocations() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        return [];
      }

      final querySnapshot = await firestore
          .collection('locations')
          .where('createdBy', isEqualTo: currentUser.uid)
          .get();

      final locations = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] as String,
          'address': data['address'] as String,
          'city': data['city'] as String,
          'state': data['state'] as String,
          'zip': data['zip'] as String,
        };
      }).toList();

      print(
          'LocationService: Fetched ${locations.length} locations for user ${currentUser.uid}');
      return locations;
    } catch (e) {
      print('Error fetching locations: $e');
      return [];
    }
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      await firestore.collection('locations').doc(locationId).delete();
    } catch (e) {
      throw Exception('Failed to delete location: $e');
    }
  }
}
