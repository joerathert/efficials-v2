import 'package:flutter/material.dart';

class SchedulerTypeScreen extends StatefulWidget {
  const SchedulerTypeScreen({super.key});

  @override
  State<SchedulerTypeScreen> createState() => _SchedulerTypeScreenState();
}

class _SchedulerTypeScreenState extends State<SchedulerTypeScreen> {
  String? selectedType;
  Map<String, dynamic>? profileData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the profile data from navigation arguments
    profileData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  void _handleTypeSelection(String type) {
    setState(() {
      selectedType = type;
    });
  }

  void _handleContinue() {
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a scheduler type to continue')),
      );
      return;
    }

    // Add scheduler type to profile data
    final updatedData = Map<String, dynamic>.from(profileData ?? {});
    updatedData['schedulerType'] = selectedType;

    // Navigate to type-specific screen
    switch (selectedType) {
      case 'Athletic Director':
        Navigator.pushNamed(
          context,
          '/athletic-director-profile',
          arguments: updatedData,
        );
        break;
      case 'Coach':
        Navigator.pushNamed(
          context,
          '/coach-profile',
          arguments: updatedData,
        );
        break;
      case 'Assigner':
        Navigator.pushNamed(
          context,
          '/assigner-profile',
          arguments: updatedData,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Icon(
          Icons.sports,
          color: Colors.yellow,
          size: 32,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'What Type of Scheduler\n'),
                    TextSpan(text: 'Are You?'),
                  ],
                ),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose the option that best describes your role',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Athletic Director Card
              _SchedulerTypeCard(
                title: 'Athletic Director',
                description: 'Manage all sports and teams for a school',
                icon: Icons.location_city,
                details: [
                  '• Create games for multiple sports',
                  '• Manage school-wide schedules',
                  '• Coordinate with all teams',
                ],
                isSelected: selectedType == 'Athletic Director',
                onTap: () => _handleTypeSelection('Athletic Director'),
              ),

              const SizedBox(height: 20),

              // Coach Card
              _SchedulerTypeCard(
                title: 'Coach',
                description: 'Manage games for a specific team',
                icon: Icons.assignment,
                details: [
                  '• Create games for your team only',
                  '• Single sport focus',
                  '• Streamlined game creation',
                ],
                isSelected: selectedType == 'Coach',
                onTap: () => _handleTypeSelection('Coach'),
              ),

              const SizedBox(height: 20),

              // Assigner Card
              _SchedulerTypeCard(
                title: 'Assigner',
                description: 'Assign officials across multiple schools',
                icon: Icons.assignment_ind,
                details: [
                  '• Coordinate league/association games',
                  '• Assign officials to multiple schools',
                  '• Manage broader region',
                ],
                isSelected: selectedType == 'Assigner',
                onTap: () => _handleTypeSelection('Assigner'),
              ),

              const SizedBox(height: 40),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedulerTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<String> details;
  final bool isSelected;
  final VoidCallback onTap;

  const _SchedulerTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.details,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.yellow.withOpacity(0.1) : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.yellow : Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.yellow : Colors.white,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.yellow,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...details.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    detail,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[300],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
