import 'dart:async';
import 'package:flutter/foundation.dart';
import 'base_service.dart';

/// Performance metrics data class
class PerformanceMetrics {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetrics({
    required this.operation,
    required this.duration,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Performance monitoring and optimization service
class PerformanceService extends BaseService {
  static final PerformanceService _instance = PerformanceService._internal();
  PerformanceService._internal();
  factory PerformanceService() => _instance;

  // Performance tracking
  final Map<String, Stopwatch> _activeOperations = {};
  final List<PerformanceMetrics> _metrics = [];
  final Map<String, List<Duration>> _operationHistory = {};

  // Performance thresholds
  static const Duration slowOperationThreshold = Duration(milliseconds: 500);
  static const Duration verySlowOperationThreshold = Duration(seconds: 2);

  // Performance monitoring settings
  bool _isEnabled = true;
  int _maxMetricsHistory = 1000;
  Duration _cleanupInterval = const Duration(minutes: 5);

  Timer? _cleanupTimer;

  /// Initialize the performance service
  void initialize() {
    if (_cleanupTimer != null) return;

    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) => _cleanupOldMetrics());
    debugPrint('Performance monitoring initialized');
  }

  /// Start tracking an operation
  String startOperation(String operationName, [Map<String, dynamic> metadata = const {}]) {
    if (!_isEnabled) return '';

    final operationId = '${operationName}_${DateTime.now().millisecondsSinceEpoch}';
    final stopwatch = Stopwatch()..start();

    _activeOperations[operationId] = stopwatch;

    if (kDebugMode) {
      debugPrint('🚀 Started operation: $operationName (ID: $operationId)');
    }

    return operationId;
  }

  /// End tracking an operation
  void endOperation(String operationId, [Map<String, dynamic> metadata = const {}]) {
    if (!_isEnabled) return;

    final stopwatch = _activeOperations.remove(operationId);
    if (stopwatch == null) {
      debugPrint('⚠️ Operation not found: $operationId');
      return;
    }

    stopwatch.stop();
    final duration = stopwatch.elapsed;

    // Extract operation name from ID
    final operationName = operationId.split('_').first;
    final timestamp = DateTime.now();

    // Store metrics
    final metrics = PerformanceMetrics(
      operation: operationName,
      duration: duration,
      timestamp: timestamp,
      metadata: metadata,
    );

    _metrics.add(metrics);

    // Store in operation history
    _operationHistory.putIfAbsent(operationName, () => []).add(duration);

    // Trim history if needed
    if (_metrics.length > _maxMetricsHistory) {
      _metrics.removeAt(0);
    }

    // Keep only last 100 operations per type
    if (_operationHistory[operationName]!.length > 100) {
      _operationHistory[operationName]!.removeAt(0);
    }

    // Log performance warnings
    if (duration > verySlowOperationThreshold) {
      debugPrint('🐌 VERY SLOW operation: $operationName took ${duration.inMilliseconds}ms');
    } else if (duration > slowOperationThreshold) {
      debugPrint('🐌 Slow operation: $operationName took ${duration.inMilliseconds}ms');
    } else if (kDebugMode) {
      debugPrint('✅ Operation completed: $operationName in ${duration.inMilliseconds}ms');
    }

    // Check for performance degradation
    _checkPerformanceDegradation(operationName, duration);
  }

  /// Track an async operation with automatic timing
  Future<T> trackAsyncOperation<T>(
    String operationName,
    Future<T> Function() operation, [
    Map<String, dynamic> metadata = const {},
  ]) async {
    final operationId = startOperation(operationName, metadata);

    try {
      final result = await operation();
      endOperation(operationId, {'success': true, ...metadata});
      return result;
    } catch (e) {
      endOperation(operationId, {'success': false, 'error': e.toString(), ...metadata});
      rethrow;
    }
  }

  /// Track a sync operation with automatic timing
  T trackSyncOperation<T>(
    String operationName,
    T Function() operation, [
    Map<String, dynamic> metadata = const {},
  ]) {
    final operationId = startOperation(operationName, metadata);

    try {
      final result = operation();
      endOperation(operationId, {'success': true, ...metadata});
      return result;
    } catch (e) {
      endOperation(operationId, {'success': false, 'error': e.toString(), ...metadata});
      rethrow;
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    final totalOperations = _metrics.length;

    if (totalOperations == 0) {
      return {'total_operations': 0, 'message': 'No performance data available'};
    }

    // Calculate overall statistics
    final totalDuration = _metrics.fold<Duration>(
      Duration.zero,
      (sum, metric) => sum + metric.duration,
    );

    stats['total_operations'] = totalOperations;
    stats['total_duration_ms'] = totalDuration.inMilliseconds;
    stats['average_duration_ms'] = totalDuration.inMilliseconds / totalOperations;

    // Calculate operation-specific statistics
    final operationStats = <String, Map<String, dynamic>>{};
    final operationCounts = <String, int>{};

    for (final metric in _metrics) {
      operationCounts[metric.operation] = (operationCounts[metric.operation] ?? 0) + 1;
    }

    for (final operation in operationCounts.keys) {
      final operationMetrics = _metrics.where((m) => m.operation == operation).toList();
      final avgDuration = operationMetrics.fold<Duration>(
        Duration.zero,
        (sum, m) => sum + m.duration,
      ).inMilliseconds / operationMetrics.length;

      final maxDuration = operationMetrics
          .map((m) => m.duration.inMilliseconds)
          .reduce((a, b) => a > b ? a : b);

      final slowOperations = operationMetrics
          .where((m) => m.duration > slowOperationThreshold)
          .length;

      operationStats[operation] = {
        'count': operationCounts[operation],
        'average_duration_ms': avgDuration,
        'max_duration_ms': maxDuration,
        'slow_operations': slowOperations,
        'slow_percentage': (slowOperations / operationCounts[operation]! * 100).round(),
      };
    }

    stats['operations'] = operationStats;

    // Identify performance bottlenecks
    final bottlenecks = operationStats.entries
        .where((entry) => entry.value['slow_percentage'] > 20)
        .map((entry) => {
          'operation': entry.key,
          'slow_percentage': entry.value['slow_percentage'],
          'average_duration_ms': entry.value['average_duration_ms'],
        })
        .toList();

    stats['bottlenecks'] = bottlenecks;

    return stats;
  }

  /// Get recent metrics
  List<PerformanceMetrics> getRecentMetrics([int limit = 50]) {
    if (_metrics.length <= limit) return List.from(_metrics);

    return _metrics.sublist(_metrics.length - limit);
  }

  /// Clear all performance data
  void clearMetrics() {
    _activeOperations.clear();
    _metrics.clear();
    _operationHistory.clear();
    debugPrint('Performance metrics cleared');
  }

  /// Enable or disable performance monitoring
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    debugPrint('Performance monitoring ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check for performance degradation
  void _checkPerformanceDegradation(String operationName, Duration currentDuration) {
    final history = _operationHistory[operationName];
    if (history == null || history.length < 10) return;

    // Calculate recent average (last 5 operations)
    final recent = history.length >= 5 ? history.sublist(history.length - 5) : history;
    final recentAverage = recent.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    ).inMilliseconds / recent.length;

    // Calculate overall average
    final overallAverage = history.fold<Duration>(
      Duration.zero,
      (sum, duration) => sum + duration,
    ).inMilliseconds / history.length;

    // Check for significant degradation (50% slower than average)
    if (currentDuration.inMilliseconds > overallAverage * 1.5) {
      debugPrint('⚠️ Performance degradation detected in $operationName:');
      debugPrint('   Current: ${currentDuration.inMilliseconds}ms');
      debugPrint('   Recent avg: ${recentAverage.round()}ms');
      debugPrint('   Overall avg: ${overallAverage.round()}ms');
    }
  }

  /// Clean up old metrics to prevent memory leaks
  void _cleanupOldMetrics() {
    if (!_isEnabled) return;

    final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));

    // Remove old metrics
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));

    // Trim operation history
    _operationHistory.forEach((key, durations) {
      if (durations.length > 50) {
        _operationHistory[key] = durations.sublist(durations.length - 50);
      }
    });

    if (kDebugMode && _metrics.isNotEmpty) {
      debugPrint('🧹 Cleaned up old performance metrics. Remaining: ${_metrics.length}');
    }
  }

  /// Get memory usage information (approximate)
  Map<String, dynamic> getMemoryInfo() {
    return {
      'active_operations': _activeOperations.length,
      'metrics_count': _metrics.length,
      'operation_types': _operationHistory.length,
      'total_operations_tracked': _operationHistory.values
          .fold<int>(0, (sum, list) => sum + list.length),
    };
  }

  /// Export performance data for analysis
  List<Map<String, dynamic>> exportMetrics() {
    return _metrics.map((metric) => metric.toJson()).toList();
  }

  /// Dispose of the service
  void dispose() {
    _cleanupTimer?.cancel();
    clearMetrics();
    debugPrint('Performance service disposed');
  }
}

/// Convenience extension for tracking operations
extension PerformanceTracking on Object {
  static final PerformanceService _performance = PerformanceService();

  Future<T> trackAsync<T>(String operationName, Future<T> Function() operation) {
    return _performance.trackAsyncOperation(operationName, operation);
  }

  T trackSync<T>(String operationName, T Function() operation) {
    return _performance.trackSyncOperation(operationName, operation);
  }
}
