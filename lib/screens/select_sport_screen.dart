import 'package:flutter/material.dart';
import '../widgets/form_section.dart';
import '../widgets/standard_button.dart';

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
      Navigator.pushNamed(
        context,
        '/name-schedule',
        arguments: {'sport': selectedSport},
      );
      // No need to handle result here since NameScheduleScreen navigates directly back
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
            constraints: const BoxConstraints(maxWidth: 550),
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
                    'Choose the sport for your new schedule',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  FormSection(
                    children: [
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
                  const SizedBox(height: 40),
                  StandardButton(
                    text: 'Continue',
                    onPressed: selectedSport != null ? _handleContinue : null,
                    enabled: selectedSport != null,
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
