import 'package:flutter/material.dart';

class SelectSportScreen extends StatefulWidget {
  const SelectSportScreen({super.key});

  @override
  State<SelectSportScreen> createState() => _SelectSportScreenState();
}

class _SelectSportScreenState extends State<SelectSportScreen> {
  String? selectedSport;
  final List<String> sports = [
    'Football',
    'Basketball',
    'Baseball',
    'Soccer',
    'Volleyball',
    'Other'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if coming from a template flow and pre-fill the sport
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['sport'] != null) {
      selectedSport = args['sport'] as String?;
    }
  }

  void _handleContinue() {
    if (selectedSport != null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final fromListsScreen = args?['fromListsScreen'] == true;

      if (fromListsScreen) {
        // Return the selected sport to the lists screen
        Navigator.pop(context, selectedSport);
      } else {
        // Normal flow - navigate to name schedule
        Navigator.pushNamed(
          context,
          '/name-schedule',
          arguments: {'sport': selectedSport},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final fromListsScreen = args?['fromListsScreen'] == true;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Icon(
          Icons.sports,
          color: theme.brightness == Brightness.dark
              ? colorScheme.primary
              : Colors.black,
          size: 32,
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'Select Sport',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? colorScheme.primary
                          : colorScheme.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fromListsScreen
                        ? 'Choose the sport for your new list of officials'
                        : 'Choose the sport for your new schedule',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Choose your sport',
                          style: TextStyle(
                            fontSize: 18,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Select a sport',
                            labelStyle: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.outline,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                          ),
                          value: selectedSport,
                          dropdownColor: colorScheme.surface,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                          ),
                          onChanged: (newValue) {
                            setState(() {
                              selectedSport = newValue;
                            });
                          },
                          items: sports.map((sport) {
                            return DropdownMenuItem(
                              value: sport,
                              child: Text(
                                sport,
                                style: TextStyle(color: colorScheme.onSurface),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 400,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: selectedSport != null ? _handleContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedSport != null
                            ? colorScheme.primary
                            : colorScheme.surfaceVariant,
                        foregroundColor: selectedSport != null
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selectedSport != null
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
