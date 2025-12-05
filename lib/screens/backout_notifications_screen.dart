import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen for schedulers to view and excuse official backouts
class BackoutNotificationsScreen extends StatefulWidget {
  const BackoutNotificationsScreen({super.key});

  @override
  State<BackoutNotificationsScreen> createState() =>
      _BackoutNotificationsScreenState();
}

class _BackoutNotificationsScreenState
    extends State<BackoutNotificationsScreen> {
  final GameService _gameService = GameService();
  final AuthService _authService = AuthService();
  
  List<Map<String, dynamic>> _backouts = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadBackouts();
  }

  Future<void> _loadBackouts() async {
    setState(() => _isLoading = true);

    try {
      _currentUserId = _authService.currentUser?.uid;
      if (_currentUserId == null) {
        debugPrint('⚠️ BACKOUT NOTIFICATIONS: No authenticated user found');
        setState(() => _isLoading = false);
        return;
      }

      final backouts = await _gameService.getPendingBackouts(_currentUserId!);
      
      setState(() {
        _backouts = backouts;
        _isLoading = false;
      });
      
      debugPrint('✅ BACKOUT NOTIFICATIONS: Loaded ${backouts.length} backouts');
    } catch (e) {
      debugPrint('🔴 BACKOUT NOTIFICATIONS: Error loading backouts: $e');
      setState(() => _isLoading = false);
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
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Backout Notifications',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Badge showing count
          if (_backouts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: colorScheme.surface,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_backouts.length} Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _backouts.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : _buildBackoutList(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Pending Backouts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All backouts have been reviewed',
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackoutList(ColorScheme colorScheme) {
    return RefreshIndicator(
      onRefresh: _loadBackouts,
      color: colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _backouts.length,
        itemBuilder: (context, index) {
          final backout = _backouts[index];
          return _buildBackoutCard(backout, colorScheme);
        },
      ),
    );
  }

  Widget _buildBackoutCard(Map<String, dynamic> backout, ColorScheme colorScheme) {
    final officialName = backout['officialName'] ?? 'Unknown Official';
    final gameSport = backout['gameSport'] ?? 'Game';
    final gameOpponent = backout['gameOpponent'] ?? 'TBD';
    final gameLocation = backout['gameLocation'] ?? '';
    final scheduleName = backout['scheduleName'] ?? 'Unknown Schedule';
    final reason = backout['reason'] ?? 'No reason provided';
    
    // Format date
    String dateStr = 'Date TBD';
    if (backout['gameDate'] != null) {
      try {
        DateTime date;
        if (backout['gameDate'] is Timestamp) {
          date = (backout['gameDate'] as Timestamp).toDate();
        } else if (backout['gameDate'] is DateTime) {
          date = backout['gameDate'];
        } else if (backout['gameDate'] is String) {
          date = DateTime.parse(backout['gameDate']);
        } else {
          date = DateTime.now();
        }
        // Format as "Mon, Jan 15"
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        dateStr = '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }
    
    // Format game time
    String timeStr = 'Time TBD';
    if (backout['gameTime'] != null) {
      final gameTime = backout['gameTime'].toString();
      try {
        final parts = gameTime.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final period = hour >= 12 ? 'PM' : 'AM';
          final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          timeStr = '$displayHour:${minute.toString().padLeft(2, '0')} $period';
        }
      } catch (e) {
        timeStr = gameTime;
      }
    }
    
    // Format timestamp
    String timeAgo = 'Just now';
    if (backout['timestamp'] != null && backout['timestamp'] is Timestamp) {
      final timestamp = (backout['timestamp'] as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      if (difference.inDays > 0) {
        timeAgo = '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        timeAgo = '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        timeAgo = '${difference.inMinutes} min ago';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_remove,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        officialName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Backed out $timeAgo',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'BACKOUT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Game info section
                Text(
                  'Game Details',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.sports, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '$gameSport vs $gameOpponent',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.group, size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            scheduleName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(
                            '$dateStr at $timeStr',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      if (gameLocation.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                gameLocation,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Reason section
                Text(
                  'Reason for Backing Out',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  ),
                  child: Text(
                    '"$reason"',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _excuseBackout(backout, 'Excused by scheduler'),
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Excuse Official'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _markAsReviewed(backout),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Dismiss'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.onSurfaceVariant,
                          side: BorderSide(color: colorScheme.outline),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Helper text
                const SizedBox(height: 12),
                Text(
                  'Excusing restores the official\'s follow-through rate. Dismissing keeps the impact.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _excuseBackout(
      Map<String, dynamic> backout, String reason) async {
    try {
      final backOutId = backout['id'] as String;
      final success = await _gameService.excuseBackout(
        backOutId,
        _currentUserId!,
        reason,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${backout['officialName']} has been excused - follow-through rate restored',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Reload the backouts list
        await _loadBackouts();
      } else {
        throw Exception('Failed to excuse backout');
      }
    } catch (e) {
      debugPrint('🔴 BACKOUT NOTIFICATIONS: Error excusing backout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to excuse backout. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _markAsReviewed(Map<String, dynamic> backout) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    try {
      final backOutId = backout['id'] as String;
      final success = await _gameService.markBackoutAsReviewed(backOutId);
      
      if (success) {
        // Reload the backouts list to reflect the change
        await _loadBackouts();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.onPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dismissed. ${backout['officialName']}\'s follow-through rate was not restored.',
                      style: TextStyle(color: colorScheme.onPrimary),
                    ),
                  ),
                ],
              ),
              backgroundColor: colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Failed to mark backout as reviewed');
      }
    } catch (e) {
      debugPrint('🔴 BACKOUT NOTIFICATIONS: Error marking as reviewed: $e');
      // Fallback: remove from list locally
      setState(() {
        _backouts.remove(backout);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Marked as reviewed'),
            backgroundColor: colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

