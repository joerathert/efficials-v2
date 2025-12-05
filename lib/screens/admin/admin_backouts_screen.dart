import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

/// Admin screen for managing all backouts
class AdminBackoutsScreen extends StatefulWidget {
  const AdminBackoutsScreen({super.key});

  @override
  State<AdminBackoutsScreen> createState() => _AdminBackoutsScreenState();
}

class _AdminBackoutsScreenState extends State<AdminBackoutsScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _allBackouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBackouts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBackouts() async {
    setState(() => _isLoading = true);
    
    try {
      final backouts = await _adminService.getAllBackouts(limit: 100);
      
      if (mounted) {
        setState(() {
          _allBackouts = backouts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading backouts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _pendingBackouts =>
      _allBackouts.where((b) => b['excused'] != true).toList();

  List<Map<String, dynamic>> get _forgivenBackouts =>
      _allBackouts.where((b) => b['excused'] == true).toList();

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return date;
      }
    } else {
      return 'Unknown';
    }
    
    return DateFormat('MMM d, yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Backouts',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorColor: colorScheme.primary,
          tabs: [
            Tab(text: 'All (${_allBackouts.length})'),
            Tab(text: 'Pending (${_pendingBackouts.length})'),
            Tab(text: 'Forgiven (${_forgivenBackouts.length})'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBackoutList(_allBackouts, colorScheme),
                  _buildBackoutList(_pendingBackouts, colorScheme),
                  _buildBackoutList(_forgivenBackouts, colorScheme),
                ],
              ),
      ),
    );
  }

  Widget _buildBackoutList(
    List<Map<String, dynamic>> backouts,
    ColorScheme colorScheme,
  ) {
    if (backouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No backouts in this category',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBackouts,
      color: colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: backouts.length,
        itemBuilder: (context, index) {
          return _buildBackoutTile(backouts[index], colorScheme);
        },
      ),
    );
  }

  Widget _buildBackoutTile(Map<String, dynamic> backout, ColorScheme colorScheme) {
    final isExcused = backout['excused'] == true;
    final gameDate = _formatDate(backout['gameDate']);
    final createdAt = _formatDate(backout['createdAt']);
    final reason = backout['reason'] as String? ?? 'No reason provided';
    final officialId = backout['officialId'] as String? ?? 'Unknown';
    final gameSport = backout['gameSport'] as String? ?? 'Unknown Sport';
    final gameOpponent = backout['gameOpponent'] as String? ?? 'Unknown';
    final excuseReason = backout['excuseReason'] as String?;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExcused
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExcused
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExcused ? Icons.check_circle : Icons.cancel,
                        size: 14,
                        color: isExcused ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExcused ? 'FORGIVEN' : 'PENDING',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isExcused ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Backed out: $createdAt',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Game info
            Text(
              '$gameSport: vs $gameOpponent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              'Game Date: $gameDate',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            // Reason
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: $reason',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Excuse reason if forgiven
            if (isExcused && excuseReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Forgiven: $excuseReason',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/admin/user-detail',
                      arguments: officialId,
                    );
                  },
                  icon: Icon(Icons.person, size: 16, color: colorScheme.primary),
                  label: Text(
                    'View Official',
                    style: TextStyle(color: colorScheme.primary, fontSize: 13),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _toggleBackoutForgiveness(backout, colorScheme),
                  icon: Icon(
                    isExcused ? Icons.undo : Icons.check,
                    size: 16,
                  ),
                  label: Text(isExcused ? 'Unforgive' : 'Forgive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isExcused ? Colors.orange : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBackoutForgiveness(
    Map<String, dynamic> backout,
    ColorScheme colorScheme,
  ) async {
    final isExcused = backout['excused'] == true;
    final backoutId = backout['id'] as String;
    
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          isExcused ? 'Unforgive Backout' : 'Forgive Backout',
          style: TextStyle(color: colorScheme.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isExcused
                  ? 'This will count the backout against the official\'s stats again.'
                  : 'This will excuse the backout and not count it against the official.',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter the reason for this action...',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isExcused ? Colors.orange : Colors.green,
            ),
            child: Text(
              isExcused ? 'Unforgive' : 'Forgive',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      bool success;
      if (isExcused) {
        success = await _adminService.unforgiveBackout(
          backoutId,
          reasonController.text.trim(),
        );
      } else {
        success = await _adminService.forgiveBackout(
          backoutId,
          reasonController.text.trim(),
        );
      }
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isExcused ? 'Backout unforgiven' : 'Backout forgiven'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadBackouts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update backout'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

