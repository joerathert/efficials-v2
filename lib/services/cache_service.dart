import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'base_service.dart';

/// Cache entry with expiration time
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry(this.data, this.timestamp, this.ttl);

  bool get isExpired => DateTime.now().difference(timestamp) > ttl;

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl.inSeconds,
    };
  }

  static CacheEntry<T> fromJson<T>(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return CacheEntry<T>(
      fromJson(json['data']),
      DateTime.parse(json['timestamp']),
      Duration(seconds: json['ttl']),
    );
  }
}

/// Comprehensive caching service for frequently accessed data
class CacheService extends BaseService {
  static final CacheService _instance = CacheService._internal();
  CacheService._internal();
  factory CacheService() => _instance;

  static const String _cachePrefix = 'efficials_cache_';

  // Cache keys
  static const String gamesKey = '${_cachePrefix}games';
  static const String officialsKey = '${_cachePrefix}officials';
  static const String locationsKey = '${_cachePrefix}locations';
  static const String userProfileKey = '${_cachePrefix}user_profile';
  static const String sportIconsKey = '${_cachePrefix}sport_icons';

  // Default TTL values
  static const Duration shortTtl = Duration(minutes: 5);
  static const Duration mediumTtl = Duration(minutes: 15);
  static const Duration longTtl = Duration(hours: 1);
  static const Duration veryLongTtl = Duration(hours: 24);

  SharedPreferences? _prefs;
  final Map<String, CacheEntry> _memoryCache = {};

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    debugPrint('CacheService initialized');
  }

  /// Get data from cache (memory first, then persistent storage)
  Future<T?> get<T>(String key, T Function(dynamic) fromJson) async {
    try {
      // Check memory cache first
      final memoryEntry = _memoryCache[key];
      if (memoryEntry != null && !memoryEntry.isExpired) {
        debugPrint('Cache hit (memory): $key');
        return memoryEntry.data as T;
      }

      // Check persistent storage
      if (_prefs != null) {
        final cachedJson = _prefs!.getString(key);
        if (cachedJson != null) {
          final entry = CacheEntry.fromJson(jsonDecode(cachedJson), fromJson);
          if (!entry.isExpired) {
            // Update memory cache
            _memoryCache[key] = entry;
            debugPrint('Cache hit (persistent): $key');
            return entry.data;
          } else {
            // Remove expired entry
            await _remove(key);
          }
        }
      }

      debugPrint('Cache miss: $key');
      return null;
    } catch (e) {
      debugPrint('Cache error getting $key: $e');
      return null;
    }
  }

  /// Store data in cache
  Future<void> set<T>(String key, T data, {
    Duration ttl = mediumTtl,
    dynamic Function(T)? toJson,
  }) async {
    try {
      final entry = CacheEntry<T>(data, DateTime.now(), ttl);

      // Store in memory cache
      _memoryCache[key] = entry;

      // Store in persistent storage
      if (_prefs != null && toJson != null) {
        final jsonData = entry.toJson();
        jsonData['data'] = toJson(data);
        await _prefs!.setString(key, jsonEncode(jsonData));
      }

      debugPrint('Cache set: $key (TTL: ${ttl.inMinutes}min)');
    } catch (e) {
      debugPrint('Cache error setting $key: $e');
    }
  }

  /// Remove data from cache
  Future<void> remove(String key) async {
    await _remove(key);
  }

  Future<void> _remove(String key) async {
    _memoryCache.remove(key);
    if (_prefs != null) {
      await _prefs!.remove(key);
    }
    debugPrint('Cache removed: $key');
  }

  /// Clear all cache data
  Future<void> clear() async {
    _memoryCache.clear();
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((key) => key.startsWith(_cachePrefix));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
    debugPrint('Cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'memory_entries': _memoryCache.length,
      'persistent_entries': _prefs?.getKeys()
          .where((key) => key.startsWith(_cachePrefix))
          .length ?? 0,
      'memory_cache_keys': _memoryCache.keys.toList(),
    };
  }

  /// Clean up expired entries
  Future<void> cleanup() async {
    try {
      // Clean memory cache
      _memoryCache.removeWhere((key, entry) => entry.isExpired);

      // Clean persistent storage
      if (_prefs != null) {
        final keys = _prefs!.getKeys().where((key) => key.startsWith(_cachePrefix));
        for (final key in keys) {
          final cachedJson = _prefs!.getString(key);
          if (cachedJson != null) {
            final jsonData = jsonDecode(cachedJson);
            final timestamp = DateTime.parse(jsonData['timestamp']);
            final ttlSeconds = jsonData['ttl'] as int;
            final ttl = Duration(seconds: ttlSeconds);

            if (DateTime.now().difference(timestamp) > ttl) {
              await _prefs!.remove(key);
            }
          }
        }
      }

      debugPrint('Cache cleanup completed');
    } catch (e) {
      debugPrint('Cache cleanup error: $e');
    }
  }

  // Specialized caching methods for common data types

  /// Cache games data
  Future<void> cacheGames(List<Map<String, dynamic>> games) async {
    await set(
      gamesKey,
      games,
      ttl: mediumTtl,
      toJson: (data) => data,
    );
  }

  /// Get cached games data
  Future<List<Map<String, dynamic>>?> getCachedGames() async {
    return get(gamesKey, (data) => List<Map<String, dynamic>>.from(data));
  }

  /// Cache officials data
  Future<void> cacheOfficials(List<Map<String, dynamic>> officials) async {
    await set(
      officialsKey,
      officials,
      ttl: longTtl,
      toJson: (data) => data,
    );
  }

  /// Get cached officials data
  Future<List<Map<String, dynamic>>?> getCachedOfficials() async {
    return get(officialsKey, (data) => List<Map<String, dynamic>>.from(data));
  }

  /// Cache locations data
  Future<void> cacheLocations(List<Map<String, dynamic>> locations) async {
    await set(
      locationsKey,
      locations,
      ttl: veryLongTtl, // Locations don't change often
      toJson: (data) => data,
    );
  }

  /// Get cached locations data
  Future<List<Map<String, dynamic>>?> getCachedLocations() async {
    return get(locationsKey, (data) => List<Map<String, dynamic>>.from(data));
  }

  /// Cache user profile
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    await set(
      userProfileKey,
      profile,
      ttl: shortTtl, // User profile might change more frequently
      toJson: (data) => data,
    );
  }

  /// Get cached user profile
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    return get(userProfileKey, (data) => Map<String, dynamic>.from(data));
  }

  /// Cache sport icons mapping
  Future<void> cacheSportIcons(Map<String, String> sportIcons) async {
    await set(
      sportIconsKey,
      sportIcons,
      ttl: veryLongTtl, // Sport icons are static
      toJson: (data) => data,
    );
  }

  /// Get cached sport icons
  Future<Map<String, String>?> getCachedSportIcons() async {
    return get(sportIconsKey, (data) => Map<String, String>.from(data));
  }
}
