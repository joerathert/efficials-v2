import '../models/user_model.dart';

class UserRepository {
  Future<UserModel?> getCurrentUser() async {
    // Mock implementation - return a mock user
    await Future.delayed(const Duration(milliseconds: 200));
    return UserModel(
      id: 'user123',
      email: 'user@example.com',
      role: 'scheduler',
      profile: ProfileData(
        firstName: 'Test',
        lastName: 'Director',
        phone: '555-123-4567',
      ),
      schedulerProfile: SchedulerProfile(
        type: 'Athletic Director',
        sport: 'Football',
        schoolName: 'Test School',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
