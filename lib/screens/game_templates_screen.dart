import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/game_template_model.dart'; // We'll create this
import '../services/game_service.dart';
import '../services/auth_service.dart';

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
  String? expandedTemplateId;

  // Helper method to get sport-specific icons
  IconData _getSportIcon(String? sport) {
    if (sport == null) return Icons.description;
    switch (sport.toLowerCase()) {
      case 'football':
        return Icons.sports_football;
      case 'basketball':
        return Icons.sports_basketball;
      case 'soccer':
        return Icons.sports_soccer;
      case 'baseball':
        return Icons.sports_baseball;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'tennis':
        return Icons.sports_tennis;
      default:
        return Icons.sports;
    }
  }

  // For schedule association
  String? scheduleName;
  String? sport;
  bool isFromScheduleDetails = false;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get arguments from navigation
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      scheduleName = args['scheduleName'] as String?;
      sport = args['sport'] as String?;
      isFromScheduleDetails = scheduleName != null;

      debugPrint(
          '🎯 TEMPLATES SCREEN: From schedule details: $isFromScheduleDetails');
      debugPrint('🎯 TEMPLATES SCREEN: Schedule: $scheduleName, Sport: $sport');

      // Always refresh templates to ensure we have the latest data
    }

    // Always refresh templates to ensure we have the latest data
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    try {
      debugPrint('🔍 TEMPLATES SCREEN: Starting to fetch templates');
      final gameService = GameService();
      final fetchedTemplates = await gameService.getTemplates();

      debugPrint(
          '📊 TEMPLATES SCREEN: Received ${fetchedTemplates.length} templates from service');

      // Log details about each template
      for (var template in fetchedTemplates) {
        debugPrint(
            '📋 TEMPLATE: ID=${template.id}, Name=${template.name}, CreatedBy=${template.createdAt}');
      }

      setState(() {
        templates = fetchedTemplates
            .where((template) =>
                template.id != '1' && template.id != '2' && template.id != '3')
            .toList(); // Filter out mock templates

        debugPrint(
            '📋 TEMPLATES SCREEN: After mock filter: ${templates.length} templates');

        // Apply sport filtering if coming from schedule details
        if (isFromScheduleDetails && sport != null && sport != 'Unknown') {
          templates = templates.where((template) {
            // Include templates that don't specify a sport, or match the schedule's sport
            return !template.includeSport ||
                template.sport == null ||
                template.sport == sport;
          }).toList();
          debugPrint(
              '🎯 TEMPLATES SCREEN: Filtered by sport "$sport": ${templates.length} templates');
        }

        debugPrint(
            '📋 TEMPLATES SCREEN: After all filtering: ${templates.length} templates');

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
      // Delete from Firestore
      final gameService = GameService();
      await gameService.deleteTemplate(template.id);

      // Remove from local list
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
      debugPrint('🎯 Using template: ${template.name}');

      // Check if we're associating template with schedule or creating new game
      if (isFromScheduleDetails && scheduleName != null) {
        debugPrint(
            '🎯 TEMPLATES SCREEN: Associating template with schedule: $scheduleName');

        // Associate template with schedule in Firestore
        final gameService = GameService();
        await gameService.saveTemplateAssociation(
          scheduleName!,
          template.id,
          template.toJson(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Template "${template.name}" associated with schedule "$scheduleName"'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to schedule details
          Navigator.pop(context, true);
        }
      } else {
        debugPrint('📋 Template config:');
        debugPrint(
            '   - Location: ${template.includeLocation && template.location != null ? template.location : 'not set'}');
        debugPrint(
            '   - Time: ${template.includeTime && template.time != null ? template.time!.format(context) : 'not set'}');
        debugPrint(
            '   - Date: ${template.includeDate && template.date != null ? template.date : 'not set'}');
        debugPrint(
            '   - Include flags: Date=${template.includeDate}, Time=${template.includeTime}, Location=${template.includeLocation}');

        // Always start with schedule selection - every game needs a schedule
        debugPrint(
            '📅 Starting with schedule selection for template: ${template.name}');
        Navigator.pushNamed(
          context,
          '/select-schedule',
          arguments: {
            'sport': template.sport,
            'template': template,
          },
        );
      }
    } catch (e) {
      debugPrint('🔴 Error using template: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildTemplateDetails(GameTemplateModel template) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Template Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        // Basic Information
        if (template.includeDate && template.date != null)
          _buildDetailRow(
              'Date', DateFormat('EEEE, MMMM d, y').format(template.date!)),

        if (template.includeTime && template.time != null)
          _buildDetailRow('Time', template.time!.format(context)),

        if (template.includeLocation && template.location?.isNotEmpty == true)
          _buildDetailRow('Location', template.location!),

        if (template.includeOpponent && template.opponent?.isNotEmpty == true)
          _buildDetailRow('Opponent', template.opponent!),

        if (template.includeLevelOfCompetition &&
            template.levelOfCompetition?.isNotEmpty == true)
          _buildDetailRow('Level', template.levelOfCompetition!),

        if (template.includeGender && template.gender?.isNotEmpty == true)
          _buildDetailRow('Gender', template.gender!),

        if (template.includeOfficialsRequired &&
            template.officialsRequired != null)
          _buildDetailRow(
              'Officials Required', '${template.officialsRequired}'),

        if (template.includeGameFee && template.gameFee?.isNotEmpty == true)
          _buildDetailRow('Game Fee', '\$${template.gameFee}'),

        if (template.includeHireAutomatically &&
            template.hireAutomatically != null)
          _buildDetailRow(
              'Auto Hire', template.hireAutomatically! ? 'Yes' : 'No'),

        // Officials Information
        if (template.method != null) ...[
          const SizedBox(height: 8),
          const Divider(color: Colors.grey, thickness: 0.5),
          const SizedBox(height: 8),
          const Text(
            'Officials Assignment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Method', _getMethodDisplayName(template.method)),
        ],

        // Show officials list name if method is use_list
        if (template.method == 'use_list' &&
            template.officialsListName?.isNotEmpty == true)
          _buildDetailRow('Selected List', template.officialsListName!),

        // Show selected lists if method is advanced (Multiple Lists)
        if (template.method == 'advanced' &&
            template.selectedLists != null &&
            template.selectedLists!.isNotEmpty) ...[
          ...template.selectedLists!.map(
            (list) => _buildDetailRow(
              'List',
              '${list['list'] ?? 'Unknown'}: Min ${list['min'] ?? 0}, Max ${list['max'] ?? 1}',
            ),
          ),
        ],

        // Show selected crew if method is hire_crew
        if (template.method == 'hire_crew' &&
            template.selectedCrews != null &&
            template.selectedCrews!.isNotEmpty) ...[
          ...template.selectedCrews!.map(
            (crew) => _buildDetailRow(
              'Crew',
              crew['name'] ?? 'Unknown Crew',
            ),
          ),
        ],

        const SizedBox(height: 8),
        Text(
          'Created: ${template.createdAt.toString().split(' ')[0]}',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _getMethodDisplayName(String? method) {
    switch (method) {
      case 'use_list':
        return 'Single List';
      case 'standard':
        return 'Standard Selection';
      case 'advanced':
        return 'Multiple Lists';
      case 'hire_crew':
        return 'Hire a Crew';
      default:
        return 'Not Set';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
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
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return IconButton(
              icon: Icon(
                Icons.sports,
                color: themeProvider.isDarkMode
                    ? colorScheme.primary // Yellow in dark mode
                    : Colors.black, // Black in light mode
                size: 32,
              ),
              onPressed: () async {
                // Navigate to appropriate home screen based on user role
                final authService = AuthService();
                final homeRoute = await authService.getHomeRoute();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  homeRoute,
                  (route) => false, // Remove all routes
                );
              },
              tooltip: 'Home',
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
                                        final isExpanded =
                                            expandedTemplateId == template.id;

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
                                            child: Column(
                                              children: [
                                                // Header section - always visible
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      expandedTemplateId =
                                                          isExpanded
                                                              ? null
                                                              : template.id;
                                                    });
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(12),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: colorScheme
                                                                .primary
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: Icon(
                                                            _getSportIcon(
                                                                template.sport),
                                                            color: colorScheme
                                                                .primary,
                                                            size: 24,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 16),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                template.name,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 18,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: colorScheme
                                                                      .onSurface,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                  height: 4),
                                                              Text(
                                                                template.sport ??
                                                                    'Unknown Sport',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 14,
                                                                  color: colorScheme
                                                                      .onSurfaceVariant,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        // Expand/collapse caret icon
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: colorScheme
                                                                .primary
                                                                .withOpacity(
                                                                    0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        4),
                                                          ),
                                                          child: Icon(
                                                            isExpanded
                                                                ? Icons
                                                                    .expand_less
                                                                : Icons
                                                                    .expand_more,
                                                            color: colorScheme
                                                                .primary,
                                                            size: 20,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                // Expandable details section
                                                AnimatedSize(
                                                  duration: const Duration(
                                                      milliseconds: 300),
                                                  child: isExpanded
                                                      ? Column(
                                                          children: [
                                                            const Divider(
                                                              color:
                                                                  Colors.grey,
                                                              thickness: 0.5,
                                                              height: 1,
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      16,
                                                                      16,
                                                                      16,
                                                                      16),
                                                              child:
                                                                  _buildTemplateDetails(
                                                                      template),
                                                            ),
                                                            // Action buttons - only shown when expanded
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .fromLTRB(
                                                                      16,
                                                                      0,
                                                                      16,
                                                                      16),
                                                              child: Row(
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        OutlinedButton
                                                                            .icon(
                                                                      onPressed:
                                                                          () {
                                                                        _editTemplate(
                                                                            template);
                                                                      },
                                                                      icon:
                                                                          Icon(
                                                                        Icons
                                                                            .edit,
                                                                        color: colorScheme
                                                                            .primary,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                      label:
                                                                          Text(
                                                                        'Edit',
                                                                        style:
                                                                            TextStyle(
                                                                          color:
                                                                              colorScheme.primary,
                                                                        ),
                                                                      ),
                                                                      style: OutlinedButton
                                                                          .styleFrom(
                                                                        side:
                                                                            BorderSide(
                                                                          color:
                                                                              colorScheme.primary,
                                                                        ),
                                                                        padding:
                                                                            const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 8),
                                                                  Expanded(
                                                                    child:
                                                                        OutlinedButton
                                                                            .icon(
                                                                      onPressed:
                                                                          () {
                                                                        _showDeleteConfirmationDialog(
                                                                            template.name,
                                                                            template);
                                                                      },
                                                                      icon:
                                                                          Icon(
                                                                        Icons
                                                                            .delete_outline,
                                                                        color: Colors
                                                                            .red
                                                                            .shade600,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                      label:
                                                                          Text(
                                                                        'Delete',
                                                                        style:
                                                                            TextStyle(
                                                                          color: Colors
                                                                              .red
                                                                              .shade600,
                                                                        ),
                                                                      ),
                                                                      style: OutlinedButton
                                                                          .styleFrom(
                                                                        side:
                                                                            BorderSide(
                                                                          color: Colors
                                                                              .red
                                                                              .shade600,
                                                                        ),
                                                                        padding:
                                                                            const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 8),
                                                                  Expanded(
                                                                    child:
                                                                        ElevatedButton
                                                                            .icon(
                                                                      onPressed:
                                                                          () {
                                                                        _useTemplate(
                                                                            template);
                                                                      },
                                                                      icon:
                                                                          const Icon(
                                                                        Icons
                                                                            .arrow_forward,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                      label:
                                                                          const Text(
                                                                        'Use',
                                                                      ),
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.green,
                                                                        foregroundColor:
                                                                            Colors.white,
                                                                        padding:
                                                                            const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              12,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      : const SizedBox.shrink(),
                                                ),
                                              ],
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

  void _editTemplate(GameTemplateModel template) {
    debugPrint(
        '✏️ TEMPLATES SCREEN: Navigating to edit template: ${template.name}');
    Navigator.pushNamed(
      context,
      '/create_game_template',
      arguments: {
        'isEdit': true,
        'template': template,
      },
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        debugPrint(
            '✅ TEMPLATES SCREEN: Template updated, received result: ${result['name']}');
        debugPrint('✅ TEMPLATES SCREEN: Result data: $result');

        // Update the local template in the list immediately
        setState(() {
          final updatedTemplate = GameTemplateModel.fromJson(result);
          debugPrint(
              '✅ TEMPLATES SCREEN: Created updated template: ${updatedTemplate.name}');
          debugPrint(
              '✅ TEMPLATES SCREEN: Updated template ID: ${updatedTemplate.id}');
          debugPrint(
              '✅ TEMPLATES SCREEN: Current templates count: ${templates.length}');

          final index = templates.indexWhere((t) => t.id == updatedTemplate.id);
          debugPrint('✅ TEMPLATES SCREEN: Found template at index: $index');

          if (index != -1) {
            templates[index] = updatedTemplate;
            _groupTemplatesBySport(); // Regroup templates
            debugPrint(
                '✅ TEMPLATES SCREEN: Updated local template successfully');
          } else {
            debugPrint(
                '❌ TEMPLATES SCREEN: Could not find template to update locally');
          }
        });

        // Also refresh from server to ensure consistency
        _fetchTemplates();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template updated successfully!')),
        );
      } else if (result == true) {
        // Template was updated but no specific result returned
        debugPrint('✅ TEMPLATES SCREEN: Template updated (boolean result)');
        _fetchTemplates();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template updated successfully!')),
        );
      } else {
        debugPrint(
            '⚠️ TEMPLATES SCREEN: Template edit returned null or invalid result: $result');
      }
    });
  }

  void _createNewTemplate() {
    debugPrint('🚀 TEMPLATES SCREEN: Navigating to create template screen');
    debugPrint('🚀 TEMPLATES SCREEN: Passing sport: $sport');

    // Pass the sport from the schedule if available
    final Map<String, dynamic> args = {};
    if (sport != null) {
      args['sport'] = sport;
    }

    Navigator.pushNamed(
      context,
      '/create_game_template',
      arguments: args.isNotEmpty ? args : null,
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        debugPrint(
            '✅ TEMPLATES SCREEN: Template created, received result: ${result['name']}');
        // Template was created, refresh the list
        _fetchTemplates();
        // Template created successfully
      } else {
        debugPrint(
            '⚠️ TEMPLATES SCREEN: Template creation returned null or invalid result: $result');
      }
    });
  }
}
