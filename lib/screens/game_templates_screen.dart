import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart'; // We'll create this
import '../services/game_service.dart';

class GameTemplatesScreen extends StatefulWidget {
  const GameTemplatesScreen({super.key});

  @override
  State<GameTemplatesScreen> createState() => _GameTemplatesScreenState();
}

class _GameTemplatesScreenState extends State<GameTemplatesScreen> {
  List<GameTemplateModel> templates = [];
  bool isLoading = true;
  List<String> sports = [];
  Map<String, List<GameTemplateModel>> groupedTemplates = {};

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    try {
      debugPrint('🔍 TEMPLATES SCREEN: Starting to fetch templates');
      final gameService = GameService();
      final fetchedTemplates = await gameService.getTemplates();

      debugPrint(
          '📊 TEMPLATES SCREEN: Received ${fetchedTemplates.length} templates from service');

      setState(() {
        templates = fetchedTemplates
            .where((template) =>
                template.id != '1' && template.id != '2' && template.id != '3')
            .toList(); // Filter out mock templates

        debugPrint(
            '📋 TEMPLATES SCREEN: After filtering: ${templates.length} templates');

        // Extract unique sports from templates
        Set<String> allSports = templates
            .where((t) => t.includeSport && t.sport != null)
            .map((t) => t.sport!)
            .toSet();

        sports = allSports.toList();
        sports.sort();

        debugPrint(
            '🏆 TEMPLATES SCREEN: Found ${sports.length} sports: $sports');

        // Group templates by sport
        _groupTemplatesBySport();

        isLoading = false;
        debugPrint('✅ TEMPLATES SCREEN: Template loading complete');
      });
    } catch (e) {
      debugPrint('🔴 TEMPLATES SCREEN: Error fetching templates: $e');
      setState(() {
        templates = [];
        sports = [];
        groupedTemplates = {};
        isLoading = false;
      });
    }
  }

  void _groupTemplatesBySport() {
    groupedTemplates.clear();

    for (var template in templates) {
      final sport = template.sport ?? 'Unknown';
      if (!groupedTemplates.containsKey(sport)) {
        groupedTemplates[sport] = [];
      }
      groupedTemplates[sport]!.add(template);
    }

    // Sort templates within each sport group by name
    for (var sportTemplates in groupedTemplates.values) {
      sportTemplates.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  void _showDeleteConfirmationDialog(
      String templateName, GameTemplateModel template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Confirm Delete',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$templateName"?',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            onPressed: () {
              Navigator.pop(context);
              _deleteTemplate(template);
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

  Future<void> _deleteTemplate(GameTemplateModel template) async {
    try {
      // For now, just remove from local list - we'll replace with actual service call
      setState(() {
        templates.removeWhere((t) => t.id == template.id);
        _groupTemplatesBySport();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting template: $e')),
        );
      }
    }
  }

  Future<void> _useTemplate(GameTemplateModel template) async {
    try {
      // Navigate to date/time screen with template
      Navigator.pushNamed(
        context,
        '/date-time',
        arguments: {
          'sport': template.sport,
          'template': template,
        },
      );
    } catch (e) {
      // Fallback to select schedule screen
      Navigator.pushNamed(
        context,
        '/select-schedule',
        arguments: {
          'sport': template.sport,
          'template': template,
        },
      );
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Game Templates',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Manage your saved game templates',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
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
                        children: [
                          isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : templates.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.description,
                                            size: 80,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No game templates found',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Create your first template to get started',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            height: 50,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                _createNewTemplate();
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    colorScheme.primary,
                                                foregroundColor:
                                                    colorScheme.onPrimary,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 15,
                                                        horizontal: 32),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              icon: Icon(
                                                Icons.add,
                                                color: colorScheme.onPrimary,
                                              ),
                                              label: Text(
                                                'Create New Template',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onPrimary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: templates.length,
                                      itemBuilder: (context, index) {
                                        final template = templates[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 12.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.shadow
                                                      .withOpacity(0.1),
                                                  blurRadius: 5,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            12),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme.primary
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Icon(
                                                      Icons.description,
                                                      color:
                                                          colorScheme.primary,
                                                      size: 24,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          template.name,
                                                          style: TextStyle(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: colorScheme
                                                                .onSurface,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          template.sport ??
                                                              'Unknown Sport',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                        ),
                                                        if (template
                                                                .description !=
                                                            null) ...[
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            template
                                                                .description!,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          _useTemplate(
                                                              template);
                                                        },
                                                        icon: Icon(
                                                          Icons.arrow_forward,
                                                          color: Colors.green,
                                                          size: 20,
                                                        ),
                                                        tooltip: 'Use Template',
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          // TODO: Navigate to edit template screen
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text(
                                                                    'Edit template coming soon!')),
                                                          );
                                                        },
                                                        icon: Icon(
                                                          Icons.edit,
                                                          color: colorScheme
                                                              .primary,
                                                          size: 20,
                                                        ),
                                                        tooltip:
                                                            'Edit Template',
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          _showDeleteConfirmationDialog(
                                                              template.name,
                                                              template);
                                                        },
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          color: Colors
                                                              .red.shade600,
                                                          size: 20,
                                                        ),
                                                        tooltip:
                                                            'Delete Template',
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                          if (!isLoading && templates.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Center(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _createNewTemplate();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15, horizontal: 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: Icon(
                                    Icons.add,
                                    color: colorScheme.onPrimary,
                                  ),
                                  label: Text(
                                    'Create New Template',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  void _createNewTemplate() {
    debugPrint('🚀 TEMPLATES SCREEN: Navigating to create template screen');
    Navigator.pushNamed(
      context,
      '/create_game_template',
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        debugPrint(
            '✅ TEMPLATES SCREEN: Template created, received result: ${result['name']}');
        // Template was created, refresh the list
        _fetchTemplates();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template created successfully!')),
        );
      } else {
        debugPrint(
            '⚠️ TEMPLATES SCREEN: Template creation returned null or invalid result: $result');
      }
    });
  }
}
