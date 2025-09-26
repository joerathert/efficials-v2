import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/game_service.dart';

class UnpublishedGamesScreen extends StatefulWidget {
  const UnpublishedGamesScreen({super.key});

  @override
  State<UnpublishedGamesScreen> createState() => _UnpublishedGamesScreenState();
}

class _UnpublishedGamesScreenState extends State<UnpublishedGamesScreen> {
  List<Map<String, dynamic>> unpublishedGames = [];
  Set<String> selectedGameIds = {};
  bool isLoading = true;
  final GameService _gameService = GameService();

  @override
  void initState() {
    super.initState();
    _fetchUnpublishedGames();
  }

  Future<void> _fetchUnpublishedGames() async {
    try {
      debugPrint('Fetching unpublished games from database...');

      final games = await _gameService.getUnpublishedGames();

      setState(() {
        unpublishedGames = games;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching unpublished games from database: $e');
      setState(() {
        unpublishedGames = [];
        isLoading = false;
      });
    }
  }

  Future<void> _deleteGame(String gameId, String gameTitle) async {
    try {
      final success = await _gameService.deleteGame(gameId);
      if (success) {
        setState(() {
          unpublishedGames.removeWhere((game) => game['id'] == gameId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game deleted!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete game')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting game: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete game')),
        );
      }
    }
  }

  Future<void> _publishSelectedGames() async {
    final gamesToPublish = unpublishedGames
        .where((game) => selectedGameIds.contains(game['id']))
        .toList();

    if (gamesToPublish.isEmpty) return;

    try {
      debugPrint('Publishing ${gamesToPublish.length} games to database...');

      final gameIds =
          gamesToPublish.map((game) => game['id'] as String).toList();
      final success = await _gameService.publishGames(gameIds);

      if (success) {
        debugPrint(
            'Successfully published ${gamesToPublish.length} games to database');
        setState(() {
          unpublishedGames
              .removeWhere((game) => selectedGameIds.contains(game['id']));
          selectedGameIds.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${gamesToPublish.length} game${gamesToPublish.length == 1 ? '' : 's'} published successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to publish games')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error publishing games to database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish games')),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String gameId, String gameTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Confirm Delete',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$gameTitle"?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGame(gameId, gameTitle);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  IconData _getSportIcon(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
        return Icons.sports_football;
      case 'basketball':
        return Icons.sports_basketball;
      case 'baseball':
        return Icons.sports_baseball;
      case 'soccer':
        return Icons.sports_soccer;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'tennis':
        return Icons.sports_tennis;
      default:
        return Icons.sports;
    }
  }

  String _formatTimeTo12Hour(String timeStr) {
    try {
      // Handle various military time formats
      final cleanTime = timeStr.trim();

      // Handle "HH:MM" format (military/24-hour)
      final timeRegex = RegExp(r'^(\d{1,2}):(\d{2})$');
      final match = timeRegex.firstMatch(cleanTime);

      if (match != null) {
        final hour = int.parse(match.group(1)!);
        final minute = int.parse(match.group(2)!);

        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final minuteStr = minute.toString().padLeft(2, '0');

        return '$displayHour:$minuteStr $period';
      }

      // If it's already in a readable format, return as-is
      return timeStr;
    } catch (e) {
      debugPrint('Error formatting time: $e');
      return timeStr; // Return original if parsing fails
    }
  }

  Color _getSportIconColor(String sport) {
    switch (sport.toLowerCase()) {
      case 'football':
        return Colors.brown;
      case 'basketball':
        return Colors.orange;
      case 'baseball':
        return Colors.blue;
      case 'soccer':
        return Colors.green;
      case 'volleyball':
        return Colors.purple;
      case 'tennis':
        return Colors.yellow.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSelectedGames = selectedGameIds.isNotEmpty;

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
                        'Draft Games',
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
                        'Review and publish your draft games',
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
                              : unpublishedGames.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.edit_note,
                                            size: 80,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No draft games',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'All your games have been published',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: unpublishedGames.length,
                                      itemBuilder: (context, index) {
                                        final game = unpublishedGames[index];
                                        final gameId = game['id'] as String;
                                        final sport =
                                            game['sport'] as String? ??
                                                'Unknown';
                                        final scheduleName =
                                            game['scheduleName'] as String? ??
                                                'Unknown';
                                        final gameDate = game['date'] != null
                                            ? DateFormat('EEEE, MMM d, yyyy')
                                                .format(DateTime.parse(
                                                    game['date']))
                                            : 'Date not set';
                                        final gameTime = game['time'] != null
                                            ? game['time'] is String
                                                ? _formatTimeTo12Hour(
                                                    game['time'])
                                                : (game['time'] as TimeOfDay)
                                                    .format(context)
                                            : 'Time not set';
                                        final location =
                                            game['location'] as String? ??
                                                'Location not set';
                                        final opponent =
                                            game['opponent'] as String?;
                                        final isAway =
                                            game['isAway'] as bool? ?? false;
                                        final sportIcon = _getSportIcon(sport);
                                        final opponentDisplay = opponent != null
                                            ? (isAway
                                                ? '@ $opponent'
                                                : 'vs $opponent')
                                            : null;

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
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/game-information',
                                                  arguments: game,
                                                ).then((result) {
                                                  if (result == true ||
                                                      (result is Map<String,
                                                              dynamic> &&
                                                          result.isNotEmpty)) {
                                                    // Refresh the unpublished games list
                                                    _fetchUnpublishedGames();
                                                  }
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: Row(
                                                  children: [
                                                    Checkbox(
                                                      value: selectedGameIds
                                                          .contains(gameId),
                                                      onChanged: (bool? value) {
                                                        setState(() {
                                                          if (value == true) {
                                                            selectedGameIds
                                                                .add(gameId);
                                                          } else {
                                                            selectedGameIds
                                                                .remove(gameId);
                                                          }
                                                        });
                                                      },
                                                      activeColor:
                                                          colorScheme.primary,
                                                      checkColor:
                                                          colorScheme.onPrimary,
                                                    ),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _getSportIconColor(
                                                                    sport)
                                                                .withOpacity(
                                                                    0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Icon(
                                                        sportIcon,
                                                        color:
                                                            _getSportIconColor(
                                                                sport),
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
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Text(
                                                                  gameDate,
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: colorScheme
                                                                        .onSurface,
                                                                  ),
                                                                ),
                                                              ),
                                                              Container(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .orange
                                                                      .withOpacity(
                                                                          0.1),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    Icon(
                                                                      Icons
                                                                          .edit,
                                                                      size: 12,
                                                                      color: Colors
                                                                          .orange
                                                                          .shade700,
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            4),
                                                                    Text(
                                                                      'Draft',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        color: Colors
                                                                            .orange
                                                                            .shade700,
                                                                        fontWeight:
                                                                            FontWeight.w600,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          // Game time
                                                          Text(
                                                            gameTime,
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: colorScheme
                                                                    .onSurface),
                                                          ),
                                                          const SizedBox(
                                                              height: 2),
                                                          // Opponent information (always shown prominently)
                                                          Text(
                                                            opponentDisplay !=
                                                                    null
                                                                ? opponentDisplay!
                                                                : 'No opponent specified',
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              color: opponentDisplay !=
                                                                      null
                                                                  ? colorScheme
                                                                      .onSurface
                                                                  : colorScheme
                                                                      .onSurfaceVariant,
                                                              fontWeight: opponentDisplay !=
                                                                      null
                                                                  ? FontWeight
                                                                      .w500
                                                                  : FontWeight
                                                                      .normal,
                                                            ),
                                                          ),
                                                          // Schedule name (smaller, below opponent)
                                                          const SizedBox(
                                                              height: 2),
                                                          Text(
                                                            scheduleName,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: colorScheme
                                                                  .onSurfaceVariant,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Text(
                                                            location,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    // Action buttons column
                                                    Column(
                                                      children: [
                                                        IconButton(
                                                          onPressed: () =>
                                                              _showDeleteConfirmationDialog(
                                                                  gameId,
                                                                  '$sport - $scheduleName'),
                                                          icon: Icon(
                                                            Icons
                                                                .delete_outline,
                                                            color: Colors
                                                                .red.shade600,
                                                            size: 20,
                                                          ),
                                                          tooltip:
                                                              'Delete Draft',
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
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
      floatingActionButton: Container(
        width: double.infinity,
        height: 100 + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: colorScheme.surface,
        ),
        padding: EdgeInsets.fromLTRB(
          24.0,
          16.0,
          24.0,
          16.0 + MediaQuery.of(context).padding.bottom,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 400, // Limited width for web version
            child: ElevatedButton(
              onPressed: hasSelectedGames ? _publishSelectedGames : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasSelectedGames
                    ? colorScheme.primary
                    : colorScheme.surfaceVariant,
                foregroundColor: hasSelectedGames
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: hasSelectedGames ? null : 0,
              ),
              child: Text(
                hasSelectedGames
                    ? 'Publish ${selectedGameIds.length} Game${selectedGameIds.length == 1 ? '' : 's'}'
                    : 'Select Games to Publish',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hasSelectedGames
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
