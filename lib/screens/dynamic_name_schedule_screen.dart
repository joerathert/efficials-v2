import 'package:flutter/material.dart';
import '../services/user_repository.dart';
import 'assigner_name_schedule_screen.dart'; // Assigner screen (has both name and home team fields)
import 'ad_name_schedule_screen.dart'; // AD screen (only name field)

class DynamicNameScheduleScreen extends StatelessWidget {
  const DynamicNameScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _determineScreen(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A1A1A),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFF5D920)),
            ),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error determining screen: ${snapshot.error}');
          // Default to AD screen on error
          return const ADNameScheduleScreen();
        }

        return snapshot.data ?? const ADNameScheduleScreen();
      },
    );
  }

  Future<Widget> _determineScreen() async {
    try {
      final userRepository = UserRepository();
      final currentUser = await userRepository.getCurrentUser();

      debugPrint('🔍 Current user: $currentUser');
      debugPrint('🔍 Current user role: ${currentUser?.role}');
      debugPrint('🔍 Current user scheduler profile: ${currentUser?.schedulerProfile}');
      debugPrint('🔍 Current user scheduler type: ${currentUser?.schedulerProfile?.type}');
      debugPrint('🔍 Checking if assigner: ${currentUser?.schedulerProfile?.type?.toLowerCase() == 'assigner'}');

      if (currentUser != null && currentUser.schedulerProfile != null &&
          currentUser.schedulerProfile!.type?.toLowerCase() == 'assigner') {
        debugPrint('✅ RETURNING ASSIGNER SCREEN: type is ${currentUser.schedulerProfile!.type}');
        return const AssignerNameScheduleScreen(); // Assigner screen with both fields
      } else {
        debugPrint('❌ RETURNING AD SCREEN: type is ${currentUser?.schedulerProfile?.type}');
        return const ADNameScheduleScreen(); // AD screen with just name field
      }
    } catch (e) {
      debugPrint('❌ ERROR determining screen type: $e');
      // Default to AD screen if there's an error
      return const ADNameScheduleScreen();
    }
  }
}
