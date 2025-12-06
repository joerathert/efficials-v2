import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_colors.dart';
import '../services/game_service.dart';

class UnpublishedGamesScreen extends StatefulWidget {
  const UnpublishedGamesScreen({super.key});

  @override
  State<UnpublishedGamesScreen> createState() => _UnpublishedGamesScreenState();
}

class _UnpublishedGamesScreenState extends State<UnpublishedGamesScreen> {
  List<Map<String, dynamic>> unpublishedGames = [];
  Set<String> selectedGameIds = {};
  Set<String> expandedGameIds = {};
  bool isLoading = true;
  bool selectAll = false;
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _fetchUnpublishedGames();
  }

  Future<void> _fetchUnpublishedGames() async {
    try {
      final games = await _gameService.getUnpublishedGames();
      setState(() {
        unpublishedGames = games;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching unpublished games: $e');
      setState(() {
        unpublishedGames = [];
        isLoading = false;
      });
    }
  }

  Future<void> _deleteGame(String gameId) async {
    try {
      final success = await _gameService.deleteGame(gameId);
      if (success) {
        setState(() {
          unpublishedGames.removeWhere((game) => game['id'] == gameId);
          selectedGameIds.remove(gameId);
          expandedGameIds.remove(gameId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game deleted'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete game')),
        );
      }
    }
  }

  Future<void> _publishSelectedGames() async {
    if (selectedGameIds.isEmpty) return;

    try {
      final success = await _gameService.publishGames(selectedGameIds.toList());
      if (success) {
        final count = selectedGameIds.length;
        setState(() {
          unpublishedGames.removeWhere((game) => selectedGameIds.contains(game['id']));
          selectedGameIds.clear();
          selectAll = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count game${count == 1 ? '' : 's'} published!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish games')),
        );
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      if (selectAll) {
        selectedGameIds = unpublishedGames.map((g) => g['id'] as String).toSet();
      } else {
        selectedGameIds.clear();
      }
    });
  }

  String _formatDate(String? dateStr, {bool full = false}) {
    if (dateStr == null) return 'TBD';
    try {
      final date = DateTime.parse(dateStr);
      return full
          ? DateFormat('EEEE, MMMM d, yyyy').format(date)
          : DateFormat('EEE, MMM d').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '';
    if (time is String) {
      final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(time.trim());
      if (match != null) {
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
      }
      return time;
    }
    return '';
  }

  // Group games by schedule
  Map<String, List<Map<String, dynamic>>> _groupGamesBySchedule() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final game in unpublishedGames) {
      final schedule = game['scheduleName'] as String? ?? 'Unassigned';
      grouped.putIfAbsent(schedule, () => []).add(game);
    }
    // Sort games within each schedule by date
    for (final games in grouped.values) {
      games.sort((a, b) {
        final aDate = a['date'] as String? ?? '';
        final bDate = b['date'] as String? ?? '';
        return aDate.compareTo(bDate);
      });
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedGames = _groupGamesBySchedule();
    final hasSelectedGames = selectedGameIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Text(
          'Draft Games',
          style: TextStyle(
            color: AppColors.efficialsYellow,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (unpublishedGames.isNotEmpty)
            TextButton(
              onPressed: _toggleSelectAll,
              child: Text(
                selectAll ? 'Deselect All' : 'Select All',
                style: const TextStyle(color: AppColors.efficialsYellow),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.efficialsYellow))
          : unpublishedGames.isEmpty
              ? _buildEmptyState()
              : _buildGamesList(groupedGames),
      bottomNavigationBar: unpublishedGames.isNotEmpty
          ? Container(
              color: AppColors.efficialsBlack,
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Row(
                children: [
                  // Game count
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${selectedGameIds.length} selected',
                        style: const TextStyle(
                          color: AppColors.efficialsYellow,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${unpublishedGames.length} total drafts',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Publish button
                  ElevatedButton.icon(
                    onPressed: hasSelectedGames ? _publishSelectedGames : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasSelectedGames
                          ? AppColors.efficialsYellow
                          : Colors.grey[700],
                      foregroundColor: AppColors.efficialsBlack,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.publish, size: 20),
                    label: const Text(
                      'Publish',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'All Caught Up!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No draft games waiting to be published',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList(Map<String, List<Map<String, dynamic>>> groupedGames) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedGames.length,
      itemBuilder: (context, index) {
        final schedule = groupedGames.keys.elementAt(index);
        final games = groupedGames[schedule]!;
        return _buildScheduleSection(schedule, games);
      },
    );
  }

  Widget _buildScheduleSection(String schedule, List<Map<String, dynamic>> games) {
    final allSelected = games.every((g) => selectedGameIds.contains(g['id']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Schedule header
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  schedule,
                  style: const TextStyle(
                    color: AppColors.efficialsYellow,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Select all for this schedule
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (allSelected) {
                      for (final game in games) {
                        selectedGameIds.remove(game['id']);
                      }
                    } else {
                      for (final game in games) {
                        selectedGameIds.add(game['id'] as String);
                      }
                    }
                    selectAll = selectedGameIds.length == unpublishedGames.length;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: allSelected
                        ? AppColors.efficialsYellow.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.efficialsYellow.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    allSelected ? '✓ All' : 'Select',
                    style: TextStyle(
                      color: AppColors.efficialsYellow,
                      fontSize: 12,
                      fontWeight: allSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Games list
        ...games.map((game) => _buildGameCard(game)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    final gameId = game['id'] as String;
    final isSelected = selectedGameIds.contains(gameId);
    final isExpanded = expandedGameIds.contains(gameId);
    final opponent = game['opponent'] as String? ?? 'TBD';
    final isAway = game['isAway'] as bool? ?? false;
    final date = _formatDate(game['date'] as String?);
    final fullDate = _formatDate(game['date'] as String?, full: true);
    final time = _formatTime(game['time']);
    final location = game['location'] as String? ?? 'Not set';
    final officialsRequired = game['officialsRequired'] as int? ?? 2;
    final gameFeeRaw = game['gameFee'];
    final gameFee = gameFeeRaw is num 
        ? gameFeeRaw 
        : (gameFeeRaw is String ? double.tryParse(gameFeeRaw) : null);
    final gender = game['gender'] as String? ?? '';
    final level = game['level'] as String? ?? '';
    final sport = game['sport'] as String? ?? '';
    final selectionMethod = game['selectionMethod'] as String? ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.efficialsYellow.withOpacity(0.1)
            : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.efficialsYellow.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Main row (always visible)
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedGameIds.remove(gameId);
                } else {
                  expandedGameIds.add(gameId);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Checkbox indicator
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedGameIds.remove(gameId);
                        } else {
                          selectedGameIds.add(gameId);
                        }
                        selectAll = selectedGameIds.length == unpublishedGames.length;
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.efficialsYellow
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.efficialsYellow
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.black)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Main content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Opponent + Officials count
                        Row(
                          children: [
                            if (isAway)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  '@',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                opponent,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person, size: 14, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$officialsRequired',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        
                        // Row 2: Date & Time
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              date,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            if (time.isNotEmpty) ...[
                              Text(
                                '  •  ',
                                style: TextStyle(color: Colors.white.withOpacity(0.3)),
                              ),
                              Text(
                                time,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Expand indicator
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white.withOpacity(0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded details
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: AppColors.darkBackground.withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                  
                  // Details grid
                  _buildDetailRow(Icons.calendar_month, 'Date', fullDate),
                  _buildDetailRow(Icons.access_time, 'Time', time.isNotEmpty ? time : 'Not set'),
                  _buildDetailRow(Icons.location_on, 'Location', location),
                  if (sport.isNotEmpty)
                    _buildDetailRow(Icons.sports, 'Sport', sport),
                  if (gender.isNotEmpty)
                    _buildDetailRow(Icons.people, 'Gender', gender),
                  if (level.isNotEmpty)
                    _buildDetailRow(Icons.emoji_events, 'Level', level),
                  _buildDetailRow(
                    Icons.person_outline,
                    'Officials',
                    '$officialsRequired required',
                  ),
                  if (gameFee != null)
                    _buildDetailRow(
                      Icons.attach_money,
                      'Game Fee',
                      '\$${gameFee.toStringAsFixed(2)}',
                    ),
                  if (selectionMethod.isNotEmpty)
                    _buildDetailRow(Icons.how_to_reg, 'Method', selectionMethod),
                  
                  const SizedBox(height: 12),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/game-information',
                              arguments: game,
                            ).then((result) {
                              if (result == true || (result is Map<String, dynamic> && result.isNotEmpty)) {
                                _fetchUnpublishedGames();
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.efficialsYellow,
                            side: const BorderSide(color: AppColors.efficialsYellow),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeleteDialog(gameId, opponent),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.efficialsYellow.withOpacity(0.7),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String gameId, String opponent) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Delete Game?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete game vs $opponent?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGame(gameId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
