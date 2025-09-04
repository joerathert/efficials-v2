import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? selectedRole;

  void _handleRoleSelection(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  void _handleContinue() {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role to continue')),
      );
      return;
    }

    // Navigate to basic profile screen with selected role
    Navigator.pushNamed(
      context,
      '/basic-profile',
      arguments: {'role': selectedRole},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Icon(
              Icons.sports,
              color: themeProvider.isDarkMode
                  ? colorScheme.primary // Yellow in dark mode
                  : Colors.black, // Black in light mode
              size: 32,
            );
          },
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                tooltip: 'Toggle theme',
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                'Choose Your Role',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.brightness == Brightness.dark
                      ? colorScheme.primary // Yellow in dark mode
                      : colorScheme.onBackground, // Dark in light mode
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Select how you\'ll be using Efficials',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Scheduler Role Card
              _RoleCard(
                title: 'Scheduler',
                subtitle: 'Athletic Director, Coach, or Assigner',
                description:
                    'Create games, manage schedules, and assign officials',
                icon: Icons.event_note,
                isSelected: selectedRole == 'scheduler',
                onTap: () => _handleRoleSelection('scheduler'),
              ),

              const SizedBox(height: 20),

              // Official Role Card
              _RoleCard(
                title: 'Official',
                subtitle: 'Referee, Umpire, or Judge',
                description: 'View and claim available game assignments',
                icon: Icons.sports,
                isSelected: selectedRole == 'official',
                onTap: () => _handleRoleSelection('official'),
              ),

              const Spacer(),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.brightness == Brightness.light
                  ? Colors.grey
                      .shade100 // Light gray background when selected in light mode
                  : colorScheme.primary.withOpacity(
                      0.1) // Yellow background when selected in dark mode
              : theme.brightness == Brightness.light
                  ? Colors.grey
                      .shade50 // Light gray background for unselected in light mode
                  : colorScheme.surfaceVariant
                      .withOpacity(0.8), // Original dark mode styling
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.brightness == Brightness.light
                    ? Colors.black // Black border when selected in light mode
                    : colorScheme
                        .primary // Yellow border when selected in dark mode
                : theme.brightness == Brightness.light
                    ? Colors.black.withOpacity(
                        0.3) // Light black border for unselected in light mode
                    : colorScheme.outline
                        .withOpacity(0.3), // Original dark mode border
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.brightness == Brightness.light
                  ? Colors.black.withOpacity(
                      isSelected ? 0.2 : 0.1) // Softer shadows in light mode
                  : colorScheme.shadow.withOpacity(
                      isSelected ? 0.3 : 0.15), // Original dark mode shadows
              blurRadius: isSelected ? 12 : 6, // More shadow for selected cards
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
                  color: theme.brightness == Brightness.dark
                      ? colorScheme.primary // Yellow icons in dark mode
                      : colorScheme.onSurface, // Black icons in light mode
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
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.brightness == Brightness.light
                                  ? colorScheme
                                      .onSurface // Black text when selected in light mode
                                  : colorScheme
                                      .primary // Yellow text when selected in dark mode
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.brightness == Brightness.dark
                        ? colorScheme.primary // Yellow checkmark in dark mode
                        : Colors.black, // Black checkmark in light mode
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
