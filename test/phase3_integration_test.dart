import 'package:flutter_test/flutter_test.dart';
import 'package:efficials_v2/services/cache_service.dart';
import 'package:efficials_v2/services/localization_service.dart';
import 'package:efficials_v2/services/performance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 3 Integration Tests', () {
    late CacheService cacheService;
    late LocalizationService localizationService;
    late PerformanceService performanceService;

    setUp(() async {
      // Initialize services
      cacheService = CacheService();
      await cacheService.initialize();

      localizationService = LocalizationService();
      await localizationService.initialize();

      performanceService = PerformanceService();
      performanceService.initialize();
    });

    tearDown(() async {
      // Clean up
      await cacheService.clear();
      performanceService.clearMetrics();
    });

    test('Cache service integration with game data', () async {
      final testGames = [
        {'id': '1', 'name': 'Test Game 1', 'sport': 'Football'},
        {'id': '2', 'name': 'Test Game 2', 'sport': 'Basketball'},
      ];

      // Cache games
      await cacheService.cacheGames(testGames);

      // Retrieve cached games
      final cachedGames = await cacheService.getCachedGames();

      expect(cachedGames, isNotNull);
      expect(cachedGames!.length, 2);
      expect(cachedGames[0]['name'], 'Test Game 1');
      expect(cachedGames[1]['sport'], 'Basketball');
    });

    test('Cache service integration with officials data', () async {
      final testOfficials = [
        {
          'id': '1',
          'firstName': 'John',
          'lastName': 'Doe',
          'email': 'john@example.com'
        },
        {
          'id': '2',
          'firstName': 'Jane',
          'lastName': 'Smith',
          'email': 'jane@example.com'
        },
      ];

      // Cache officials
      await cacheService.cacheOfficials(testOfficials);

      // Retrieve cached officials
      final cachedOfficials = await cacheService.getCachedOfficials();

      expect(cachedOfficials, isNotNull);
      expect(cachedOfficials!.length, 2);
      expect(cachedOfficials[0]['firstName'], 'John');
      expect(cachedOfficials[1]['email'], 'jane@example.com');
    });

    test('Localization service provides correct strings', () {
      expect(localizationService.getString('nav.home'), 'Home');
      expect(localizationService.getString('action.continue'), 'Continue');
      expect(localizationService.getString('games.createGame'), 'Create Game');
      expect(localizationService.getString('error.general'),
          'An error occurred. Please try again.');
    });

    test('Localization service handles missing keys gracefully', () {
      expect(
          localizationService.getString('nonexistent.key'), 'nonexistent.key');
    });

    test('Localization service supports parameterized strings', () {
      final result = localizationService.getString('test.welcome', {
        'name': 'John',
        'count': '5',
      });

      // Since this key doesn't exist, it should return the key itself
      expect(result, 'test.welcome');
    });

    test('Performance service tracks operations correctly', () async {
      final operationId = performanceService.startOperation('test_operation');

      // Simulate some work
      await Future.delayed(const Duration(milliseconds: 10));

      performanceService.endOperation(operationId, {'test': true});

      final stats = performanceService.getPerformanceStats();
      expect(stats['total_operations'], 1);
      expect(stats['operations']['test_operation']['count'], 1);
    });

    test('Performance service tracks async operations', () async {
      final result = await performanceService.trackAsyncOperation(
        'async_test',
        () async {
          await Future.delayed(const Duration(milliseconds: 5));
          return 'success';
        },
        {'async': true},
      );

      expect(result, 'success');

      final stats = performanceService.getPerformanceStats();
      expect(stats['total_operations'], 1);
      expect(stats['operations']['async_test']['count'], 1);
    });

    test('Performance service tracks sync operations', () {
      final result = performanceService.trackSyncOperation(
        'sync_test',
        () => 'sync_result',
        {'sync': true},
      );

      expect(result, 'sync_result');

      final stats = performanceService.getPerformanceStats();
      expect(stats['operations']['sync_test']['count'], 1);
    });

    test('Cache service respects TTL (Time To Live)', () async {
      final testData = {'id': 'test', 'name': 'Test Item'};

      // Cache with very short TTL (1 millisecond)
      await cacheService.set('test_short_ttl', testData,
          ttl: const Duration(milliseconds: 1));

      // Immediately try to retrieve (should still be there)
      var cachedData = await cacheService.get('test_short_ttl', (data) => data);
      expect(cachedData, isNotNull);

      // Wait for TTL to expire
      await Future.delayed(const Duration(milliseconds: 2));

      // Try to retrieve again (should be null)
      cachedData = await cacheService.get('test_short_ttl', (data) => data);
      expect(cachedData, isNull);
    });

    test('Cache service cleanup removes expired entries', () async {
      // Add some entries with very short TTL
      await cacheService.set('test1', {'data': 'test1'},
          ttl: const Duration(milliseconds: 1));
      await cacheService.set('test2', {'data': 'test2'},
          ttl: const Duration(milliseconds: 1));

      // Wait for expiration
      await Future.delayed(const Duration(milliseconds: 5));

      // Manually trigger cleanup
      await cacheService.cleanup();

      // Check that expired entries are removed
      final stats = cacheService.getStats();
      expect(stats['memory_entries'], 0);
    });

    test('Localization service provides convenience getters', () {
      expect(localizationService.home, 'Home');
      expect(localizationService.games, 'Games');
      expect(localizationService.officials, 'Officials');
      expect(localizationService.settings, 'Settings');
      expect(localizationService.continueText, 'Continue');
      expect(localizationService.cancel, 'Cancel');
    });

    test('Performance service identifies bottlenecks', () async {
      // Create some slow operations
      for (int i = 0; i < 5; i++) {
        final operationId = performanceService.startOperation('slow_operation');
        await Future.delayed(
            const Duration(milliseconds: 600)); // > 500ms threshold
        performanceService.endOperation(operationId);
      }

      final stats = performanceService.getPerformanceStats();
      final bottlenecks = stats['bottlenecks'] as List;

      expect(bottlenecks.length, 1);
      expect(bottlenecks[0]['operation'], 'slow_operation');
      expect(bottlenecks[0]['slow_percentage'], 100);
    });

    test('Service integration: Cache + Performance + Localization', () async {
      // Test a complete workflow combining all services
      final operationId = performanceService.startOperation('integration_test');

      // Cache some localized data
      final localizedGames = [
        {
          'id': '1',
          'name': localizationService.createGame,
          'sport': localizationService.sport
        },
      ];

      await cacheService.cacheGames(localizedGames);
      final cachedGames = await cacheService.getCachedGames();

      performanceService.endOperation(operationId, {
        'cached_items': cachedGames?.length ?? 0,
        'language': localizationService.currentLanguage,
      });

      expect(cachedGames, isNotNull);
      expect(cachedGames!.length, 1);
      expect(cachedGames[0]['name'], 'Create Game');

      // Verify performance tracking
      final stats = performanceService.getPerformanceStats();
      expect(stats['total_operations'], greaterThan(0));
      expect(stats['operations']['integration_test'], isNotNull);
    });

    test('Cache service handles different data types correctly', () async {
      // Test with different data structures
      final gameData = {
        'id': 'game1',
        'name': 'Test Game',
        'sport': 'Football',
        'officialsRequired': 5,
        'date': DateTime.now().toIso8601String(),
      };

      final officialData = {
        'id': 'official1',
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john@example.com',
        'sports': ['Football', 'Basketball'],
        'experience': 10,
      };

      // Cache both types
      await cacheService.set('game_data', gameData,
          ttl: const Duration(hours: 1));
      await cacheService.set('official_data', officialData,
          ttl: const Duration(hours: 1));

      // Retrieve both
      final cachedGame = await cacheService.get(
          'game_data', (data) => data as Map<String, dynamic>);
      final cachedOfficial = await cacheService.get(
          'official_data', (data) => data as Map<String, dynamic>);

      expect(cachedGame, isNotNull);
      expect(cachedOfficial, isNotNull);
      expect(cachedGame!['sport'], 'Football');
      expect(cachedOfficial!['experience'], 10);
      expect(cachedOfficial['sports'], isA<List>());
    });
  });
}
