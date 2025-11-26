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

    return ListView.builder(
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        return _buildGameCard(game);
      },
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
    final date = game['date'] as DateTime?;
    final time = game['time'] as TimeOfDay?;

    // Handle different field name variations
    final officialsRequired = _getIntValue(game, 'officialsRequired') ??
                             _getIntValue(game, 'officials_required') ?? 0;
    final officialsHired = _getIntValue(game, 'officialsHired') ??
                          _getIntValue(game, 'officials_hired') ?? 0;
    final officialsNeeded = officialsRequired - officialsHired;

    String dateText = 'TBD';
    if (date != null) {
      dateText = '${date.month}/${date.day}/${date.year}';
      if (time != null) {
        final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
        final minute = time.minute.toString().padLeft(2, '0');
        final period = time.hour >= 12 ? 'PM' : 'AM';
        final timeText = '$hour:$minute $period';
        dateText += ' at $timeText';
      }
    }

    // Get game details with flexible field names
    final opponent = game['opponent'] ?? 'TBD';
    final homeTeam = game['homeTeam'] ?? 'Home Team';
    final scheduleName = game['scheduleName'] ?? 'Unknown Schedule';
    final sportName = game['sport'] ?? 'Unknown';
    final locationName = game['location'] ?? 'TBD';
    final isAway = game['isAway'] == true;

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
        child: Column(
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
            if (locationName != 'TBD') ...[
              const SizedBox(height: 4),
              Text(
                locationName,
                style: const TextStyle(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '$officialsHired of $officialsRequired officials confirmed',
              style: const TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
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
