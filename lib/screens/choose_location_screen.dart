import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart';
import '../services/location_service.dart';

class ChooseLocationScreen extends StatefulWidget {
  const ChooseLocationScreen({super.key});

  @override
  State<ChooseLocationScreen> createState() => _ChooseLocationScreenState();
}

class _ChooseLocationScreenState extends State<ChooseLocationScreen> {
  String? selectedLocation;
  List<Map<String, dynamic>> locations = [];
  bool isLoading = true;
  GameTemplateModel? template;
  String? scheduleName;
  String? sport;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final route = ModalRoute.of(context);
    if (route != null) {
      final args = route.settings.arguments;
      if (args is Map<String, dynamic>) {
        scheduleName = args['scheduleName'] as String?;
        sport = args['sport'] as String?;
        template = args['template'] as GameTemplateModel?;
        selectedDate = args['date'] as DateTime?;
        selectedTime = args['time'] as TimeOfDay?;
        // Pre-select the location if it exists in the arguments
        if (args.containsKey('location') && args['location'] != null) {
          selectedLocation = args['location'] as String?;
        }
        debugPrint('🎯 CHOOSE_LOCATION: Received template: ${template?.name}');
        debugPrint(
            '🎯 CHOOSE_LOCATION: Template location: ${template?.location}');
        debugPrint(
            '🎯 CHOOSE_LOCATION: Template includeLocation: ${template?.includeLocation}');
        debugPrint(
            '🎯 CHOOSE_LOCATION: Pre-selected location: $selectedLocation');
      }
    }
  }

  Future<void> _fetchLocations() async {
    try {
      final locationService = LocationService();
      print('ChooseLocationScreen: Fetching locations...');
      final savedLocations = await locationService.getLocations();

      setState(() {
        locations = [
          {'name': 'Away Game', 'id': 2},
          // Add saved locations from Firebase
          ...savedLocations.map((location) => {
                'name': location['name'] as String,
                'id': location['id'] as String,
                'address': location['address'] as String,
                'city': location['city'] as String,
                'state': location['state'] as String,
                'zip': location['zip'] as String,
              }),
          {'name': '+ Create new location', 'id': 0},
        ];
        isLoading = false;
      });

      print(
          'ChooseLocationScreen: Processed ${locations.length} total locations (${savedLocations.length} from Firebase)');
    } catch (e) {
      print('Error fetching locations: $e');
      setState(() {
        locations = [
          {'name': 'Away Game', 'id': 2},
          {'name': '+ Create new location', 'id': 0},
        ];
        isLoading = false;
      });
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
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Icon(
              Icons.sports,
              color:
                  themeProvider.isDarkMode ? colorScheme.primary : Colors.black,
              size: 32,
            );
          },
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Choose Location',
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
                      'Where will the game be played?',
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
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              'Schedule: ${scheduleName ?? "Not set"}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Sport: ${sport ?? "Not set"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Date: ${selectedDate != null ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}' : "Not set"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Time: ${selectedTime != null ? selectedTime!.format(context) : "Not set"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 30),
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 400),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: DropdownButtonFormField<String>(
                                      decoration: InputDecoration(
                                        labelText: 'Select a location',
                                        labelStyle: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colorScheme.outline,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colorScheme.outline,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surface,
                                      ),
                                      value: selectedLocation,
                                      hint: Text(
                                        'Choose a location',
                                        style: TextStyle(
                                            color:
                                                colorScheme.onSurfaceVariant),
                                      ),
                                      dropdownColor: colorScheme.surface,
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                        fontSize: 16,
                                      ),
                                      onChanged: (newValue) {
                                        if (newValue ==
                                            '+ Create new location') {
                                          Navigator.pushNamed(
                                            context,
                                            '/add-new-location',
                                            arguments: {
                                              'scheduleName': scheduleName,
                                              'sport': sport,
                                              'template': template,
                                              'date': selectedDate,
                                              'time': selectedTime,
                                            },
                                          ).then((result) {
                                            if (result != null) {
                                              final newLoc = result
                                                  as Map<String, dynamic>;
                                              setState(() {
                                                locations.insert(
                                                    locations.length - 1, {
                                                  'name': newLoc['name'],
                                                  'address': newLoc['address'],
                                                  'city': newLoc['city'],
                                                  'state': newLoc['state'],
                                                  'zip': newLoc['zip'],
                                                  'id': newLoc['id'],
                                                });
                                                selectedLocation =
                                                    newLoc['name'];
                                              });
                                            }
                                          });
                                        } else {
                                          setState(() {
                                            selectedLocation = newValue;
                                          });
                                        }
                                      },
                                      items: locations.map((location) {
                                        final locationName =
                                            location['name'] as String;
                                        return DropdownMenuItem(
                                          value: locationName,
                                          child: Text(locationName),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 40),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: 400,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (selectedLocation != null &&
                                      selectedLocation !=
                                          '+ Create new location')
                                  ? () {
                                      final isAwayGame =
                                          selectedLocation == 'Away Game';
                                      Navigator.pushNamed(
                                        context,
                                        isAwayGame
                                            ? '/additional-game-info-condensed'
                                            : '/additional-game-info',
                                        arguments: {
                                          'scheduleName': scheduleName,
                                          'sport': sport,
                                          'template': template,
                                          'date': selectedDate,
                                          'time': selectedTime,
                                          'location': selectedLocation,
                                          'isAwayGame': isAwayGame,
                                          'isAway': isAwayGame,
                                        },
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                disabledBackgroundColor: Colors.grey[600],
                                disabledForegroundColor: Colors.grey[300],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
