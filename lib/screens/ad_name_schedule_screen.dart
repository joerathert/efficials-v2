import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_theme.dart';
import '../services/user_repository.dart';
import '../services/game_service.dart';
import '../models/user_model.dart';

class ADNameScheduleScreen extends StatefulWidget {
  const ADNameScheduleScreen({super.key});

  @override
  State<ADNameScheduleScreen> createState() => _ADNameScheduleScreenState();
}

class _ADNameScheduleScreenState extends State<ADNameScheduleScreen> {
  final _nameController = TextEditingController();
  final UserRepository _userRepository = UserRepository();

  UserModel? currentUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      currentUser = await _userRepository.getCurrentUser();
    } catch (e) {
      debugPrint('Error loading current user: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name!')),
      );
      return;
    }

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Unknown';

    // For ADs, use their organization name from profile for home team
    String homeTeamName = currentUser?.schedulerProfile?.organizationName ?? '';
    if (homeTeamName.isEmpty) {
      homeTeamName = 'Default Organization'; // Fallback
    }

    try {
      // Save the schedule to Firebase using GameService
      final gameService = GameService();
      final newSchedule = await gameService.createSchedule(
        name,
        sport,
      );

      // Add the home team info to the returned data
      final scheduleData = {
        ...newSchedule,
        'homeTeam': homeTeamName,
      };

      Navigator.pop(context, scheduleData);
    } catch (e) {
      // Fallback: return local data if Firebase fails
      final scheduleData = {
        'name': name,
        'homeTeam': homeTeamName,
        'sport': sport,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      Navigator.pop(context, scheduleData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: AppColors.efficialsYellow,
          size: 32,
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.efficialsYellow))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'Name Your Schedule',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.efficialsYellow,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Schedule Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.efficialsYellow,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'This will appear as the title on your schedule list',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Ex. Varsity Football',
                                hintStyle: TextStyle(color: secondaryTextColor),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.efficialsYellow),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.efficialsYellow, width: 2),
                                ),
                              ),
                              style: const TextStyle(fontSize: 16, color: AppColors.efficialsWhite),
                            ),
                            if (currentUser?.schedulerProfile?.organizationName != null &&
                                currentUser!.schedulerProfile!.organizationName!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.efficialsBlue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.efficialsBlue.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: AppColors.efficialsBlue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Your organization name "${currentUser!.schedulerProfile!.organizationName}" will be used for all home games.',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.efficialsBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.efficialsYellow,
                          foregroundColor: AppColors.efficialsBlack,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
