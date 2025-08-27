import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gamekeep/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Flow Integration Tests', () {
    testWidgets('Complete game addition flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test authentication flow
      // Note: In real tests, you'd need to mock Firebase Auth
      
      // Expect to see login screen
      expect(find.text('Sign In'), findsOneWidget);
      
      // Tap on email sign in
      await tester.tap(find.text('Sign in with Email'));
      await tester.pumpAndSettle();
      
      // Enter credentials (mocked)
      await tester.enterText(
        find.byType(TextField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );
      
      // Submit
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();
      
      // Should now be on home/library screen
      expect(find.text('GameKeep'), findsOneWidget);
      
      // Test adding a game via camera
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();
      
      // Camera screen should open
      expect(find.text('Capture Game'), findsOneWidget);
      
      // Tap gallery option
      await tester.tap(find.byIcon(Icons.photo_library));
      await tester.pumpAndSettle();
      
      // Would select an image (mocked in test)
      // Processing would happen
      
      // Expect confirmation screen for medium confidence
      expect(find.text('Confirm Game Details'), findsOneWidget);
      
      // Verify and save
      await tester.tap(find.text('Add to Library'));
      await tester.pumpAndSettle();
      
      // Should return to library with success message
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Added'), findsOneWidget);
    });

    testWidgets('Search and filter functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Assume logged in (would mock in real test)
      
      // Enter search query
      await tester.enterText(
        find.byType(TextField).first,
        'Catan',
      );
      await tester.pumpAndSettle();
      
      // Results should filter
      expect(find.text('Catan'), findsWidgets);
      
      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      
      // Test filter chips
      await tester.tap(find.text('Available'));
      await tester.pumpAndSettle();
      
      // Only available games should show
      // (Would verify with actual game data in real test)
      
      // Test sort options
      await tester.tap(find.byType(DropdownButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recent').last);
      await tester.pumpAndSettle();
      
      // Games should be sorted by date
      // (Would verify order in real test)
    });

    testWidgets('BGG import flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to profile/settings
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Find BGG import option
      await tester.tap(find.text('Import from BGG'));
      await tester.pumpAndSettle();
      
      // Enter BGG username
      await tester.enterText(
        find.byType(TextField).first,
        'testuser',
      );
      
      // Start import
      await tester.tap(find.text('Import Collection'));
      await tester.pumpAndSettle();
      
      // Should show progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Wait for completion (mocked)
      await tester.pump(const Duration(seconds: 3));
      
      // Should show success message
      expect(find.textContaining('imported'), findsOneWidget);
    });

    testWidgets('Game detail view and actions', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Tap on a game card
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
      
      // Should show game details
      expect(find.text('Details'), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget); // Player count
      expect(find.byIcon(Icons.timer), findsOneWidget); // Play time
      
      // Test action buttons
      expect(find.text('Log Play'), findsOneWidget);
      expect(find.text('Loan Game'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      
      // Test log play
      await tester.tap(find.text('Log Play'));
      await tester.pumpAndSettle();
      
      // Should open play logging dialog
      expect(find.text('Log a Play'), findsOneWidget);
      
      // Add players
      await tester.tap(find.text('Add Player'));
      await tester.enterText(
        find.byType(TextField).last,
        'Player 1',
      );
      
      // Save play
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      
      // Should show success
      expect(find.text('Play logged successfully'), findsOneWidget);
    });

    testWidgets('Offline functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Simulate offline mode
      // (Would need network mocking in real test)
      
      // Should still be able to browse library
      expect(find.byType(GridView), findsOneWidget);
      
      // Should be able to search locally
      await tester.enterText(
        find.byType(TextField).first,
        'Pandemic',
      );
      await tester.pumpAndSettle();
      
      // Offline indicator should show
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      
      // Try to add a game
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Should queue for sync
      expect(find.text('Will sync when online'), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('Handles camera permission denial', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Try to access camera without permission
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();
      
      // Should show permission request
      expect(find.text('Camera permission is required'), findsOneWidget);
    });

    testWidgets('Handles invalid BGG username', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Navigate to BGG import
      await tester.tap(find.byIcon(Icons.download));
      await tester.pumpAndSettle();
      
      // Enter invalid username
      await tester.enterText(
        find.byType(TextField).first,
        'invalid_user_12345',
      );
      
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      
      // Should show error
      expect(find.text('User not found'), findsOneWidget);
    });

    testWidgets('Handles network errors gracefully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Simulate network error during game fetch
      // (Would mock in real test)
      
      // Should show retry option
      expect(find.text('Retry'), findsOneWidget);
      
      // Tap retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      
      // Should attempt to reload
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}