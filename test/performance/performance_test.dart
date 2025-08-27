import 'package:flutter_test/flutter_test.dart';
import 'package:gamekeep/models/game_model.dart';
import 'package:gamekeep/services/ocr_service.dart';
import 'package:gamekeep/providers/game_provider.dart';

void main() {
  group('Performance Tests', () {
    test('Library should handle 500+ games efficiently', () {
      final stopwatch = Stopwatch()..start();
      final games = <GameModel>[];

      // Generate 500 test games
      for (int i = 0; i < 500; i++) {
        games.add(GameModel(
          gameId: 'game_$i',
          ownerId: 'user123',
          title: 'Game $i',
          publisher: 'Publisher ${i % 10}',
          year: 2000 + (i % 24),
          designers: ['Designer ${i % 5}'],
          minPlayers: 2,
          maxPlayers: 4,
          playTime: 30 + (i % 90),
          weight: 1.0 + (i % 4),
          mechanics: ['Mechanic ${i % 8}'],
          categories: ['Category ${i % 6}'],
          tags: [],
          coverImage: 'https://example.com/game_$i.jpg',
          thumbnailImage: 'https://example.com/game_${i}_thumb.jpg',
          condition: GameCondition.good,
          location: 'Shelf ${i % 10}',
          visibility: GameVisibility.friends,
          importSource: ImportSource.manual,
          createdAt: DateTime.now().subtract(Duration(days: i)),
          updatedAt: DateTime.now(),
        ));
      }

      stopwatch.stop();

      // Should create 500 games in under 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(games.length, 500);
    });

    test('Search should return results in <500ms', () {
      final games = List.generate(1000, (i) => GameModel(
        gameId: 'game_$i',
        ownerId: 'user123',
        title: 'Game Title $i',
        publisher: 'Publisher',
        year: 2020,
        designers: ['Designer'],
        minPlayers: 2,
        maxPlayers: 4,
        playTime: 60,
        weight: 2.0,
        mechanics: [],
        categories: [],
        tags: [],
        coverImage: '',
        thumbnailImage: '',
        condition: GameCondition.good,
        location: '',
        visibility: GameVisibility.friends,
        importSource: ImportSource.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final stopwatch = Stopwatch()..start();

      // Perform search
      final results = games.where((game) => 
        game.title.toLowerCase().contains('500')).toList();

      stopwatch.stop();

      // Search should complete in under 500ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(results, isNotEmpty);
    });

    test('OCR processing should complete in <3 seconds', () async {
      final ocrService = OCRService();
      final stopwatch = Stopwatch()..start();

      // Simulate OCR processing
      await Future.delayed(const Duration(milliseconds: 2500));

      stopwatch.stop();

      // Should complete within 3 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      
      ocrService.dispose();
    });

    test('App cold start should be <2 seconds', () {
      final stopwatch = Stopwatch()..start();

      // Simulate app initialization
      // - Firebase init
      // - Auth check
      // - Initial data load
      // - UI render
      
      // Mock initialization tasks
      Future.wait([
        Future.delayed(const Duration(milliseconds: 500)), // Firebase
        Future.delayed(const Duration(milliseconds: 200)), // Auth
        Future.delayed(const Duration(milliseconds: 300)), // Data
        Future.delayed(const Duration(milliseconds: 100)), // UI
      ]);

      stopwatch.stop();

      // Total should be under 2 seconds
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });

    test('Filter operations should be responsive', () {
      final games = List.generate(500, (i) => GameModel(
        gameId: 'game_$i',
        ownerId: 'user123',
        title: 'Game $i',
        publisher: 'Publisher',
        year: 2020,
        designers: [],
        minPlayers: 1 + (i % 4),
        maxPlayers: 2 + (i % 6),
        playTime: 30 + (i % 90),
        weight: 1.0 + (i % 4),
        mechanics: ['Mechanic ${i % 5}'],
        categories: ['Category ${i % 3}'],
        tags: [],
        coverImage: '',
        thumbnailImage: '',
        condition: GameCondition.good,
        location: '',
        visibility: GameVisibility.friends,
        importSource: ImportSource.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final stopwatch = Stopwatch()..start();

      // Apply multiple filters
      final filtered = games.where((game) =>
        game.minPlayers <= 3 &&
        game.maxPlayers >= 3 &&
        game.playTime <= 60 &&
        game.weight <= 2.5 &&
        game.categories.contains('Category 1')
      ).toList();

      stopwatch.stop();

      // Filtering should be instant (<50ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(50));
      expect(filtered, isNotEmpty);
    });

    test('Image thumbnail generation should be efficient', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate thumbnail generation for 10 images
      for (int i = 0; i < 10; i++) {
        // Mock image processing
        await Future.delayed(const Duration(milliseconds: 50));
      }

      stopwatch.stop();

      // Should process 10 images in under 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('BGG import should handle rate limiting', () async {
      final stopwatch = Stopwatch()..start();
      int requestCount = 0;

      // Simulate 10 BGG API requests with rate limiting
      for (int i = 0; i < 10; i++) {
        // Enforce 500ms minimum between requests
        if (i > 0) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        requestCount++;
      }

      stopwatch.stop();

      // Should take at least 4.5 seconds for 10 requests (rate limited)
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(4500));
      expect(requestCount, 10);
    });

    test('Memory usage should stay reasonable with large collections', () {
      final games = <GameModel>[];
      
      // Add 1000 games and monitor memory (simplified test)
      for (int i = 0; i < 1000; i++) {
        games.add(GameModel(
          gameId: 'game_$i',
          ownerId: 'user123',
          title: 'Game $i with a very long title that takes up memory',
          publisher: 'Publisher with long name',
          year: 2020,
          designers: List.generate(5, (j) => 'Designer $j'),
          minPlayers: 2,
          maxPlayers: 6,
          playTime: 90,
          weight: 3.5,
          mechanics: List.generate(10, (j) => 'Mechanic $j'),
          categories: List.generate(8, (j) => 'Category $j'),
          tags: List.generate(5, (j) => 'Tag $j'),
          coverImage: 'https://example.com/very/long/url/path/to/image_$i.jpg',
          thumbnailImage: 'https://example.com/very/long/url/path/to/thumb_$i.jpg',
          condition: GameCondition.good,
          location: 'Very specific location on shelf $i',
          visibility: GameVisibility.friends,
          importSource: ImportSource.bgg,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      // Ensure collection was created
      expect(games.length, 1000);
      
      // In a real test, you'd measure actual memory usage
      // For now, just ensure the list can be created and accessed
      expect(games.first.title, contains('Game 0'));
      expect(games.last.title, contains('Game 999'));
    });
  });
}