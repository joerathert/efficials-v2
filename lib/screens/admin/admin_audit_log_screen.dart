import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

/// Admin screen for viewing audit log of admin actions
class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  final AdminService _adminService = AdminService();
  
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;
  String? _selectedAction;

  final List<String> _actionTypes = [
    'All Actions',
    'RESET_FOLLOW_THROUGH',
    'UPDATE_OFFICIAL_STATS',
    'RESET_ENDORSEMENTS',
    'GRANT_ADMIN',
    'REVOKE_ADMIN',
    'FORGIVE_BACKOUT',
    'UNFORGIVE_BACKOUT',
    'DELETE_USER',
  ];

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    
    try {
      final logs = await _adminService.getAuditLog(
        limit: 100,
        filterByAction: _selectedAction == 'All Actions' ? null : _selectedAction,
      );
      
      if (mounted) {
        setState(() {
          _auditLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading audit logs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'Unknown';
    }
    
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'RESET_FOLLOW_THROUGH':
        return Icons.refresh;
      case 'UPDATE_OFFICIAL_STATS':
        return Icons.edit;
      case 'RESET_ENDORSEMENTS':
        return Icons.thumb_down;
      case 'GRANT_ADMIN':
        return Icons.add_moderator;
      case 'REVOKE_ADMIN':
        return Icons.remove_moderator;
      case 'FORGIVE_BACKOUT':
        return Icons.check_circle;
      case 'UNFORGIVE_BACKOUT':
        return Icons.cancel;
      case 'DELETE_USER':
        return Icons.delete;
      default:
        return Icons.history;
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'RESET_FOLLOW_THROUGH':
      case 'RESET_ENDORSEMENTS':
        return Colors.orange;
      case 'UPDATE_OFFICIAL_STATS':
        return Colors.blue;
      case 'GRANT_ADMIN':
        return Colors.green;
      case 'REVOKE_ADMIN':
        return Colors.purple;
      case 'FORGIVE_BACKOUT':
        return Colors.green;
      case 'UNFORGIVE_BACKOUT':
        return Colors.orange;
      case 'DELETE_USER':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatActionName(String action) {
    return action
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
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
          'Audit Log',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter dropdown
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedAction ?? 'All Actions',
                    isExpanded: true,
                    dropdownColor: colorScheme.surfaceContainerHighest,
                    style: TextStyle(color: colorScheme.onSurface),
                    items: _actionTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == 'All Actions' ? type : _formatActionName(type),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAction = value;
                      });
                      _loadAuditLogs();
                    },
                  ),
                ),
              ),
            ),

            // Results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${_auditLogs.length} entries',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Audit log list
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: colorScheme.primary),
                    )
                  : _auditLogs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No audit logs found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAuditLogs,
                          color: colorScheme.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _auditLogs.length,
                            itemBuilder: (context, index) {
                              final log = _auditLogs[index];
                              return _buildLogTile(log, colorScheme);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogTile(Map<String, dynamic> log, ColorScheme colorScheme) {
    final action = log['action'] as String? ?? 'Unknown';
    final actionColor = _getActionColor(action);
    final timestamp = _formatTimestamp(log['timestamp']);
    final reason = log['reason'] as String? ?? 'No reason provided';
    final targetUserId = log['targetUserId'] as String? ?? 'Unknown';
    final adminId = log['adminId'] as String? ?? 'Unknown';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: actionColor.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: actionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getActionIcon(action),
            color: actionColor,
            size: 20,
          ),
        ),
        title: Text(
          _formatActionName(action),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          timestamp,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                _buildDetailRow('Admin ID', adminId, colorScheme),
                _buildDetailRow('Target User', targetUserId, colorScheme),
                _buildDetailRow('Reason', reason, colorScheme),
                if (log['previousData'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Previous Data:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatMap(log['previousData']),
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                if (log['newData'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'New Data:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _formatMap(log['newData']),
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMap(dynamic data) {
    if (data == null) return 'null';
    if (data is! Map) return data.toString();
    
    return data.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }
}

