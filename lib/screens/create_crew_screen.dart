import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_colors.dart';
import '../models/crew_model.dart';
import '../services/user_service.dart';

class CreateCrewScreen extends StatefulWidget {
  const CreateCrewScreen({super.key});

  @override
  State<CreateCrewScreen> createState() => _CreateCrewScreenState();
}

class _CreateCrewScreenState extends State<CreateCrewScreen> {
  final CrewRepository _crewRepo = CrewRepository();
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  List<Map<String, dynamic>> _crewTypes = [];
  Map<String, dynamic>? _selectedCrewType;
  final List<String> _selectedCompetitionLevels = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _currentUserId;

  final List<String> _competitionLevels = [
    'Grade School (6U-11U)',
    'Middle School (12U-14U)',
    'Underclass (15U-16U)',
    'Junior Varsity (16U-17U)',
    'Varsity (17U-18U)',
    'College',
    'Adult',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _currentUserId = user.uid;

      // Load crew types
      print('🔍 CREATE CREW: Loading crew types from database');
      final crewTypes = await _crewRepo.getAllCrewTypes();
      print('✅ CREATE CREW: Found ${crewTypes.length} crew types in database');

      // If no crew types exist, provide some defaults and save them to the database
      List<Map<String, dynamic>> finalCrewTypes;
      if (crewTypes.isEmpty) {
        print('⚠️ CREATE CREW: No crew types found, using defaults and saving to database');
        finalCrewTypes = [
          {
            'id': 1,
            'sport_name': 'Basketball',
            'level_of_competition': 'Varsity',
            'required_officials': 3,
            'sport_id': 1,
          },
          {
            'id': 2,
            'sport_name': 'Basketball',
            'level_of_competition': 'Varsity',
            'required_officials': 2,
            'sport_id': 1,
          },
          {
            'id': 3,
            'sport_name': 'Football',
            'level_of_competition': 'Varsity',
            'required_officials': 5,
            'sport_id': 2,
          },
          {
            'id': 4,
            'sport_name': 'Football',
            'level_of_competition': 'Varsity',
            'required_officials': 4,
            'sport_id': 2,
          },
          {
            'id': 5,
            'sport_name': 'Baseball',
            'level_of_competition': 'Varsity',
            'required_officials': 2,
            'sport_id': 4,
          },
          {
            'id': 6,
            'sport_name': 'Baseball',
            'level_of_competition': 'Varsity',
            'required_officials': 3,
            'sport_id': 4,
          },
          {
            'id': 7,
            'sport_name': 'Softball',
            'level_of_competition': 'Varsity',
            'required_officials': 2,
            'sport_id': 5,
          },
          {
            'id': 8,
            'sport_name': 'Volleyball',
            'level_of_competition': 'Varsity',
            'required_officials': 2,
            'sport_id': 6,
          },
        ];

        // Save crew types to database so they're available for crew loading
        print('🔄 CREW TYPES: Saving default crew types to database');
        await _crewRepo.saveDefaultCrewTypes(finalCrewTypes);
        print('✅ CREW TYPES: Default crew types saved to database');
      } else {
        finalCrewTypes = crewTypes;
      }

      if (mounted) {
        setState(() {
          _crewTypes = finalCrewTypes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Failed to load data: ${e.toString()}');
      }
    }
  }

  Future<void> _createCrew() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCrewType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crew type')),
      );
      return;
    }
    if (_selectedCompetitionLevels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one competition level')),
      );
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create the crew
      final crew = Crew(
        name: _nameController.text.trim(),
        crewTypeId: _selectedCrewType!['id'] as int,
        crewChiefId: _currentUserId!,
        createdBy: _currentUserId!,
        isActive: true,
        paymentMethod: 'equal_split',
        competitionLevels: _selectedCompetitionLevels,
        sportName: _selectedCrewType!['sport_name'] as String?,
        levelOfCompetition: _selectedCrewType!['level_of_competition'] as String?,
        requiredOfficials: _selectedCrewType!['required_officials'] as int?,
      );

      // Get current user info for invitation
      final currentUser = await _userService.getCurrentUser();
      if (currentUser != null) {
        final userData = {
          'id': currentUser.id,
          'name': currentUser.fullName,
          'email': currentUser.email,
        };

        // Create crew with chief as member and potentially invite others
        final crewId = await _crewRepo.createCrewWithMembersAndInvitations(
          crew: crew,
          selectedMembers: [userData], // Just the chief for now
          crewChiefId: _currentUserId!,
        );

        if (crewId != null && mounted) {

          if (crewId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Crew created successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate back to dashboard
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Crew created but failed to add members. Please try again.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create crew. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error creating crew: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating crew: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text(
          'Error',
          style: TextStyle(color: AppColors.efficialsWhite),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppColors.efficialsWhite),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.efficialsYellow),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.efficialsBlack,
          title: const Text(
            'Create Crew',
            style: TextStyle(color: AppColors.efficialsWhite),
          ),
          iconTheme: const IconThemeData(color: AppColors.efficialsWhite),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.efficialsYellow),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text(
          'Create New Crew',
          style: TextStyle(color: AppColors.efficialsWhite),
        ),
        iconTheme: const IconThemeData(color: AppColors.efficialsWhite),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Form a New Crew',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.efficialsYellow,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create a crew to work games together with other officials',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Crew Name
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.efficialsWhite),
                  decoration: InputDecoration(
                    labelText: 'Crew Name',
                    labelStyle: const TextStyle(color: Colors.grey),
                    hintText: 'Enter a unique name for your crew',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    filled: true,
                    fillColor: AppColors.darkSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.efficialsYellow),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a crew name';
                    }
                    if (value.trim().length < 3) {
                      return 'Crew name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Crew Type Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crew Type',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.efficialsWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select the type of crew based on sport and number of officials',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: _selectedCrewType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.efficialsBlack,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.efficialsYellow),
                          ),
                        ),
                        dropdownColor: AppColors.efficialsBlack,
                        style: const TextStyle(color: AppColors.efficialsWhite),
                        hint: const Text(
                          'Select crew type',
                          style: TextStyle(color: Colors.grey),
                        ),
                        items: _crewTypes.map((crewType) {
                          final sportName = crewType['sport_name'] ?? 'Unknown Sport';
                          final requiredOfficials = crewType['required_officials'] ?? 0;

                          return DropdownMenuItem(
                            value: crewType,
                            child: Text(
                              '$sportName - $requiredOfficials officials',
                              style: const TextStyle(color: AppColors.efficialsWhite),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCrewType = value);
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a crew type';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Competition Levels
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Competition Levels',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.efficialsWhite,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select the competition levels this crew will officiate',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _competitionLevels.map((level) {
                          final isSelected = _selectedCompetitionLevels.contains(level);
                          return FilterChip(
                            label: Text(level),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCompetitionLevels.add(level);
                                } else {
                                  _selectedCompetitionLevels.remove(level);
                                }
                              });
                            },
                            backgroundColor: AppColors.efficialsBlack,
                            selectedColor: AppColors.efficialsYellow.withOpacity(0.3),
                            checkmarkColor: AppColors.efficialsYellow,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.efficialsYellow : Colors.grey,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _createCrew,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.efficialsYellow,
                      foregroundColor: AppColors.efficialsBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : const Text(
                            'Create Crew',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
