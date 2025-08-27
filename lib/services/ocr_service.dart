import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image/image.dart' as img;
import '../models/game_model.dart';
import 'bgg_service.dart';

class OCRResult {
  final String? title;
  final String? publisher;
  final List<String> extractedText;
  final double confidence;
  final List<BGGGameMatch> bggMatches;

  OCRResult({
    this.title,
    this.publisher,
    required this.extractedText,
    required this.confidence,
    required this.bggMatches,
  });
}

class OCRService {
  late final TextRecognizer _textRecognizer;
  late final BarcodeScanner _barcodeScanner;
  final BGGService _bggService = BGGService();

  OCRService() {
    _textRecognizer = TextRecognizer();
    _barcodeScanner = BarcodeScanner();
  }

  Future<OCRResult> processGameImage(String imagePath) async {
    try {
      // Start timer for performance tracking
      final startTime = DateTime.now();

      // Step 1: Preprocess image
      final processedImagePath = await _preprocessImage(imagePath);

      // Step 2: Extract text using ML Kit
      final extractedText = await _extractTextFromImage(processedImagePath);

      // Step 3: Parse game information from text
      final gameInfo = _parseGameDetails(extractedText);

      // Step 4: Search BGG for matches
      final bggMatches = await _bggService.searchGames(
        gameInfo['title'] ?? '',
        publisher: gameInfo['publisher'],
      );

      // Step 5: Calculate confidence
      final confidence = _calculateConfidence(
        extractedText,
        gameInfo,
        bggMatches,
      );

      // Track processing time
      final processingTime = DateTime.now().difference(startTime);
      print('OCR processing completed in ${processingTime.inSeconds} seconds');

      return OCRResult(
        title: gameInfo['title'],
        publisher: gameInfo['publisher'],
        extractedText: extractedText,
        confidence: confidence,
        bggMatches: bggMatches,
      );
    } catch (e) {
      print('Error processing game image: $e');
      return OCRResult(
        extractedText: [],
        confidence: 0,
        bggMatches: [],
      );
    }
  }

  Future<String> _preprocessImage(String imagePath) async {
    try {
      // Load image
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) return imagePath;

      // Auto-rotate based on EXIF data
      final oriented = img.bakeOrientation(image);

      // Enhance contrast for better OCR
      final enhanced = _enhanceImage(oriented);

      // Save processed image
      final processedPath = imagePath.replaceAll('.jpg', '_processed.jpg');
      File(processedPath).writeAsBytesSync(img.encodeJpg(enhanced));

      return processedPath;
    } catch (e) {
      print('Error preprocessing image: $e');
      return imagePath;
    }
  }

  img.Image _enhanceImage(img.Image image) {
    // Apply image enhancements for better OCR
    img.adjustColor(image, contrast: 1.2);
    img.normalize(image, min: 100, max: 255);
    return image;
  }

  Future<List<String>> _extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    List<String> extractedLines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        extractedLines.add(line.text);
      }
    }

    return extractedLines;
  }

  Map<String, String> _parseGameDetails(List<String> textLines) {
    Map<String, String> gameInfo = {};

    // Common patterns for game titles and publishers
    final titlePatterns = [
      RegExp(r'^[A-Z][A-Za-z0-9\s:&\-]+$'), // Title case line
      RegExp(r'^\s*([A-Z][^.!?]*)\s*$'), // Capital start, no sentence punctuation
    ];

    final publisherPatterns = [
      RegExp(r'(?:published by|from|by)\s+([A-Za-z\s&]+)', caseSensitive: false),
      RegExp(r'©\s*\d{4}\s+([A-Za-z\s&]+)'),
      RegExp(r'([A-Za-z\s&]+)\s+(?:Games|Gaming|Entertainment|Studios)', caseSensitive: false),
    ];

    // Try to identify title (usually the largest/most prominent text)
    for (String line in textLines) {
      if (gameInfo['title'] == null) {
        for (RegExp pattern in titlePatterns) {
          if (pattern.hasMatch(line) && line.length > 3) {
            gameInfo['title'] = line.trim();
            break;
          }
        }
      }

      // Try to identify publisher
      if (gameInfo['publisher'] == null) {
        for (RegExp pattern in publisherPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            gameInfo['publisher'] = match.group(1)?.trim() ?? '';
            break;
          }
        }
      }
    }

    // If no title found, use the first substantial line
    if (gameInfo['title'] == null && textLines.isNotEmpty) {
      gameInfo['title'] = textLines
          .firstWhere(
            (line) => line.length > 3 && !line.contains(RegExp(r'[©®™]')),
            orElse: () => textLines.first,
          )
          .trim();
    }

    return gameInfo;
  }

  double _calculateConfidence(
    List<String> extractedText,
    Map<String, String> gameInfo,
    List<BGGGameMatch> bggMatches,
  ) {
    double confidence = 0;

    // Base confidence from text extraction quality
    if (extractedText.isNotEmpty) confidence += 0.2;
    if (gameInfo['title'] != null) confidence += 0.3;
    if (gameInfo['publisher'] != null) confidence += 0.2;

    // BGG match confidence
    if (bggMatches.isNotEmpty) {
      confidence += 0.3 * bggMatches.first.matchConfidence;
    }

    return confidence.clamp(0.0, 1.0);
  }

  Future<String?> scanBarcode(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        return barcodes.first.rawValue;
      }
    } catch (e) {
      print('Error scanning barcode: $e');
    }
    return null;
  }

  void dispose() {
    _textRecognizer.close();
    _barcodeScanner.close();
  }
}