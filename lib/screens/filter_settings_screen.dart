import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class FilterSettingsScreen extends StatefulWidget {
  const FilterSettingsScreen({super.key});

  @override
  State<FilterSettingsScreen> createState() => _FilterSettingsScreenState();
}

class _FilterSettingsScreenState extends State<FilterSettingsScreen> {
  String? ihsaLevel;
  final _yearsController = TextEditingController();
  final Map<String, bool> competitionLevels = {
    'Grade School (6U-11U)': false,
    'Middle School (11U-14U)': false,
    'Underclass (15U-16U)': false,
    'JV (16U-17U)': false,
    'Varsity (17U-18U)': false,
    'College': false,
    'Adult': false,
  };

  final Map<String, String> levelMapping = {
    'Grade School (6U-11U)': 'Grade School',
    'Middle School (11U-14U)': 'Middle School',
    'Underclass (15U-16U)': 'Underclass',
    'JV (16U-17U)': 'JV',
    'Varsity (17U-18U)': 'Varsity',
    'College': 'College',
    'Adult': 'Adult',
  };
  final _radiusController = TextEditingController();
  String? defaultLocationName;
  String? defaultLocationAddress;

  @override
  void initState() {
    super.initState();
    _loadDefaultLocation();
  }

  Future<void> _loadDefaultLocation() async {
    // For now, just set some default values
    // In a real implementation, this would load from user preferences or school data
    setState(() {
      defaultLocationName = 'Sample High School';
      defaultLocationAddress = '123 Main St, Sample City, IL';
    });
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final sport = args?['sport'] as String? ?? 'Football';
    final locationData = args?['locationData'] as Map<String, dynamic>?;
    final isAwayGame = args?['isAwayGame'] as bool? ?? false;

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Filter Settings',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('IHSA Certification Level',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary)),
                          const SizedBox(height: 8),
                          const Text('Select minimum required level:',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                          const SizedBox(height: 12),
                          RadioListTile<String>(
                            title: Text('IHSA - Registered',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onSurface)),
                            subtitle: const Text(
                                'Includes Recognized and Certified officials',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            value: 'registered',
                            groupValue: ihsaLevel,
                            onChanged: (value) =>
                                setState(() => ihsaLevel = value),
                            activeColor: colorScheme.primary,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            dense: true,
                          ),
                          RadioListTile<String>(
                            title: Text('IHSA - Recognized',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onSurface)),
                            subtitle: const Text('Includes Certified officials',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            value: 'recognized',
                            groupValue: ihsaLevel,
                            onChanged: (value) =>
                                setState(() => ihsaLevel = value),
                            activeColor: colorScheme.primary,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            dense: true,
                          ),
                          RadioListTile<String>(
                            title: Text('IHSA - Certified',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.onSurface)),
                            subtitle: const Text('Only Certified officials',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            value: 'certified',
                            groupValue: ihsaLevel,
                            onChanged: (value) =>
                                setState(() => ihsaLevel = value),
                            activeColor: colorScheme.primary,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 0),
                            dense: true,
                          ),
                          const SizedBox(height: 20),
                          Text('Experience',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _yearsController,
                            decoration: InputDecoration(
                              hintText: 'Minimum years of experience',
                              hintStyle: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                              filled: true,
                              fillColor: colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: colorScheme.outline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            style: TextStyle(
                                fontSize: 16, color: colorScheme.onSurface),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            maxLength: 2,
                            buildCounter: (context,
                                    {required currentLength,
                                    required maxLength,
                                    required isFocused}) =>
                                null,
                          ),
                          const SizedBox(height: 20),
                          Text('Competition Levels',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary)),
                          const SizedBox(height: 12),
                          Column(
                            children: competitionLevels.keys.map((level) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: CheckboxListTile(
                                  title: Text(level,
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: colorScheme.onSurface)),
                                  value: competitionLevels[level],
                                  onChanged: (value) => setState(() =>
                                      competitionLevels[level] =
                                          value ?? false),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 0, vertical: 0),
                                  dense: true,
                                  activeColor: colorScheme.primary,
                                  checkColor: colorScheme.onPrimary,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                          Text('Location',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary)),
                          const SizedBox(height: 12),
                          if (isAwayGame) ...[
                            Text(
                              'Radius filtering unavailable for Away Games.',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                          ] else ...[
                            Text(
                              locationData != null
                                  ? 'Game Location: ${locationData['name']}'
                                  : defaultLocationName != null
                                      ? 'Game Location: $defaultLocationName'
                                      : 'Distance measured from your school\'s address',
                              style: TextStyle(
                                  fontSize: locationData == null &&
                                          defaultLocationName == null
                                      ? 14
                                      : 16,
                                  color: colorScheme.onSurface),
                            ),
                            if (locationData == null &&
                                defaultLocationAddress != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Using school address: $defaultLocationAddress',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextField(
                              controller: _radiusController,
                              decoration: InputDecoration(
                                hintText: 'Enter search radius (miles)',
                                hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                                filled: true,
                                fillColor: colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: colorScheme.outline),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 16, color: colorScheme.onSurface),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              maxLength: 3,
                              buildCounter: (context,
                                      {required currentLength,
                                      required maxLength,
                                      required isFocused}) =>
                                  null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 300,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!competitionLevels.values
                              .any((selected) => selected)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Please select at least one competition level!'),
                                backgroundColor: colorScheme.surfaceVariant,
                              ),
                            );
                            return;
                          }
                          if (!isAwayGame && _radiusController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                    'Please specify a search radius!'),
                                backgroundColor: colorScheme.surfaceVariant,
                              ),
                            );
                            return;
                          }
                          final selectedLevels = competitionLevels.entries
                              .where((entry) => entry.value)
                              .map((entry) => levelMapping[entry.key]!)
                              .toList();

                          final filterData = {
                            'sport': sport,
                            'ihsaLevel': ihsaLevel,
                            'minYears': _yearsController.text.isNotEmpty
                                ? int.parse(_yearsController.text)
                                : 0,
                            'levels': selectedLevels,
                            'locationData': locationData,
                            'radius': isAwayGame
                                ? null
                                : int.parse(_radiusController.text),
                          };

                          Navigator.pop(context, filterData);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Apply Filters',
                            style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
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
