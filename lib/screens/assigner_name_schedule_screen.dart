import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_colors.dart';
import '../app_theme.dart';
import '../services/user_repository.dart';
import '../services/game_service.dart';
import '../models/user_model.dart';

class AssignerNameScheduleScreen extends StatefulWidget {
  const AssignerNameScheduleScreen({super.key});

  @override
  State<AssignerNameScheduleScreen> createState() => _AssignerNameScheduleScreenState();
}

class _AssignerNameScheduleScreenState extends State<AssignerNameScheduleScreen> {
  final _nameController = TextEditingController();
  final _homeTeamController = TextEditingController();
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
    _homeTeamController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    final name = _nameController.text.trim();
    final homeTeamName = _homeTeamController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a schedule name!')),
      );
      return;
    }

    if (homeTeamName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a home team name!')),
      );
      return;
    }

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Unknown';

    try {
      // Try to create schedule using database service first
      // For now, we'll use the GameService from the existing codebase
      final gameService = GameService();

      final newSchedule = await gameService.createSchedule(
        name,
        sport,
        homeTeamName: homeTeamName,
      );

      // Schedule created successfully
      Navigator.pop(context, newSchedule);
    } catch (e) {
      // Fallback to SharedPreferences if database fails
      await _handleContinueWithPrefs(name, sport);
    }
  }

  Future<void> _handleContinueWithPrefs(String name, String sport) async {
    // Save the schedule to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? unpublishedGamesJson = prefs.getString('unpublished_games');
    List<Map<String, dynamic>> unpublishedGames = [];
    if (unpublishedGamesJson != null && unpublishedGamesJson.isNotEmpty) {
      unpublishedGames =
          List<Map<String, dynamic>>.from(jsonDecode(unpublishedGamesJson));
    }

    final scheduleEntry = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'scheduleName': name,
      'sport': sport,
      'createdAt': DateTime.now().toIso8601String(),
    };
    unpublishedGames.add(scheduleEntry);
    await prefs.setString('unpublished_games', jsonEncode(unpublishedGames));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule created!')),
      );

      // Return the new schedule data to the calling screen
      Navigator.pop(context, {
        'name': name,
        'id': scheduleEntry['id'],
        'sport': sport,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            ? const Center(
                child:
                    CircularProgressIndicator(color: AppColors.efficialsYellow))
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
                              decoration: InputDecoration(
                                hintText: 'Ex. - Edwardsville Varsity',
                                hintStyle: TextStyle(
                                    color: secondaryTextColor.withOpacity(0.7)),
                                fillColor: AppColors.darkSurface,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color:
                                          secondaryTextColor.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color:
                                          secondaryTextColor.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.efficialsYellow,
                                      width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.efficialsWhite),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Home Team Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.efficialsYellow,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'This will be used when scheduling games (e.g., "Opponent @ Home Team")',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _homeTeamController,
                              decoration: InputDecoration(
                                hintText: 'Ex. - Edwardsville Tigers',
                                hintStyle: TextStyle(
                                    color: secondaryTextColor.withOpacity(0.7)),
                                fillColor: AppColors.darkSurface,
                                filled: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color:
                                          secondaryTextColor.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color:
                                          secondaryTextColor.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.efficialsYellow,
                                      width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.efficialsWhite),
                            ),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.efficialsBlack,
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
