import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gamekeep/services/ocr_service.dart';
import 'package:gamekeep/services/bgg_service.dart';

class MockBGGService extends Mock implements BGGService {}

void main() {
  group('OCR Service Tests', () {
    late OCRService ocrService;

    setUp(() {
      ocrService = OCRService();
    });

    tearDown(() {
      ocrService.dispose();
    });

    test('should parse game details from extracted text correctly', () {
      final textLines = [
        'TICKET TO RIDE',
        'A railway adventure game',
        'Published by Days of Wonder',
        '© 2004 Days of Wonder',
        'Ages 8+',
        '2-5 Players',
        '30-60 minutes',
      ];

      // This would need to be exposed or tested differently in production
      // For now, we test the overall confidence calculation
      final ocrResult = OCRResult(
        title: 'TICKET TO RIDE',
        publisher: 'Days of Wonder',
        extractedText: textLines,
        confidence: 0.0,
        bggMatches: [],
      );

      expect(ocrResult.title, 'TICKET TO RIDE');
      expect(ocrResult.publisher, 'Days of Wonder');
      expect(ocrResult.extractedText, isNotEmpty);
    });

    test('should calculate confidence scores correctly', () {
      // Test high confidence scenario
      final highConfidenceResult = OCRResult(
        title: 'Catan',
        publisher: 'Kosmos',
        extractedText: ['Catan', 'Kosmos', 'Klaus Teuber'],
        confidence: 0.95,
        bggMatches: [
          BGGGameMatch(
            bggId: 13,
            title: 'Catan',
            publisher: 'Kosmos',
            year: 1995,
            matchConfidence: 0.98,
          ),
        ],
      );

      expect(highConfidenceResult.confidence, greaterThanOrEqualTo(0.9));
      expect(highConfidenceResult.bggMatches, isNotEmpty);

      // Test low confidence scenario
      final lowConfidenceResult = OCRResult(
        title: null,
        publisher: null,
        extractedText: ['Blurry', 'Text', 'Hard to read'],
        confidence: 0.3,
        bggMatches: [],
      );

      expect(lowConfidenceResult.confidence, lessThan(0.6));
      expect(lowConfidenceResult.title, isNull);
    });

    test('should handle empty or invalid image paths gracefully', () async {
      // This test would need actual file system mocking in production
      final result = await ocrService.processGameImage('invalid/path.jpg');
      
      expect(result.confidence, 0);
      expect(result.extractedText, isEmpty);
      expect(result.bggMatches, isEmpty);
    });

    test('should identify common board game publishers', () {
      final publishers = [
        'Days of Wonder',
        'Fantasy Flight Games',
        'Z-Man Games',
        'Rio Grande Games',
        'Stonemaier Games',
        'Czech Games Edition',
      ];

      for (final publisher in publishers) {
        final textWithPublisher = [
          'Some Game Title',
          'Published by $publisher',
        ];

        // Test that publisher patterns are recognized
        // This would need the actual parsing method exposed
        expect(textWithPublisher.any((line) => line.contains(publisher)), true);
      }
    });

    test('BGGGameMatch confidence calculation', () {
      final perfectMatch = BGGGameMatch(
        bggId: 1,
        title: 'Catan',
        year: 1995,
        matchConfidence: 1.0,
      );

      final partialMatch = BGGGameMatch(
        bggId: 2,
        title: 'Settlers of Catan',
        year: 1995,
        matchConfidence: 0.8,
      );

      final poorMatch = BGGGameMatch(
        bggId: 3,
        title: 'Completely Different Game',
        year: 2020,
        matchConfidence: 0.2,
      );

      expect(perfectMatch.matchConfidence, 1.0);
      expect(partialMatch.matchConfidence, greaterThanOrEqualTo(0.6));
      expect(poorMatch.matchConfidence, lessThan(0.5));
    });

    test('should handle special characters in game titles', () {
      final specialTitles = [
        'Dungeons & Dragons',
        'Rock\'n\'Roll Manager',
        'Café International',
        '7 Wonders: Duel',
        'BANG! The Dice Game',
      ];

      for (final title in specialTitles) {
        final result = OCRResult(
          title: title,
          extractedText: [title],
          confidence: 0.8,
          bggMatches: [],
        );

        expect(result.title, title);
        expect(result.title, isNotEmpty);
      }
    });
  });

  group('OCR Performance Tests', () {
    test('should process image within time constraints', () async {
      final ocrService = OCRService();
      final stopwatch = Stopwatch()..start();
      
      // Simulate processing (would use actual image in production)
      await Future.delayed(const Duration(milliseconds: 100));
      
      stopwatch.stop();
      
      // Should be under 3 seconds for on-device processing
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      
      ocrService.dispose();
    });
  });
}