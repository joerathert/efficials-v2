import 'package:flutter/material.dart';
import '../../app_colors.dart';
import '../../services/bulk_import_service.dart';

class BulkImportPreviewScreen extends StatefulWidget {
  const BulkImportPreviewScreen({super.key});

  @override
  State<BulkImportPreviewScreen> createState() => _BulkImportPreviewScreenState();
}

class _BulkImportPreviewScreenState extends State<BulkImportPreviewScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  BulkImportConfig? config;
  List<ParsedGame> parsedGames = [];
  Map<String, List<ParsedGame>> gamesBySchedule = {};
  List<String> scheduleNames = [];
  bool _isInitialized = false;

  bool isImporting = false;
  bool isImported = false;
  Map<String, dynamic>? importResult;

  final BulkImportService _bulkImportService = BulkImportService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return; // Only initialize once
    
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      config = args['config'] as BulkImportConfig?;
      parsedGames = args['parsedGames'] as List<ParsedGame>? ?? [];
      _organizeGames();
      _isInitialized = true;
    }
  }

  void _organizeGames() {
    gamesBySchedule.clear();
    for (final game in parsedGames) {
      gamesBySchedule.putIfAbsent(game.scheduleName, () => []).add(game);
    }
    scheduleNames = gamesBySchedule.keys.toList();

    // Dispose old controller if exists
    _tabController?.dispose();
    
    _tabController = TabController(
      length: scheduleNames.isEmpty ? 1 : scheduleNames.length,
      vsync: this,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _importGames() async {
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration error. Please try again.')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text(
          'Confirm Import',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'You are about to import ${parsedGames.length} game${parsedGames.length == 1 ? '' : 's'} into ${scheduleNames.length} schedule${scheduleNames.length == 1 ? '' : 's'}.\n\nThis will create schedules that don\'t exist and add games to them.\n\nContinue?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.efficialsYellow,
              foregroundColor: Colors.black,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isImporting = true;
    });

    try {
      final result = await _bulkImportService.importGames(parsedGames, config!);

      setState(() {
        isImporting = false;
        isImported = true;
        importResult = result;
      });
    } catch (e) {
      setState(() {
        isImporting = false;
        importResult = {
          'success': false,
          'error': e.toString(),
        };
      });
    }
  }

  void _goHome() {
    Navigator.popUntil(context, (route) {
      return route.settings.name == '/assigner-home' || route.isFirst;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isImported) {
      return _buildResultView();
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text(
          'Preview Import',
          style: TextStyle(color: AppColors.efficialsYellow, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.efficialsWhite),
          onPressed: isImporting ? null : () => Navigator.pop(context),
        ),
        bottom: scheduleNames.length > 1 && _tabController != null
            ? TabBar(
                controller: _tabController!,
                isScrollable: true,
                indicatorColor: AppColors.efficialsYellow,
                labelColor: AppColors.efficialsYellow,
                unselectedLabelColor: Colors.grey,
                tabs: scheduleNames.map((name) {
                  final games = gamesBySchedule[name] ?? [];
                  return Tab(
                    child: Row(
                      children: [
                        Text(name.length > 15 ? '${name.substring(0, 15)}...' : name),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.efficialsYellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${games.length}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              )
            : null,
      ),
      body: scheduleNames.isEmpty || _tabController == null
          ? const Center(
              child: Text(
                'No games to preview',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : scheduleNames.length == 1
              ? _buildGamesList(scheduleNames.first)
              : TabBarView(
                  controller: _tabController!,
                  children: scheduleNames.map((name) {
                    return _buildGamesList(name);
                  }).toList(),
                ),
      bottomNavigationBar: Container(
        color: AppColors.efficialsBlack,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                      'Schedules', scheduleNames.length.toString(), Icons.folder),
                  _buildSummaryItem(
                      'Games', parsedGames.length.toString(), Icons.sports),
                  _buildSummaryItem('Linked', _countLinkedGames().toString(), Icons.link),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isImporting ? null : _importGames,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.efficialsYellow,
                foregroundColor: AppColors.efficialsBlack,
                disabledBackgroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: isImporting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text(
                          'Import ${parsedGames.length} Game${parsedGames.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesList(String scheduleName) {
    final allGames = parsedGames; // Use all games for cross-schedule linking

    // Group games by link group across ALL schedules for cross-schedule linking
    final allLinkedGroups = <String, List<ParsedGame>>{};

    for (final game in allGames) {
      if (game.linkGroup != null && game.linkGroup!.isNotEmpty) {
        allLinkedGroups.putIfAbsent(game.linkGroup!, () => []).add(game);
      }
    }

    // Filter to show only link groups that have games in the current schedule
    final scheduleGames = gamesBySchedule[scheduleName] ?? [];
    final linkedGroups = <String, List<ParsedGame>>{};
    final unlinkedGames = <ParsedGame>[];

    for (final game in scheduleGames) {
      if (game.linkGroup != null && game.linkGroup!.isNotEmpty) {
        // For linked groups, show all games in the link group (cross-schedule)
        final linkGroup = game.linkGroup!;
        if (!linkedGroups.containsKey(linkGroup)) {
          linkedGroups[linkGroup] = allLinkedGroups[linkGroup] ?? [];
        }
      } else {
        unlinkedGames.add(game);
      }
    }

    // Sort games by date
    unlinkedGames.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Schedule header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.efficialsYellow.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scheduleName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.efficialsYellow,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip('${scheduleGames.length} games', Icons.sports),
                    const SizedBox(width: 8),
                    if (scheduleGames.isNotEmpty && scheduleGames.first.teamName.isNotEmpty)
                      _buildInfoChip(scheduleGames.first.teamName, Icons.group),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Linked game groups
          if (linkedGroups.isNotEmpty) ...[
            const Text(
              'Linked Games',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            ...linkedGroups.entries.map((entry) {
              return _buildLinkedGroup(entry.key, entry.value);
            }),
            const SizedBox(height: 20),
          ],

          // Regular games
          if (unlinkedGames.isNotEmpty) ...[
            const Text(
              'Individual Games',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ...unlinkedGames.map((game) => _buildGameCard(game)),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkedGroup(String linkGroup, List<ParsedGame> games) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Link Group $linkGroup',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${games.length} games',
                  style: TextStyle(
                    color: Colors.blue.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: games.map((game) => _buildGameCard(game, isLinked: true)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(ParsedGame game, {bool isLinked = false}) {
    final dateStr = game.date != null
        ? '${game.date!.month}/${game.date!.day}/${game.date!.year}'
        : 'No date';
    final timeStr = game.time != null
        ? '${game.time!.hourOfPeriod}:${game.time!.minute.toString().padLeft(2, '0')} ${game.time!.period == DayPeriod.am ? 'AM' : 'PM'}'
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: isLinked ? 8 : 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLinked ? Colors.transparent : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(8),
        border: isLinked ? null : Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Date/Time column
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Game info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (game.isAway)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text(
                          '@',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        game.opponent ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (game.gender != null) ...[
                      Text(
                        game.gender!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(color: Colors.white.withOpacity(0.3)),
                      ),
                    ],
                    if (game.competitionLevel != null)
                      Text(
                        game.competitionLevel!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Officials count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.efficialsYellow.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person,
                  size: 14,
                  color: AppColors.efficialsYellow,
                ),
                const SizedBox(width: 4),
                Text(
                  '${game.officialsRequired ?? 2}',
                  style: const TextStyle(
                    color: AppColors.efficialsYellow,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.efficialsYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.efficialsYellow),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.efficialsYellow,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.efficialsYellow),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _countLinkedGames() {
    int count = 0;
    for (final game in parsedGames) {
      if (game.linkGroup != null && game.linkGroup!.isNotEmpty) {
        count++;
      }
    }
    return count;
  }

  Widget _buildResultView() {
    final success = importResult?['success'] == true;
    final successCount = importResult?['successCount'] ?? 0;
    final errorCount = importResult?['errorCount'] ?? 0;
    final errors = (importResult?['errors'] as List<String>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: Text(
          success ? 'Import Complete!' : 'Import Results',
          style: const TextStyle(color: AppColors.efficialsYellow, fontSize: 18),
        ),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.warning,
              color: success ? Colors.green : Colors.orange,
              size: 100,
            ),
            const SizedBox(height: 24),
            Text(
              success
                  ? 'Successfully Imported!'
                  : errorCount > 0
                      ? 'Partial Import'
                      : 'Import Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: success ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 16),

            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultStat('Imported', successCount.toString(), Colors.green),
                  if (errorCount > 0)
                    _buildResultStat('Failed', errorCount.toString(), Colors.red),
                  _buildResultStat('Total', parsedGames.length.toString(), Colors.blue),
                ],
              ),
            ),

            if (errors.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Errors:',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...errors.map((error) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $error',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),
            Text(
              success
                  ? 'Your games have been added as unpublished. Review them in the Unpublished Games screen before publishing.'
                  : 'Some games could not be imported. Please check the errors above.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _goHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.efficialsYellow,
                  foregroundColor: AppColors.efficialsBlack,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Go to Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/assigner_manage_schedules');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.efficialsYellow,
                  side: const BorderSide(color: AppColors.efficialsYellow),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Schedules',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/unpublished-games');
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.efficialsYellow,
                  side: const BorderSide(color: AppColors.efficialsYellow),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Review Unpublished Games',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

