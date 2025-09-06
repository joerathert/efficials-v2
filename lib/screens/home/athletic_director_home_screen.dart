import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  List<Map<String, dynamic>> publishedGames = []; // Mock games data for now
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
    _fetchGames();
  }

  Future<void> _fetchGames() async {
    try {
      // For now, use mock data - we'll replace with actual service calls
      setState(() {
        publishedGames = []; // Empty for initial state
        _isLoading = false;
      });
    } catch (e) {
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

  void _onShowPastGames() {
    setState(() {
      showPastGames = true;
      pullDistance = 0.0;
      isPullingDown = false;
    });
  }

  List<Map<String, dynamic>> _filterGamesByTime(
      List<Map<String, dynamic>> games, bool getPastGames) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return games.where((game) {
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
                        'You have ${publishedGames.length} game${publishedGames.length == 1 ? '' : 's'} created, but they are currently hidden by your filter settings.',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to filter screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Filter screen coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.filter_list, size: 24),
                        label: const Text(
                          'Adjust Filters',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: colorScheme.onSecondary,
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

    final gameTitle = game['scheduleName'] as String? ?? 'Not set';
    final gameDate = game['date'] != null
        ? (game['date'] as DateTime).toString().split(' ')[0]
        : 'Not set';
    final gameTime = game['time'] != null ? 'Time: ${game['time']}' : 'Not set';
    final sport = game['sport'] as String? ?? 'Unknown Sport';

    return GestureDetector(
      onTap: () {
        // TODO: Navigate to game details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Game details for $gameTitle coming soon!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.2),
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
                Icons.sports,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameDate,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$gameTime - $gameTitle',
                    style:
                        TextStyle(fontSize: 16, color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sport,
                          style: TextStyle(
                              fontSize: 12, color: colorScheme.secondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              color: themeProvider.isDarkMode
                  ? colorScheme.primary // Yellow in dark mode
                  : Colors.black, // Black in light mode
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
              leading: Icon(Icons.settings, color: colorScheme.primary),
              title: Text('Settings',
                  style: TextStyle(color: colorScheme.onSurface)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            const Divider(color: Colors.grey),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement logout
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logout coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onPanUpdate: (details) {
            if (details.delta.dy > 0) {
              setState(() {
                pullDistance = (pullDistance + details.delta.dy)
                    .clamp(0.0, pullThreshold * 1.5);
                isPullingDown = pullDistance > 10;
              });
            }
          },
          onPanEnd: (details) {
            if (pullDistance >= pullThreshold && !showPastGames) {
              _onShowPastGames();
            } else {
              setState(() {
                pullDistance = 0.0;
                isPullingDown = false;
              });
            }
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: pullDistance > 0
                    ? pullDistance.clamp(0.0, pullThreshold)
                    : 0,
                child: pullDistance > 0
                    ? Container(
                        width: double.infinity,
                        color: colorScheme.background,
                        child: Center(
                          child: Text(
                            pullDistance >= pullThreshold
                                ? 'Release to view past games'
                                : 'View past games',
                            style: TextStyle(
                              fontSize: 16,
                              color: pullDistance >= pullThreshold
                                  ? colorScheme.secondary
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
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
      floatingActionButton: Column(
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
    );
  }
}
