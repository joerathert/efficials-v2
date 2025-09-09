import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  String? selectedLocation;
  List<Map<String, dynamic>> locations = [];
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // Initialize with a default value to avoid empty list
    locations = [
      {'name': 'No saved locations', 'id': -1},
      {'name': '+ Create new location', 'id': 0},
    ];
    selectedLocation = locations[0]['name'] as String? ?? 'No saved locations';
    _fetchLocations();
  }

  // Helper method to ensure selectedLocation is valid
  void _validateSelectedLocation() {
    if (locations.isEmpty) {
      locations = [
        {'name': 'No saved locations', 'id': -1},
        {'name': '+ Create new location', 'id': 0},
      ];
    }
    if (!locations.any((loc) => loc['name'] == selectedLocation)) {
      selectedLocation =
          locations[0]['name'] as String? ?? 'No saved locations';
    }
  }

  Future<void> _fetchLocations() async {
    try {
      // Use LocationService to fetch from database
      final fetchedLocations = await _locationService.getLocations();

      setState(() {
        locations = [];

        // Add saved locations from database
        locations.addAll(fetchedLocations);

        // Add default options
        if (locations.isEmpty) {
          locations.add({'name': 'No saved locations', 'id': -1});
        }
        locations.add({'name': '+ Create new location', 'id': 0});

        // Ensure selectedLocation is valid
        if (selectedLocation == null ||
            !locations.any((loc) => loc['name'] == selectedLocation)) {
          selectedLocation = locations.first['name'] as String;
        }
      });
    } catch (e) {
      debugPrint('Error fetching locations: $e');
      setState(() {
        locations = [
          {'name': 'No saved locations', 'id': -1},
          {'name': '+ Create new location', 'id': 0},
        ];
        selectedLocation = 'No saved locations';
      });
    }
  }

  void _showDeleteConfirmationDialog(String locationName, int locationId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Confirm Delete',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$locationName"?',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Use LocationService to delete from database
                await _locationService.deleteLocation(locationId.toString());

                // Refresh the locations list
                await _fetchLocations();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Location deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting location: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Validate selectedLocation before rendering
    _validateSelectedLocation();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: const Icon(
          Icons.location_on,
          color: Colors.yellow,
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Locations',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your saved locations',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
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
                          selectedLocation == null
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
                                        'Choose from existing locations',
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
                                        setState(() {
                                          selectedLocation = newValue;
                                          if (newValue ==
                                              '+ Create new location') {
                                            Navigator.pushNamed(context,
                                                    '/add_new_location')
                                                .then((result) {
                                              if (result != null) {
                                                // Location was created successfully, refresh the list
                                                _fetchLocations();
                                                final newLocation = result
                                                    as Map<String, dynamic>;
                                                selectedLocation =
                                                    newLocation['name']
                                                            as String? ??
                                                        'Unknown Location';
                                              } else {
                                                _validateSelectedLocation();
                                              }
                                            });
                                          } else if (newValue !=
                                                  'No saved locations' &&
                                              !newValue!.startsWith('Error')) {
                                            selectedLocation = newValue;
                                          }
                                        });
                                      },
                                      items: locations.map((location) {
                                        final locationName =
                                            location['name'] as String;
                                        return DropdownMenuItem(
                                          value: locationName,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    locationName,
                                                    style: TextStyle(
                                                      color: locationName ==
                                                              'No saved locations'
                                                          ? Colors.red
                                                          : colorScheme
                                                              .onSurface,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: 400,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (selectedLocation == null ||
                                      selectedLocation ==
                                          'No saved locations' ||
                                      selectedLocation ==
                                          '+ Create new location')
                                  ? null
                                  : () {
                                      final selected = locations.firstWhere(
                                          (l) => l['name'] == selectedLocation);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              Container(), // Placeholder for edit screen
                                          settings: RouteSettings(
                                              arguments: selected),
                                        ),
                                      ).then((result) {
                                        if (result != null) {
                                          // Location was updated successfully, refresh the list
                                          _fetchLocations();
                                          final updatedLocation =
                                              result as Map<String, dynamic>;
                                          selectedLocation =
                                              updatedLocation['name']
                                                      as String? ??
                                                  'Unknown Location';
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content:
                                                    Text('Location updated!')),
                                          );
                                        }
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                disabledBackgroundColor: Colors.grey[600],
                                disabledForegroundColor: Colors.grey[300],
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15, horizontal: 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Edit Location',
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          selectedLocation != null &&
                                  selectedLocation != 'No saved locations' &&
                                  selectedLocation != '+ Create new location'
                              ? SizedBox(
                                  width: 400,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final selected = locations.firstWhere(
                                          (l) => l['name'] == selectedLocation);
                                      _showDeleteConfirmationDialog(
                                          selectedLocation!,
                                          selected['id'] as int? ?? 0);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Delete Location',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
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
