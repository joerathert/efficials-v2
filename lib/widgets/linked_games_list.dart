import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../app_theme.dart';

class LinkedGamesList extends StatelessWidget {
  final List<Map<String, dynamic>> games;
  final Function(Map<String, dynamic>) onGameTap;
  final String? emptyMessage;
  final IconData? emptyIcon;

  const LinkedGamesList({
    super.key,
    required this.games,
    required this.onGameTap,
    this.emptyMessage,
    this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (games.isEmpty) {
      return _buildEmptyState();
    }

    // Group games by linkGroupId if they have linked games
    final groupedGames = _groupLinkedGames(games);

    return Column(
      children: groupedGames.map((group) {
        if (group.length == 1) {
          // Single game, no linking
          return _buildGameCard(group[0]);
        } else {
          // Linked games - show as a group
          return _buildLinkedGameGroup(group);
        }
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            emptyIcon ?? Icons.sports,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage ?? 'No games available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    return GestureDetector(
      onTap: () => onGameTap(game),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: _buildGameCardContent(game),
      ),
    );
  }

  // Group linked games together based on linkGroupId
  List<List<Map<String, dynamic>>> _groupLinkedGames(
      List<Map<String, dynamic>> games) {
    debugPrint('🔗 LinkedGamesList: Grouping ${games.length} games');
    final linkedGroups = <String, List<Map<String, dynamic>>>{};
    final unlinkedGames = <Map<String, dynamic>>[];

    for (final game in games) {
      final linkGroupId = game['linkGroupId'] as String?;
      debugPrint('🔗 Game ${game['id']}: linkGroupId = $linkGroupId');
      if (linkGroupId != null && linkGroupId.isNotEmpty) {
        linkedGroups.putIfAbsent(linkGroupId, () => []).add(game);
      } else {
        unlinkedGames.add(game);
      }
    }

    // Sort games within each linked group by date/time
    linkedGroups.forEach((key, games) {
      games.sort((a, b) {
        try {
          // Parse date
          final aDateValue = a['date'];
          final bDateValue = b['date'];
          final aDate = aDateValue is DateTime
              ? aDateValue
              : DateTime.parse(aDateValue.toString());
          final bDate = bDateValue is DateTime
              ? bDateValue
              : DateTime.parse(bDateValue.toString());

          // If dates are different, sort by date
          if (aDate != bDate) {
            return aDate.compareTo(bDate);
          }

          // If dates are the same, try to sort by time
          final aTimeStr = a['time']?.toString();
          final bTimeStr = b['time']?.toString();

          if (aTimeStr != null && bTimeStr != null) {
            // Parse time strings (format: "HH:MM")
            final aParts = aTimeStr.split(':');
            final bParts = bTimeStr.split(':');

            if (aParts.length >= 2 && bParts.length >= 2) {
              final aHour = int.tryParse(aParts[0]) ?? 0;
              final aMinute = int.tryParse(aParts[1]) ?? 0;
              final bHour = int.tryParse(bParts[0]) ?? 0;
              final bMinute = int.tryParse(bParts[1]) ?? 0;

              final aTime = TimeOfDay(hour: aHour, minute: aMinute);
              final bTime = TimeOfDay(hour: bHour, minute: bMinute);

              return aTime.hour * 60 +
                  aTime.minute -
                  (bTime.hour * 60 + bTime.minute);
            }
          }

          return 0;
        } catch (e) {
          return 0;
        }
      });
    });

    // Combine linked groups and unlinked games
    final result = <List<Map<String, dynamic>>>[];
    result.addAll(linkedGroups.values);
    result.addAll(unlinkedGames.map((game) => [game]));

    debugPrint(
        '🔗 LinkedGamesList: Created ${result.length} groups (${linkedGroups.length} linked, ${unlinkedGames.length} unlinked)');
    for (int i = 0; i < result.length; i++) {
      debugPrint('🔗 Group $i: ${result[i].length} games');
    }

    return result;
  }

  // Build a group of linked games
  Widget _buildLinkedGameGroup(List<Map<String, dynamic>> linkedGames) {
    if (linkedGames.length < 2) {
      return _buildGameCard(linkedGames.first);
    }

    // Calculate total fee for linked games (if applicable)
    double totalFee = 0.0;
    for (final game in linkedGames) {
      // Try different fee field names
      final fee = double.tryParse(game['game_fee']?.toString() ?? '0') ??
          double.tryParse(game['gameFee']?.toString() ?? '0') ??
          0.0;
      totalFee += fee;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Column(
            children: [
              // Top card - first game
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildTopLinkedGameContent(linkedGames[0]),
              ),
              // No gap - cards pressed together
              // Bottom card - second game + shared info
              Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: _buildBottomLinkedGameContent(
                    linkedGames[1], totalFee, linkedGames),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopLinkedGameContent(Map<String, dynamic> game) {
    return GestureDetector(
      onTap: () => onGameTap(game),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildGameCardContent(game,
            isLinked: true,
            showButtons: false,
            showLocation: false,
            showOfficialsStatus: false),
      ),
    );
  }

  Widget _buildBottomLinkedGameContent(Map<String, dynamic> game,
      double totalFee, List<Map<String, dynamic>> linkedGames) {
    return GestureDetector(
      onTap: () => onGameTap(game),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGameCardContent(game,
                isLinked: true,
                showButtons: false,
                showLocation: true,
                showOfficialsStatus: true),
            const SizedBox(height: 12),
            // Total fee and any additional info
            if (totalFee > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Fee: \$${totalFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50), // Green color for fees
                    ),
                  ),
                  // Could add action buttons here if needed
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Extract game card content to reuse for linked games
  Widget _buildGameCardContent(Map<String, dynamic> game,
      {bool isLinked = false,
      bool showButtons = true,
      bool showLocation = true,
      bool showOfficialsStatus = true}) {
    // Parse date properly - it comes from Firestore as a string
    DateTime? date;
    if (game['date'] != null) {
      try {
        final dateValue = game['date'];
        date = dateValue is DateTime
            ? dateValue
            : DateTime.parse(dateValue.toString());
      } catch (e) {
        debugPrint('LinkedGamesList: Error parsing date: $e');
        date = null;
      }
    }

    // Parse time properly - it comes from Firestore as a string
    TimeOfDay? time;
    if (game['time'] != null) {
      try {
        final timeValue = game['time'];
        debugPrint(
            'LinkedGamesList: Parsing time for game ${game['id']}: $timeValue (type: ${timeValue.runtimeType})');
        if (timeValue is TimeOfDay) {
          time = timeValue;
        } else {
          // Parse time string (format: "HH:MM")
          final timeStr = timeValue.toString();
          final parts = timeStr.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour != null && minute != null) {
              time = TimeOfDay(hour: hour, minute: minute);
              debugPrint(
                  'LinkedGamesList: Successfully parsed time: $hour:$minute');
            } else {
              debugPrint(
                  'LinkedGamesList: Failed to parse hour/minute from: $timeStr');
            }
          } else {
            debugPrint(
                'LinkedGamesList: Time string doesn\'t have 2 parts: $timeStr');
          }
        }
      } catch (e) {
        debugPrint('LinkedGamesList: Error parsing time: $e');
        time = null;
      }
    } else {
      debugPrint('LinkedGamesList: No time field for game ${game['id']}');
    }

    debugPrint(
        'LinkedGamesList: Game ${game['id']} linkGroupId = ${game['linkGroupId']}');

    // Handle different field name variations
    final officialsRequired = _getIntValue(game, 'officialsRequired') ??
        _getIntValue(game, 'officials_required') ??
        0;
    final officialsHired = _getIntValue(game, 'officialsHired') ??
        _getIntValue(game, 'officials_hired') ??
        0;
    final officialsNeeded = officialsRequired - officialsHired;

    String dateText = 'TBD';
    if (date != null) {
      dateText = '${date.month}/${date.day}/${date.year}';
      if (time != null) {
        final hour =
            time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
        final minute = time.minute.toString().padLeft(2, '0');
        final period = time.hour >= 12 ? 'PM' : 'AM';
        final timeText = '$hour:$minute $period';
        dateText += ' at $timeText';
      }
    }

    // Get game details with flexible field names
    final opponent = game['opponent'] ?? 'TBD';
    final scheduleName = game['scheduleName'] ?? 'Unknown Schedule';
    // For coach games, home team is the schedule name if homeTeam is null
    final homeTeam = game['homeTeam'] ?? scheduleName;
    final sportName = game['sport'] ?? 'Unknown';

    // Handle location - it can be a string or a map with name/address
    String locationName = 'TBD';
    if (game['location'] != null) {
      if (game['location'] is String) {
        locationName = game['location'] as String;
      } else if (game['location'] is Map && game['location']['name'] != null) {
        locationName = game['location']['name'] as String;
      }
    }

    final isAway = game['isAway'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              getSportIcon(sportName),
              color: AppColors.efficialsYellow,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAway ? '$homeTeam @ $opponent' : '$opponent @ $homeTeam',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scheduleName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLinked) // Only show the badge for non-linked cards
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Need $officialsNeeded',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          dateText,
          style: const TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
          ),
        ),
        if (showLocation && locationName != 'TBD') ...[
          const SizedBox(height: 4),
          Text(
            locationName,
            style: const TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
        ],
        if (showOfficialsStatus) ...[
          const SizedBox(height: 8),
          Text(
            '$officialsHired of $officialsRequired officials confirmed',
            style: const TextStyle(
              fontSize: 12,
              color: secondaryTextColor,
            ),
          ),
        ],
      ],
    );
  }

  // Helper function to safely get integer values from different field names
  int? _getIntValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }
}
