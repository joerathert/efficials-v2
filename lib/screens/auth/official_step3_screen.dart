import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class OfficialStep3Screen extends StatefulWidget {
  const OfficialStep3Screen({super.key});

  @override
  State<OfficialStep3Screen> createState() => _OfficialStep3ScreenState();
}

class _OfficialStep3ScreenState extends State<OfficialStep3Screen> {
  // Available sports and their certification levels (matching coach profile)
  final List<String> availableSports = [
    'Baseball',
    'Basketball',
    'Football',
    'Soccer',
    'Softball',
    'Volleyball'
  ];

  final List<String> certificationLevels = [
    'IHSA Registered',
    'IHSA Recognized',
    'IHSA Certified',
    'No Certification',
  ];

  final List<String> competitionLevels = [
    'Grade School (6U-11U)',
    'Middle School (11U-14U)',
    'Underclass (15U-16U)',
    'Junior Varsity (16U-17U)',
    'Varsity (17U-18U)',
    'College',
    'Adult',
  ];

  // Selected sports with their details
  Map<String, Map<String, dynamic>> selectedSports = {};
  // Maintain order of sports (most recently added first)
  List<String> sportsOrder = [];

  late Map<String, dynamic> previousData;

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    previousData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // Initialize selectedSports from previous data if it exists
    if (previousData.containsKey('selectedSports')) {
      final previousSports = previousData['selectedSports']
          as Map<String, Map<String, dynamic>>;
      setState(() {
        selectedSports = Map<String, Map<String, dynamic>>.from(previousSports);
        // Initialize order with existing sports (most recently added first)
        sportsOrder = previousSports.keys.toList().reversed.toList();
      });
      // Scroll to top after initialization
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _addSport(String sport) {
    if (!selectedSports.containsKey(sport)) {
      setState(() {
        selectedSports[sport] = {
          'certification': null,
          'experience': null, // Changed from 0 to null for proper empty field handling
          'competitionLevels': <String>[],
        };
        // Add to the beginning of the order list so it appears at the top
        sportsOrder.insert(0, sport);
      });
      // Scroll to top to show the new sport
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _removeSport(String sport) {
    setState(() {
      selectedSports.remove(sport);
      sportsOrder.remove(sport);
    });
  }

  void _handleContinue() {
    // Validate that at least one sport is selected
    if (selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select at least one sport you can officiate')),
      );
      return;
    }

    // Validate that each sport has at least one competition level
    for (var entry in selectedSports.entries) {
      if (entry.value['competitionLevels'].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Please select competition levels for ${entry.key}')),
        );
        return;
      }
    }

    final updatedData = {
      ...previousData,
      'selectedSports': selectedSports,
    };

    // Navigate to step 4
    Navigator.pushNamed(
      context,
      '/official-step4',
      arguments: updatedData,
    );
  }

  void _showAddSportDialog() {
    final availableToAdd = availableSports
        .where((sport) => !selectedSports.containsKey(sport))
        .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You have already added all available sports')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Select a Sport',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableToAdd.length,
              itemBuilder: (context, index) {
                final sport = availableToAdd[index];
                return ListTile(
                  title: Text(
                    sport,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _addSport(sport);
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
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

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? Colors.black
          : colorScheme.background,
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
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Title - Sports & Certifications
                  Center(
                    child: Text(
                      'Sports & Certifications',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary // Yellow in dark mode
                            : colorScheme.onBackground, // Dark in light mode
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Subtitle - Step 3 of 4: Your Officiating Experience
                  Center(
                    child: Text(
                      'Step 3 of 4: Your Officiating Experience',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Form Fields
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedSports.isEmpty)
                            Column(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Text(
                                      'No sports added yet.\nTap "Add Sport" to get started.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: SizedBox(
                                    width: 300,
                                    child: ElevatedButton(
                                      onPressed: _showAddSportDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            theme.brightness == Brightness.dark
                                                ? colorScheme.primary
                                                : Colors.black,
                                        foregroundColor:
                                            theme.brightness == Brightness.dark
                                                ? Colors.black
                                                : Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Add Sport',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: SizedBox(
                                    width: 300,
                                    child: ElevatedButton(
                                      onPressed: selectedSports.isNotEmpty
                                          ? _handleContinue
                                          : null,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        backgroundColor: selectedSports.isEmpty
                                            ? Colors.grey[400]
                                            : null,
                                        foregroundColor: selectedSports.isEmpty
                                            ? Colors.grey[600]
                                            : null,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                ...sportsOrder.map((sportName) =>
                                    _buildSportCard(sportName, selectedSports[sportName]!)),
                                const SizedBox(height: 32),

                                // Button Row - Add Sport above Continue
                                Center(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: 300,
                                        child: OutlinedButton(
                                          onPressed: _showAddSportDialog,
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            side: BorderSide(
                                              color: theme.brightness ==
                                                      Brightness.dark
                                                  ? colorScheme.primary
                                                  : Colors.black,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            'Add Another Sport',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: theme.brightness ==
                                                      Brightness.dark
                                                  ? colorScheme.primary
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: 300,
                                        child: ElevatedButton(
                                          onPressed: selectedSports.isNotEmpty
                                              ? _handleContinue
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 16),
                                            backgroundColor:
                                                selectedSports.isEmpty
                                                    ? Colors.grey[400]
                                                    : null,
                                            foregroundColor:
                                                selectedSports.isEmpty
                                                    ? Colors.grey[600]
                                                    : null,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSportCard(String sport, Map<String, dynamic> sportData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      color: theme.brightness == Brightness.dark
          ? colorScheme.surfaceVariant
          : colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: SizedBox(
        width: 280,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        sport,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? colorScheme.primary // Yellow in dark mode
                              : colorScheme.onBackground, // Dark in light mode
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _removeSport(sport),
                    icon: Icon(
                      Icons.delete,
                      color: theme.brightness == Brightness.dark
                          ? Colors.red[400]
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Years of Experience Field (moved up)
              SizedBox(
                width: 240,
                child: TextFormField(
                  initialValue: sportData['experience'] == null
                      ? null
                      : sportData['experience'].toString(),
                  decoration: InputDecoration(
                    labelText: 'Years of Experience',
                    hintText: 'Set years of experience',
                    labelStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary // Yellow for dark mode
                            : Colors.black, // Black for light mode
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark
                        ? Colors.grey[700]
                        : colorScheme.surface,
                  ),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    sportData['experience'] = value.isEmpty ? null : int.tryParse(value) ?? 0;
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Certification Level Dropdown
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<String>(
                  value: sportData['certification'],
                  decoration: InputDecoration(
                    labelText: 'Certification Level',
                    labelStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary // Yellow for dark mode
                            : Colors.black, // Black for light mode
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark
                        ? Colors.grey[700]
                        : colorScheme.surface,
                  ),
                  hint: Text(
                    'Select certification level',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  dropdownColor: colorScheme.surface,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  items: certificationLevels.map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      sportData['certification'] = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Competition Levels
              Text(
                'Competition Levels:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: competitionLevels.map((level) {
                  final isSelected =
                      (sportData['competitionLevels'] as List<String>)
                          .contains(level);
                  return Container(
                    width: 240,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: FilterChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(
                          level,
                          textAlign: TextAlign.left,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            (sportData['competitionLevels'] as List<String>)
                                .add(level);
                          } else {
                            (sportData['competitionLevels'] as List<String>)
                                .remove(level);
                          }
                        });
                      },
                      selectedColor: theme.brightness == Brightness.dark
                          ? colorScheme.primary
                          : Colors.black,
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.grey[700]
                          : Colors.grey[200],
                      checkmarkColor: theme.brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (theme.brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white)
                            : colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
