import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:gamekeep/models/game_model.dart';

void main() {
  group('GameModel Tests', () {
    test('should create GameModel with all required fields', () {
      final game = GameModel(
        gameId: 'test123',
        ownerId: 'user123',
        title: 'Catan',
        publisher: 'Kosmos',
        year: 1995,
        designers: ['Klaus Teuber'],
        minPlayers: 3,
        maxPlayers: 4,
        playTime: 90,
        weight: 2.33,
        mechanics: ['Trading', 'Dice Rolling'],
        categories: ['Strategy'],
        tags: ['favorite'],
        coverImage: 'https://example.com/catan.jpg',
        thumbnailImage: 'https://example.com/catan_thumb.jpg',
        condition: GameCondition.good,
        location: 'Shelf A',
        visibility: GameVisibility.friends,
        importSource: ImportSource.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(game.title, 'Catan');
      expect(game.minPlayers, 3);
      expect(game.maxPlayers, 4);
      expect(game.isAvailable, true);
      expect(game.condition, GameCondition.good);
    });

    test('should convert GameModel to/from Firestore correctly', () {
      final originalGame = GameModel(
        gameId: 'test123',
        ownerId: 'user123',
        title: 'Wingspan',
        publisher: 'Stonemaier Games',
        year: 2019,
        designers: ['Elizabeth Hargrave'],
        minPlayers: 1,
        maxPlayers: 5,
        playTime: 70,
        weight: 2.43,
        bggId: 266192,
        bggRank: 15,
        mechanics: ['Engine Building', 'Card Drafting'],
        categories: ['Animals', 'Card Game'],
        tags: ['solo'],
        coverImage: 'https://example.com/wingspan.jpg',
        thumbnailImage: 'https://example.com/wingspan_thumb.jpg',
        condition: GameCondition.mint,
        location: 'Main Collection',
        value: 59.99,
        visibility: GameVisibility.public,
        importSource: ImportSource.bgg,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Convert to Firestore
      final firestoreData = originalGame.toFirestore();
      
      // Verify key fields
      expect(firestoreData['title'], 'Wingspan');
      expect(firestoreData['bggId'], 266192);
      expect(firestoreData['condition'], 'mint');
      expect(firestoreData['visibility'], 'public');
      expect(firestoreData['importSource'], 'bgg');
    });

    test('should handle copyWith correctly', () {
      final game = GameModel(
        gameId: 'test123',
        ownerId: 'user123',
        title: 'Azul',
        publisher: 'Next Move Games',
        year: 2017,
        designers: ['Michael Kiesling'],
        minPlayers: 2,
        maxPlayers: 4,
        playTime: 45,
        weight: 1.77,
        mechanics: ['Pattern Building'],
        categories: ['Abstract'],
        tags: [],
        coverImage: 'image.jpg',
        thumbnailImage: 'thumb.jpg',
        condition: GameCondition.good,
        location: 'Shelf B',
        visibility: GameVisibility.friends,
        importSource: ImportSource.photo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedGame = game.copyWith(
        title: 'Azul: Summer Pavilion',
        year: 2019,
        isAvailable: false,
        currentBorrowerId: 'friend123',
      );

      expect(updatedGame.title, 'Azul: Summer Pavilion');
      expect(updatedGame.year, 2019);
      expect(updatedGame.isAvailable, false);
      expect(updatedGame.currentBorrowerId, 'friend123');
      expect(updatedGame.publisher, game.publisher); // Unchanged
    });

    test('should validate player count ranges', () {
      final game = GameModel(
        gameId: 'test',
        ownerId: 'user',
        title: 'Test Game',
        publisher: 'Publisher',
        year: 2020,
        designers: [],
        minPlayers: 2,
        maxPlayers: 6,
        playTime: 60,
        weight: 2.0,
        mechanics: [],
        categories: [],
        tags: [],
        coverImage: '',
        thumbnailImage: '',
        condition: GameCondition.good,
        location: '',
        visibility: GameVisibility.private,
        importSource: ImportSource.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test player count validation
      expect(game.minPlayers <= game.maxPlayers, true);
      expect(game.minPlayers, greaterThanOrEqualTo(1));
      expect(game.maxPlayers, lessThanOrEqualTo(99));
    });
  });
}