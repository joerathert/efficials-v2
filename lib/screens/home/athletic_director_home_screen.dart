import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../providers/theme_provider.dart';

class AthleticDirectorHomeScreen extends StatefulWidget {
  const AthleticDirectorHomeScreen({super.key});

  @override
  State<AthleticDirectorHomeScreen> createState() =>
      _AthleticDirectorHomeScreenState();
}

class _AthleticDirectorHomeScreenState
    extends State<AthleticDirectorHomeScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> publishedGames = [];
  int _alertDays = 7;
  String _alertUnit = 'days';
  bool isFabExpanded = false;
  bool showPastGames = false;
  bool isPullingDown = false;
  double pullDistance = 0.0;
  static const double pullThreshold = 80.0;
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadAlertPreferences();
    _fetchGames();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['refresh'] == true) {
        _fetchGames();
        // Show success message if a game was just published
        if (args['gamePublished'] == true && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Game published successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          });
        }
      }
    }
  }

  Future<void> _loadAlertPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _alertDays = prefs.getInt('alert_days') ?? 7;
      _alertUnit = prefs.getString('alert_unit') ?? 'days';
    });
  }

  IconData _getSportIcon(String sport) {
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

  bool _shouldShowAlert(DateTime gameDate) {
    final now = DateTime.now();
    final difference = gameDate.difference(now);

    switch (_alertUnit) {
      case 'days':
        return difference.inDays <= _alertDays && difference.inDays >= 0;
      case 'weeks':
        return difference.inDays <= (_alertDays * 7) && difference.inDays >= 0;
      case 'months':
        return difference.inDays <= (_alertDays * 30) && difference.inDays >= 0;
      default:
        return difference.inDays <= _alertDays && difference.inDays >= 0;
    }
  }

  Future<void> _fetchGames() async {
    try {
      // Fetch games from Firestore (both published and unpublished)
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('games').get();

      final games = snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore data back to the format expected by the UI
        return {
          'id': doc.id,
          'scheduleId': data['scheduleId'],
          'scheduleName': data['scheduleName'],
          'sport': data['sport'],
          'date': data['date'] != null ? DateTime.parse(data['date']) : null,
          'time': data['time'] != null
              ? TimeOfDay(
                  hour: int.parse(data['time'].split(':')[0]),
                  minute: int.parse(data['time'].split(':')[1]),
                )
              : null,
          'location': data['location'],
          'opponent': data['opponent'],
          'officialsRequired': data['officialsRequired'] ?? 0,
          'gameFee': data['gameFee'],
          'gender': data['gender'],
          'levelOfCompetition': data['levelOfCompetition'],
          'hireAutomatically': data['hireAutomatically'] ?? false,
          'method': data['method'],
          'selectedOfficials': data['selectedOfficials'],
          'selectedCrews': data['selectedCrews'],
          'selectedCrew': data['selectedCrew'],
          'selectedListName': data['selectedListName'],
          'selectedLists': data['selectedLists'],
          'officialsHired': data['officialsHired'] ?? 0,
          'status': data['status'],
          'createdAt': data['createdAt'],
          'isAway': data['isAway'] ?? false,
          'homeTeam': data['homeTeam'],
          'awayTeam': data['awayTeam'],
        };
      }).toList();

      // Sort games by date and time (chronological order, nearest first)
      games.sort((a, b) {
        final dateA = a['date'] as DateTime?;
        final dateB = b['date'] as DateTime?;
        final timeA = a['time'] as TimeOfDay?;
        final timeB = b['time'] as TimeOfDay?;

        // Handle null dates - put games without dates at the end
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        // Compare dates first
        final dateComparison = dateA.compareTo(dateB);
        if (dateComparison != 0) return dateComparison;

        // If dates are the same, compare times
        if (timeA == null && timeB == null) return 0;
        if (timeA == null) return 1;
        if (timeB == null) return -1;

        // Compare times
        final timeAInMinutes = timeA.hour * 60 + timeA.minute;
        final timeBInMinutes = timeB.hour * 60 + timeB.minute;
        return timeAInMinutes.compareTo(timeBInMinutes);
      });

      setState(() {
        publishedGames = games;
        _isLoading = false;
      });

      debugPrint('Fetched ${games.length} games from Firestore');
      // Debug: log the status of each game
      for (var game in games) {
        debugPrint(
            'Game: ${game['scheduleName']} - Status: ${game['status']} - Date: ${game['date']}');
      }
    } catch (e) {
      debugPrint('Error fetching games: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading games: $e')),
        );
      }
      setState(() {
        publishedGames = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterGamesByTime(
      List<Map<String, dynamic>> games, bool getPastGames) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return games.where((game) {
      // Only show published games in the upcoming/past games lists
      final status = game['status'] as String?;
      if (status != 'Published') return false;

      final gameDate = game['date'] as DateTime?;
      if (gameDate != null) {
        final gameDay = DateTime(gameDate.year, gameDate.month, gameDate.day);
        final isPastGame = gameDay.isBefore(today);
        if (getPastGames && !isPastGame) return false;
        if (!getPastGames && isPastGame) return false;
      }
      return true;
    }).toList();
  }

  Widget _buildGamesList(List<Map<String, dynamic>> pastGames,
      List<Map<String, dynamic>> upcomingGames) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (upcomingGames.isEmpty && pastGames.isEmpty) {
      final bool hasAnyGames = publishedGames.isNotEmpty;

      if (!hasAnyGames) {
        // No games exist - show welcome message
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, -80),
                  child: Column(
                    children: [
                      Icon(
                        Icons.sports,
                        size: 80,
                        color: theme.brightness == Brightness.dark
                            ? colorScheme.primary // Yellow in dark mode
                            : Colors.black, // Black in light mode
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to Efficials!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? colorScheme.primary
                              : colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Get started by adding your first game to manage schedules and officials.',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isFabExpanded = true;
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        label: const Text(
                          'Add Your First Game',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Games exist but are filtered out - show filter message
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, -80),
                  child: Column(
                    children: [
                      Text(
                        'No Games Found',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You have ${publishedGames.length} game${publishedGames.length == 1 ? '' : 's'} created, but ${publishedGames.length == 1 ? 'it is' : 'they are'} currently hidden by your filter settings.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  Container(), // TODO: Add filter screen
                            ),
                          );
                        },
                        icon: const Icon(Icons.filter_list, size: 24),
                        label: const Text(
                          'Adjust Filters',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            // Reset all filters to show all games
                            // TODO: Reset filters
                          });
                        },
                        child: Text(
                          'Show All Games',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (!showPastGames) {
      return ListView.builder(
        itemCount: upcomingGames.length,
        itemBuilder: (context, index) {
          final game = upcomingGames[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildGameTile(game),
          );
        },
      );
    } else {
      return ListView.builder(
        controller: scrollController,
        itemCount: pastGames.length + upcomingGames.length,
        itemBuilder: (context, index) {
          if (index >= pastGames.length) {
            final upcomingIndex = index - pastGames.length;
            final game = upcomingGames[upcomingIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildGameTile(game),
            );
          } else {
            final game = pastGames[pastGames.length - 1 - index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildGameTile(game),
            );
          }
        },
      );
    }
  }

  Widget _buildGameTile(Map<String, dynamic> game) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final gameDate = game['date'] as DateTime?;
    final gameTime = game['time'] as TimeOfDay?;
    final sport = game['sport'] as String? ?? 'Unknown Sport';
    final opponent = game['opponent'] as String?;
    final officialsRequired = game['officialsRequired'] as int? ?? 5;
    final officialsHired = game['officialsHired'] as int? ?? 0;
    final levelOfCompetition =
        game['levelOfCompetition'] as String? ?? 'Varsity';
    final isAway = game['isAway'] as bool? ?? false;

    // Format date as requested: "Friday, Sep 12, 2025"
    final formattedDate = gameDate != null
        ? DateFormat('EEEE, MMM d, yyyy').format(gameDate)
        : 'Not set';

    // Format time as requested: "7:00 PM"
    final formattedTime = gameTime != null
        ? '${gameTime.hourOfPeriod}:${gameTime.minute.toString().padLeft(2, '0')} ${gameTime.period.name.toUpperCase()}'
        : 'Not set';

    // Format opponent display
    final opponentDisplay =
        opponent != null ? (isAway ? '@ $opponent' : 'vs $opponent') : '';

    // Determine officials count background color
    final shouldAlert = gameDate != null ? _shouldShowAlert(gameDate) : false;
    final officialsBackgroundColor =
        shouldAlert && officialsHired < officialsRequired
            ? Colors.red.withOpacity(0.1)
            : colorScheme.primary.withOpacity(0.1);

    final officialsTextColor = shouldAlert && officialsHired < officialsRequired
        ? Colors.red
        : colorScheme.primary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: GestureDetector(
          onTap: () {
            // TODO: Navigate to game details
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Game details coming soon!')),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getSportIcon(sport),
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date line
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Time and opponent line
                      Text(
                        '$formattedTime $opponentDisplay',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Sport and level line
                      Text(
                        '$levelOfCompetition $sport',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Officials count
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: officialsBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$officialsHired/$officialsRequired Officials',
                          style: TextStyle(
                            fontSize: 12,
                            color: officialsTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onShowPastGames() {
    setState(() {
      showPastGames = true;
      pullDistance = 0.0;
      isPullingDown = false;
    });

    // Ensure layout is complete and adjust scroll position
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        final pastGames = _filterGamesByTime(publishedGames, true);
        final upcomingGames = _filterGamesByTime(publishedGames, false);
        if (upcomingGames.isNotEmpty) {
          // Calculate the index where upcoming games start
          final firstUpcomingIndex = pastGames.length;
          // Estimate the height of each game tile (adjust based on actual measurement)
          const double estimatedTileHeight = 160.0; // Current estimate
          // Initial target offset
          double targetOffset = firstUpcomingIndex * estimatedTileHeight;
          // Get initial max scroll extent
          final initialMaxScrollExtent =
              scrollController.position.maxScrollExtent;

          // If maxScrollExtent is too small, delay and retry with a longer wait
          if (targetOffset > initialMaxScrollExtent) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (scrollController.hasClients) {
                final updatedMaxScrollExtent =
                    scrollController.position.maxScrollExtent;
                targetOffset = firstUpcomingIndex *
                    estimatedTileHeight.clamp(0.0, updatedMaxScrollExtent);
                scrollController
                    .jumpTo(targetOffset.clamp(0.0, updatedMaxScrollExtent));
              }
            });
          } else {
            scrollController
                .jumpTo(targetOffset.clamp(0.0, initialMaxScrollExtent));
          }
        }
      }
    });
  }

  void _handleLogout() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Logout',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog

                // Clear user session
                // TODO: Implement session clearing

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                ); // Go to welcome screen and clear navigation stack
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    final upcomingGames = _filterGamesByTime(publishedGames, false);
    final pastGames = _filterGamesByTime(publishedGames, true);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Icon(
              Icons.sports,
              color:
                  themeProvider.isDarkMode ? colorScheme.primary : Colors.black,
              size: 32,
            );
          },
        ),
        centerTitle: true,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: colorScheme.onSurface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
              decoration: BoxDecoration(color: colorScheme.surface),
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8.0,
                    bottom: 8.0,
                    left: 16.0,
                    right: 16.0),
                child: Text(
                  'Menu',
                  style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.sports, color: colorScheme.primary),
              title: Text('Game Templates',
                  style: TextStyle(color: colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/game-templates');
              },
            ),
            ListTile(
              leading: Icon(Icons.schedule, color: colorScheme.primary),
              title: Text('Schedules',
                  style: TextStyle(color: colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/select-schedule');
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: colorScheme.primary),
              title: Text('Lists of Officials',
                  style: TextStyle(color: colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/lists-of-officials',
                    arguments: {'fromHamburgerMenu': true});
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: colorScheme.primary),
              title: Text('Settings',
                  style: TextStyle(color: colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!showPastGames && upcomingGames.isNotEmpty) ...[
                          Text(
                            'Upcoming Games',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onBackground,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Expanded(
                          child: _buildGamesList(pastGames, upcomingGames),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 40,
            right: (MediaQuery.of(context).size.width -
                        (MediaQuery.of(context).size.width > 550
                            ? 550
                            : MediaQuery.of(context).size.width)) /
                    2 +
                20, // Position FAB 20px from the right edge of the constrained content area
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isFabExpanded) ...[
                  AnimatedOpacity(
                    opacity: isFabExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FloatingActionButton.extended(
                        heroTag: "fab_use_template",
                        onPressed: () {
                          setState(() {
                            isFabExpanded = false;
                          });
                          Navigator.pushNamed(context, '/game-templates');
                        },
                        backgroundColor: colorScheme.primary,
                        label: Text('Use Game Template',
                            style: TextStyle(color: colorScheme.onPrimary)),
                        icon: Icon(Icons.copy, color: colorScheme.onPrimary),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: isFabExpanded ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FloatingActionButton.extended(
                        heroTag: "fab_start_scratch",
                        onPressed: () {
                          setState(() {
                            isFabExpanded = false;
                          });
                          Navigator.pushNamed(context, '/select-schedule');
                        },
                        backgroundColor: colorScheme.primary,
                        label: Text('Start from Scratch',
                            style: TextStyle(color: colorScheme.onPrimary)),
                        icon: Icon(Icons.add, color: colorScheme.onPrimary),
                      ),
                    ),
                  ),
                ],
                FloatingActionButton(
                  heroTag: "fab_main",
                  onPressed: () {
                    setState(() {
                      isFabExpanded = !isFabExpanded;
                    });
                  },
                  backgroundColor: colorScheme.surfaceVariant,
                  child: Icon(isFabExpanded ? Icons.close : Icons.add,
                      size: 30, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
