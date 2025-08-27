import 'package:dio/dio.dart';
import 'package:xml/xml.dart' as xml;
import '../models/game_model.dart';
import 'ocr_service.dart';

class BGGService {
  static const String baseUrl = 'https://boardgamegeek.com/xmlapi2';
  static const String baseUrlV1 = 'https://boardgamegeek.com/xmlapi';
  final Dio _dio = Dio();

  // Rate limiting: 2 requests per second
  DateTime _lastRequestTime = DateTime.now();
  static const Duration _minRequestInterval = Duration(milliseconds: 500);

  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastRequestTime);
    if (timeSinceLastRequest < _minRequestInterval) {
      await Future.delayed(_minRequestInterval - timeSinceLastRequest);
    }
    _lastRequestTime = DateTime.now();
  }

  Future<List<BGGGameMatch>> searchGames(String query, {String? publisher}) async {
    if (query.isEmpty) return [];

    await _enforceRateLimit();

    try {
      // Search using BGG API
      final response = await _dio.get(
        '$baseUrl/search',
        queryParameters: {
          'query': query,
          'type': 'boardgame',
        },
      );

      final document = xml.XmlDocument.parse(response.data);
      final items = document.findAllElements('item');

      List<BGGGameMatch> matches = [];
      for (var item in items) {
        final id = int.tryParse(item.getAttribute('id') ?? '0') ?? 0;
        final name = item.findElements('name').firstOrNull?.getAttribute('value') ?? '';
        final yearStr = item.findElements('yearpublished').firstOrNull?.getAttribute('value');
        final year = int.tryParse(yearStr ?? '0') ?? 0;

        // Calculate match confidence
        double confidence = _calculateMatchConfidence(
          query: query,
          matchTitle: name,
          publisher: publisher,
          year: year,
        );

        matches.add(BGGGameMatch(
          bggId: id,
          title: name,
          year: year,
          matchConfidence: confidence,
        ));
      }

      // Sort by confidence
      matches.sort((a, b) => b.matchConfidence.compareTo(a.matchConfidence));

      // Get additional details for top matches
      if (matches.isNotEmpty) {
        final topMatches = matches.take(3).toList();
        await _enrichGameDetails(topMatches);
      }

      return matches.take(5).toList();
    } catch (e) {
      print('Error searching BGG: $e');
      return [];
    }
  }

  Future<void> _enrichGameDetails(List<BGGGameMatch> games) async {
    for (var game in games) {
      try {
        await _enforceRateLimit();
        final details = await getGameDetails(game.bggId);
        if (details != null) {
          game.thumbnailUrl = details['thumbnail'];
          game.publisher = details['publisher'];
        }
      } catch (e) {
        print('Error enriching game ${game.bggId}: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getGameDetails(int bggId) async {
    await _enforceRateLimit();

    try {
      final response = await _dio.get(
        '$baseUrl/thing',
        queryParameters: {
          'id': bggId,
          'stats': 1,
        },
      );

      final document = xml.XmlDocument.parse(response.data);
      final item = document.findAllElements('item').firstOrNull;

      if (item == null) return null;

      return {
        'bggId': bggId,
        'title': item.findElements('name').where((e) => e.getAttribute('type') == 'primary').firstOrNull?.getAttribute('value') ?? '',
        'publisher': item.findElements('link').where((e) => e.getAttribute('type') == 'boardgamepublisher').firstOrNull?.getAttribute('value') ?? '',
        'year': int.tryParse(item.findElements('yearpublished').firstOrNull?.getAttribute('value') ?? '0') ?? 0,
        'minPlayers': int.tryParse(item.findElements('minplayers').firstOrNull?.getAttribute('value') ?? '1') ?? 1,
        'maxPlayers': int.tryParse(item.findElements('maxplayers').firstOrNull?.getAttribute('value') ?? '4') ?? 4,
        'playTime': int.tryParse(item.findElements('playingtime').firstOrNull?.getAttribute('value') ?? '0') ?? 0,
        'weight': double.tryParse(item.findElements('statistics').firstOrNull?.findElements('ratings').firstOrNull?.findElements('averageweight').firstOrNull?.getAttribute('value') ?? '0') ?? 0,
        'rank': int.tryParse(item.findElements('statistics').firstOrNull?.findElements('ratings').firstOrNull?.findElements('ranks').firstOrNull?.findElements('rank').where((e) => e.getAttribute('name') == 'boardgame').firstOrNull?.getAttribute('value') ?? '0') ?? 0,
        'thumbnail': item.findElements('thumbnail').firstOrNull?.innerText ?? '',
        'image': item.findElements('image').firstOrNull?.innerText ?? '',
        'description': item.findElements('description').firstOrNull?.innerText ?? '',
        'designers': item.findElements('link').where((e) => e.getAttribute('type') == 'boardgamedesigner').map((e) => e.getAttribute('value') ?? '').toList(),
        'mechanics': item.findElements('link').where((e) => e.getAttribute('type') == 'boardgamemechanic').map((e) => e.getAttribute('value') ?? '').toList(),
        'categories': item.findElements('link').where((e) => e.getAttribute('type') == 'boardgamecategory').map((e) => e.getAttribute('value') ?? '').toList(),
      };
    } catch (e) {
      print('Error getting game details from BGG: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getUserCollection(String username) async {
    if (username.isEmpty) return [];

    await _enforceRateLimit();

    try {
      final response = await _dio.get(
        '$baseUrl/collection',
        queryParameters: {
          'username': username,
          'stats': 1,
          'own': 1,
        },
      );

      final document = xml.XmlDocument.parse(response.data);
      
      // Check if collection is still processing
      if (document.findAllElements('message').isNotEmpty) {
        // Wait and retry once
        await Future.delayed(Duration(seconds: 3));
        return getUserCollection(username);
      }

      final items = document.findAllElements('item');
      List<Map<String, dynamic>> collection = [];

      for (var item in items) {
        collection.add({
          'bggId': int.tryParse(item.getAttribute('objectid') ?? '0') ?? 0,
          'title': item.findElements('name').firstOrNull?.innerText ?? '',
          'yearPublished': int.tryParse(item.findElements('yearpublished').firstOrNull?.innerText ?? '0') ?? 0,
          'image': item.findElements('image').firstOrNull?.innerText ?? '',
          'thumbnail': item.findElements('thumbnail').firstOrNull?.innerText ?? '',
          'userRating': double.tryParse(item.findElements('stats').firstOrNull?.findElements('rating').firstOrNull?.getAttribute('value') ?? '0') ?? 0,
          'numPlays': int.tryParse(item.findElements('numplays').firstOrNull?.innerText ?? '0') ?? 0,
        });
      }

      return collection;
    } catch (e) {
      print('Error getting user collection from BGG: $e');
      return [];
    }
  }

  double _calculateMatchConfidence({
    required String query,
    required String matchTitle,
    String? publisher,
    int? year,
  }) {
    double confidence = 0;

    // Title similarity (using simple ratio for now, could use Levenshtein distance)
    final queryLower = query.toLowerCase();
    final matchLower = matchTitle.toLowerCase();

    if (queryLower == matchLower) {
      confidence = 1.0;
    } else if (matchLower.contains(queryLower) || queryLower.contains(matchLower)) {
      confidence = 0.8;
    } else {
      // Calculate word overlap
      final queryWords = queryLower.split(' ').where((w) => w.length > 2).toSet();
      final matchWords = matchLower.split(' ').where((w) => w.length > 2).toSet();
      final intersection = queryWords.intersection(matchWords);
      
      if (queryWords.isNotEmpty) {
        confidence = intersection.length / queryWords.length * 0.7;
      }
    }

    // Boost confidence if publisher matches
    if (publisher != null && publisher.isNotEmpty) {
      confidence += 0.1;
    }

    // Slight boost for recent games
    if (year != null && year > 2015) {
      confidence += 0.05;
    }

    return confidence.clamp(0.0, 1.0);
  }
}

/// Represents a game match result from BGG search
class BGGGameMatch {
  final int bggId;
  final String title;
  final int year;
  final double matchConfidence;
  String? publisher;
  String? thumbnailUrl;

  BGGGameMatch({
    required this.bggId,
    required this.title,
    required this.year,
    required this.matchConfidence,
    this.publisher,
    this.thumbnailUrl,
  });
}