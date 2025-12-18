import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../services/game_service.dart';

class LinkGamesDialog extends StatefulWidget {
  final String currentGameId;
  final List<Map<String, dynamic>> eligibleGames;
  final bool isCurrentlyLinked;
  final GameService gameService;
  final VoidCallback onLinkCreated;

  const LinkGamesDialog({
    super.key,
    required this.currentGameId,
    required this.eligibleGames,
    required this.isCurrentlyLinked,
    required this.gameService,
    required this.onLinkCreated,
  });

  @override
  State<LinkGamesDialog> createState() => _LinkGamesDialogState();
}

class _LinkGamesDialogState extends State<LinkGamesDialog> {
  final Set<String> selectedGameIds = {};
  bool isLoading = false;

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'TBD';

    try {
      // Handle different time formats
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
        final displayMinute = minute.toString().padLeft(2, '0');

        return '$displayHour:$displayMinute $period';
      }
    } catch (e) {
      debugPrint('Error formatting time: $e');
    }

    return timeStr; // Return original if parsing fails
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      title: Text(
        widget.isCurrentlyLinked ? 'Manage Game Links' : 'Link Games',
        style: const TextStyle(
          color: AppColors.efficialsYellow,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isCurrentlyLinked) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.efficialsYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.efficialsYellow.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: AppColors.efficialsYellow, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This game is already linked with other games',
                        style: TextStyle(color: AppColors.efficialsYellow, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: _unlinkGame,
                      child: const Text(
                        'Unlink',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              widget.eligibleGames.isEmpty
                  ? 'No other games found at the same location and date.'
                  : 'Select games to link together (same location & date):',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (widget.eligibleGames.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Games must be at the same location on the same date to be linked.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: widget.eligibleGames.length,
                  itemBuilder: (context, index) {
                    final game = widget.eligibleGames[index];
                    final gameId = game['id'] as String;
                    final isSelected = selectedGameIds.contains(gameId);
                    final isAlreadyLinked = game['isAlreadyLinked'] == true;

                    return CheckboxListTile(
                      title: Text(
                        '${_formatTime(game['time']?.toString())} - ${game['opponent'] ?? 'vs TBD'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          decoration: isAlreadyLinked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${game['sport'] ?? 'Unknown'} • ${game['officialsRequired'] ?? 0} officials needed',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          if (isAlreadyLinked)
                            const Text(
                              'Already linked to another game',
                              style: TextStyle(color: Colors.orange, fontSize: 12),
                            ),
                        ],
                      ),
                      value: isSelected,
                      onChanged: isAlreadyLinked ? null : (value) {
                        setState(() {
                          if (value == true) {
                            selectedGameIds.add(gameId);
                          } else {
                            selectedGameIds.remove(gameId);
                          }
                        });
                      },
                      activeColor: AppColors.efficialsYellow,
                      checkColor: AppColors.darkBackground,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.efficialsYellow)),
        ),
        if (widget.eligibleGames.isNotEmpty && !widget.isCurrentlyLinked)
          ElevatedButton(
            onPressed: selectedGameIds.isEmpty || isLoading ? null : _createLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.efficialsYellow,
              foregroundColor: AppColors.darkBackground,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkBackground),
                    ),
                  )
                : const Text('Link Games'),
          ),
      ],
    );
  }

  Future<void> _createLink() async {
    setState(() {
      isLoading = true;
    });

    try {
      final gameIds = [widget.currentGameId, ...selectedGameIds];
      final linkId = await widget.gameService.createGameLink(gameIds);

      if (linkId != null) {
        widget.onLinkCreated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully linked ${gameIds.length} games'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create game link'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _unlinkGame() async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await widget.gameService.unlinkGame(widget.currentGameId);

      if (success) {
        widget.onLinkCreated();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game unlinked successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to unlink game'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unlinking game: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
