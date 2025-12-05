import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';

/// Admin screen for viewing and editing user details
class AdminUserDetailScreen extends StatefulWidget {
  const AdminUserDetailScreen({super.key});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final AdminService _adminService = AdminService();
  
  UserModel? _user;
  List<Map<String, dynamic>> _backouts = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args != _userId) {
      _userId = args;
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (_userId == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = await _adminService.getUserById(_userId!);
      final backouts = await _adminService.getBackoutsForUser(_userId!);
      
      if (mounted) {
        setState(() {
          _user = user;
          _backouts = backouts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    final initials =
        parts.where((p) => p.isNotEmpty).map((p) => p[0].toUpperCase()).join();
    return initials.isNotEmpty ? initials : 'U';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Loading...', style: TextStyle(color: colorScheme.primary)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('User Not Found', style: TextStyle(color: colorScheme.error)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'User not found',
                style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
      );
    }

    final isOfficial = _user!.role == 'official';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Details',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onSelected: (value) => _handleMenuAction(value, colorScheme),
            itemBuilder: (context) => [
              if (isOfficial) ...[
                const PopupMenuItem(
                  value: 'reset_stats',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Reset Follow-Through'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset_endorsements',
                  child: Row(
                    children: [
                      Icon(Icons.thumb_down, size: 20),
                      SizedBox(width: 8),
                      Text('Reset Endorsements'),
                    ],
                  ),
                ),
              ],
              PopupMenuItem(
                value: _user!.isAdmin ? 'revoke_admin' : 'grant_admin',
                child: Row(
                  children: [
                    Icon(
                      _user!.isAdmin ? Icons.remove_moderator : Icons.add_moderator,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_user!.isAdmin ? 'Revoke Admin' : 'Grant Admin'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete User', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          color: colorScheme.primary,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                _buildProfileHeader(colorScheme),
                const SizedBox(height: 24),

                // Basic Info
                _buildInfoSection(colorScheme),
                const SizedBox(height: 24),

                // Official Stats (if official)
                if (isOfficial) ...[
                  _buildOfficialStats(colorScheme),
                  const SizedBox(height: 24),
                  _buildBackoutsSection(colorScheme),
                ],

                // Scheduler Info (if scheduler)
                if (!isOfficial) _buildSchedulerInfo(colorScheme),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(35),
            ),
            child: Center(
              child: Text(
                _getInitials(_user!.fullName),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _user!.fullName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    if (_user!.isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _user!.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _user!.role == 'official'
                        ? colorScheme.primary.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _user!.role == 'official'
                        ? 'Official'
                        : (_user!.schedulerProfile?.type ?? 'Scheduler'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _user!.role == 'official'
                          ? colorScheme.primary
                          : Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('User ID', _user!.id, colorScheme),
          _buildInfoRow('Phone', _user!.profile.phone.isNotEmpty ? _user!.profile.phone : 'Not set', colorScheme),
          _buildInfoRow('Created', DateFormat('MMM d, yyyy').format(_user!.createdAt), colorScheme),
          _buildInfoRow('Last Updated', DateFormat('MMM d, yyyy').format(_user!.updatedAt), colorScheme),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficialStats(ColorScheme colorScheme) {
    final profile = _user!.officialProfile!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Official Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showEditStatsDialog(colorScheme),
                icon: Icon(Icons.edit, size: 16, color: colorScheme.primary),
                label: Text('Edit', style: TextStyle(color: colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Follow-Through',
                  '${profile.followThroughRate.toStringAsFixed(1)}%',
                  colorScheme,
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Games',
                  '${profile.totalAcceptedGames}',
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Backed Out',
                  '${profile.totalBackedOutGames}',
                  colorScheme,
                  isWarning: profile.totalBackedOutGames > 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Scheduler Endorsements',
                  '${profile.schedulerEndorsements}',
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Official Endorsements',
                  '${profile.officialEndorsements}',
                  colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Experience',
                  '${profile.experienceYears ?? 0} years',
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Location',
                  '${profile.city}, ${profile.state}',
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, ColorScheme colorScheme, {
    bool highlighted = false,
    bool isWarning = false,
  }) {
    Color valueColor = colorScheme.onSurface;
    if (highlighted) valueColor = colorScheme.primary;
    if (isWarning) valueColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: highlighted
            ? Border.all(color: colorScheme.primary.withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBackoutsSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backout History (${_backouts.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          if (_backouts.isEmpty)
            Text(
              'No backouts recorded',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...(_backouts.take(5).map((backout) => _buildBackoutTile(backout, colorScheme))),
          if (_backouts.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    // TODO: Show all backouts dialog
                  },
                  child: Text(
                    'View all ${_backouts.length} backouts',
                    style: TextStyle(color: colorScheme.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBackoutTile(Map<String, dynamic> backout, ColorScheme colorScheme) {
    final isExcused = backout['excused'] == true;
    final gameDate = backout['gameDate'] ?? 'Unknown date';
    final reason = backout['reason'] ?? 'No reason provided';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isExcused
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExcused ? Icons.check_circle : Icons.cancel,
            color: isExcused ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameDate.toString(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  reason,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              isExcused ? Icons.undo : Icons.check,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () => _toggleBackoutForgiveness(backout, colorScheme),
            tooltip: isExcused ? 'Unforgive' : 'Forgive',
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulerInfo(ColorScheme colorScheme) {
    final profile = _user!.schedulerProfile;
    if (profile == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scheduler Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Type', profile.type, colorScheme),
          if (profile.schoolName != null)
            _buildInfoRow('School', profile.schoolName!, colorScheme),
          if (profile.teamName != null)
            _buildInfoRow('Team', profile.teamName!, colorScheme),
          if (profile.organizationName != null)
            _buildInfoRow('Organization', profile.organizationName!, colorScheme),
          if (profile.sport != null)
            _buildInfoRow('Sport', profile.sport!, colorScheme),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, ColorScheme colorScheme) {
    switch (action) {
      case 'reset_stats':
        _showResetStatsDialog(colorScheme);
        break;
      case 'reset_endorsements':
        _showResetEndorsementsDialog(colorScheme);
        break;
      case 'grant_admin':
      case 'revoke_admin':
        _showAdminToggleDialog(action == 'grant_admin', colorScheme);
        break;
      case 'delete':
        _showDeleteUserDialog(colorScheme);
        break;
    }
  }

  void _showResetStatsDialog(ColorScheme colorScheme) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          'Reset Follow-Through Stats',
          style: TextStyle(color: colorScheme.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will reset ${_user!.fullName}\'s follow-through rate to 100% and delete all backout records.',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Reason for reset',
                hintText: 'Enter the reason for this action...',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context);
              await _resetStats(reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetStats(String reason) async {
    final success = await _adminService.resetFollowThroughStats(_userId!, reason);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Follow-through stats reset successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reset stats'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditStatsDialog(ColorScheme colorScheme) {
    final profile = _user!.officialProfile!;
    final rateController = TextEditingController(text: profile.followThroughRate.toStringAsFixed(1));
    final gamesController = TextEditingController(text: profile.totalAcceptedGames.toString());
    final backoutsController = TextEditingController(text: profile.totalBackedOutGames.toString());
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Edit Statistics', style: TextStyle(color: colorScheme.primary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Follow-Through Rate (%)',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gamesController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Total Accepted Games',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: backoutsController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Total Backed Out Games',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  labelText: 'Reason for change',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              final rate = double.tryParse(rateController.text);
              final games = int.tryParse(gamesController.text);
              final backouts = int.tryParse(backoutsController.text);
              
              if (rate == null || games == null || backouts == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid numbers')),
                );
                return;
              }
              
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final success = await _adminService.updateOfficialStats(
                officialId: _userId!,
                followThroughRate: rate.clamp(0.0, 100.0),
                totalAcceptedGames: games,
                totalBackedOutGames: backouts,
                reason: reasonController.text.trim(),
              );
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Statistics updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadUserData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update statistics'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetEndorsementsDialog(ColorScheme colorScheme) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Reset Endorsements', style: TextStyle(color: colorScheme.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This will reset all endorsements for ${_user!.fullName} to zero.',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Reason',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context);
              
              final success = await _adminService.resetEndorsements(
                _userId!,
                reasonController.text.trim(),
              );
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Endorsements reset successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadUserData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reset endorsements'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAdminToggleDialog(bool granting, ColorScheme colorScheme) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          granting ? 'Grant Admin Access' : 'Revoke Admin Access',
          style: TextStyle(color: colorScheme.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              granting
                  ? 'This will give ${_user!.fullName} full admin privileges.'
                  : 'This will remove admin privileges from ${_user!.fullName}.',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Reason',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context);
              
              final success = await _adminService.setUserAdminStatus(
                _userId!,
                granting,
                reasonController.text.trim(),
              );
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(granting
                          ? 'Admin access granted'
                          : 'Admin access revoked'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadUserData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to update admin status'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: granting ? Colors.green : Colors.orange,
            ),
            child: Text(
              granting ? 'Grant' : 'Revoke',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteUserDialog(ColorScheme colorScheme) {
    final reasonController = TextEditingController();
    final confirmController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text(
          'Delete User',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚠️ WARNING: This action cannot be undone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'This will permanently delete ${_user!.fullName} and all associated data.',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Reason for deletion',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              style: TextStyle(color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Type "DELETE" to confirm',
                border: const OutlineInputBorder(),
                labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (confirmController.text != 'DELETE') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please type DELETE to confirm')),
                );
                return;
              }
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context);
              
              final success = await _adminService.deleteUser(
                _userId!,
                reasonController.text.trim(),
              );
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Go back to user list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete user'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBackoutForgiveness(Map<String, dynamic> backout, ColorScheme colorScheme) async {
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
            child: Text(isExcused ? 'Unforgive' : 'Forgive'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      bool success;
      if (isExcused) {
        success = await _adminService.unforgiveBackout(backoutId, reasonController.text.trim());
      } else {
        success = await _adminService.forgiveBackout(backoutId, reasonController.text.trim());
      }
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isExcused ? 'Backout unforgiven' : 'Backout forgiven'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadUserData();
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

