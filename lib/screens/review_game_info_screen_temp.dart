import 'package:flutter/material.dart';
import '../app_colors.dart';

class ReviewGameInfoScreen extends StatefulWidget {
  const ReviewGameInfoScreen({super.key});

  @override
  State<ReviewGameInfoScreen> createState() => _ReviewGameInfoScreenState();
}

class _ReviewGameInfoScreenState extends State<ReviewGameInfoScreen> {
  late Map<String, dynamic> args;
  late Map<String, dynamic> originalArgs;
  bool isEditMode = false;
  bool isFromGameInfo = false;
  bool isAwayGame = false;
  bool fromScheduleDetails = false;
  int? scheduleId;
  bool? isCoachScheduler;
  String? teamName;
  bool isUsingTemplate = false;
  bool _isPublishing = false;
  bool _showButtonLoading = false;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasInitialized) {
      final newArgs =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      setState(() {
        args = Map<String, dynamic>.from(newArgs);
        originalArgs = Map<String, dynamic>.from(newArgs);
        isEditMode = newArgs['isEdit'] == true;
        isFromGameInfo = newArgs['isFromGameInfo'] == true;
        isAwayGame = newArgs['isAway'] == true;
        fromScheduleDetails = newArgs['fromScheduleDetails'] == true;
        scheduleId = newArgs['scheduleId'] as int?;
        isUsingTemplate = newArgs['template'] != null;
        if (args['officialsRequired'] != null) {
          args['officialsRequired'] =
              int.tryParse(args['officialsRequired'].toString()) ?? 0;
        }
        _hasInitialized = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    args = {};
    originalArgs = {};
    _hasInitialized = false;
  }

  Future<void> _publishGame() async {
    if (_isPublishing) return;

    setState(() {
      _isPublishing = true;
      _showButtonLoading = true;
    });

    try {
      if (args['time'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please set a game time before publishing.')),
        );
        return;
      }

      if (!isAwayGame &&
              !(args['hireAutomatically'] == true) &&
              args['selectedOfficials'] == null ||
          (args['selectedOfficials'] as List).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please select at least one official for non-away games.')),
        );
        return;
      }

      final gameData = Map<String, dynamic>.from(args);
      gameData['id'] = gameData['id'] ?? DateTime.now().millisecondsSinceEpoch;
      gameData['createdAt'] = DateTime.now().toIso8601String();
      gameData['officialsHired'] = gameData['officialsHired'] ?? 0;
      gameData['status'] = 'Published';

      if (gameData['scheduleName'] == null) {
        gameData['scheduleName'] = 'Team Schedule';
      }

      // TODO: Implement game publishing logic
      // For now, just show a placeholder message
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Game publishing functionality coming soon!')),
        );
        _navigateBack();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
          _showButtonLoading = false;
        });
      }
    }
  }

  Future<void> _publishUpdate() async {
    // TODO: Implement publish update functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publish update not yet implemented')),
    );
  }

  Future<void> _publishLater() async {
    // TODO: Implement publish later functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Publish later not yet implemented')),
    );
  }

  void _navigateBack() {
    if (fromScheduleDetails) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/schedule_details',
        (route) => false,
        arguments: {
          'scheduleName': args['scheduleName'],
          'scheduleId': scheduleId,
        },
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/athletic_director_home',
        (route) => false,
        arguments: {'refresh': true},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Create gameDetails map
    final gameDetails = <String, String>{
      'Sport': args['sport'] as String? ?? 'Unknown',
      'Schedule Name': args['scheduleName'] as String? ?? 'Unnamed',
      'Date': args['date'] != null
          ? '${(args['date'] as DateTime).month}/${(args['date'] as DateTime).day}/${(args['date'] as DateTime).year}'
          : 'Not set',
      'Time': args['time'] != null
          ? (args['time'] as TimeOfDay).format(context)
          : 'Not set',
      'Location': args['location'] as String? ?? 'Not set',
      'Opponent': args['opponent'] as String? ?? 'Not set',
    };

    final additionalDetails = !isAwayGame
        ? {
            'Officials Required': (args['officialsRequired'] ?? 0).toString(),
            'Fee per Official':
                args['gameFee'] != null ? '\$${args['gameFee']}' : 'Not set',
            'Gender': args['gender'] as String? ?? 'Not set',
            'Competition Level':
                args['levelOfCompetition'] as String? ?? 'Not set',
            'Hire Automatically':
                args['hireAutomatically'] == true ? 'Yes' : 'No',
          }
        : {};

    final allDetails = {
      ...gameDetails,
      if (!isAwayGame) ...additionalDetails,
    };

    final isPublished = args['status'] == 'Published';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.efficialsBlack,
        title: const Icon(
          Icons.sports,
          color: AppColors.efficialsYellow,
          size: 32,
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.efficialsWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverHeaderDelegate(
              child: Container(
                color: AppColors.darkSurface,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Game Details',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.efficialsYellow)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, '/edit_game_info',
                          arguments: {
                            ...args,
                            'isEdit': true,
                            'isFromGameInfo': true,
                            'fromScheduleDetails': fromScheduleDetails,
                            'scheduleId': scheduleId,
                          }).then((result) {
                        if (result != null &&
                            result is Map<String, dynamic>) {
                          setState(() {
                            args = result;
                            fromScheduleDetails =
                                result['fromScheduleDetails'] == true;
                            scheduleId = result['scheduleId'] as int?;
                          });
                        }
                      }),
                      child: const Text('Edit',
                          style: TextStyle(
                              color: AppColors.efficialsYellow, fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

            // Game details
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...allDetails.entries.map(
                          (e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 150,
                                  child: Text('${e.key}:',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500)),
                                ),
                                Expanded(
                                    child: Text(e.value,
                                        style: const TextStyle(fontSize: 16))),
                              ],
                            ),
                          ),
                        ),

                        // Selected Officials section
                        if (!isAwayGame) ...[
                          const SizedBox(height: 20),
                          const Text('Selected Officials',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          if (args['selectedOfficials'] == null ||
                              (args['selectedOfficials'] as List).isEmpty)
                            const Text('No officials selected.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey))
                          else
                            ...(args['selectedOfficials'] as List<dynamic>)
                                .map((item) => item as Map<String, dynamic>)
                                .map(
                                  (official) => ListTile(
                                    title: Text(official['name'] as String),
                                    subtitle: Text(
                                        'Distance: ${(official['distance'] as num?)?.toStringAsFixed(1) ?? '0.0'} mi'),
                                  ),
                                ),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),

      bottomNavigationBar: Container(
        color: AppColors.efficialsBlack,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPublished) ...[
              ElevatedButton(
                onPressed: _publishUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.efficialsYellow,
                  foregroundColor: AppColors.efficialsBlack,
                  disabledBackgroundColor: AppColors.darkSurfaceVariant,
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Publish Update',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _isPublishing ? null : _publishGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.efficialsYellow,
                  foregroundColor: AppColors.efficialsBlack,
                  disabledBackgroundColor: AppColors.darkSurfaceVariant,
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _showButtonLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Publish Game',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isPublishing ? null : _publishLater,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkSurface,
                  foregroundColor: AppColors.efficialsWhite,
                  disabledBackgroundColor: AppColors.darkSurfaceVariant,
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _showButtonLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Publish Later',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
