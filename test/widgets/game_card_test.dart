import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamekeep/models/game_model.dart';
import 'package:gamekeep/widgets/game_card.dart';

void main() {
  group('GameCard Widget Tests', () {
    late GameModel testGame;

    setUp(() {
      testGame = GameModel(
        gameId: 'test123',
        ownerId: 'user123',
        title: 'Test Game',
        publisher: 'Test Publisher',
        year: 2020,
        designers: ['Test Designer'],
        minPlayers: 2,
        maxPlayers: 4,
        playTime: 60,
        weight: 2.5,
        mechanics: ['Strategy'],
        categories: ['Family'],
        tags: ['favorite'],
        coverImage: 'https://example.com/image.jpg',
        thumbnailImage: 'https://example.com/thumb.jpg',
        condition: GameCondition.good,
        location: 'Shelf A',
        visibility: GameVisibility.friends,
        importSource: ImportSource.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should display game title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: testGame,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Game'), findsOneWidget);
    });

    testWidgets('should display player count', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: testGame,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('2-4'), findsOneWidget);
    });

    testWidgets('should display play time', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: testGame,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('60'), findsOneWidget);
    });

    testWidgets('should show availability indicator', (WidgetTester tester) async {
      // Test available game
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: testGame,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Test unavailable game
      final loanedGame = testGame.copyWith(
        isAvailable: false,
        currentBorrowerId: 'friend123',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: loanedGame,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should handle tap events', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: testGame,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GameCard));
      expect(wasTapped, true);
    });

    testWidgets('should display BGG rank if available', (WidgetTester tester) async {
      final rankedGame = testGame.copyWith(
        bggRank: 42,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: rankedGame,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('#42'), findsOneWidget);
    });

    testWidgets('should show complexity indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: testGame,
              onTap: () {},
            ),
          ),
        ),
      );

      // Weight of 2.5 should show medium complexity
      expect(find.byIcon(Icons.psychology), findsWidgets);
    });

    testWidgets('should handle missing thumbnail gracefully', (WidgetTester tester) async {
      final gameWithoutImage = testGame.copyWith(
        thumbnailImage: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: gameWithoutImage,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show placeholder
      expect(find.byIcon(Icons.casino), findsOneWidget);
    });

    testWidgets('should display tags if present', (WidgetTester tester) async {
      final taggedGame = testGame.copyWith(
        tags: ['favorite', 'solo', 'house-rule'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameCard(
              game: taggedGame,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('favorite'), findsOneWidget);
    });
  });
}