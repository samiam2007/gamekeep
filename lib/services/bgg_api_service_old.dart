import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/game_model.dart';

class BGGApiService {
  static const String baseUrl = 'https://boardgamegeek.com/xmlapi2';
  static const String baseUrlV1 = 'https://boardgamegeek.com/xmlapi';
  
  // Rate limiting - BGG requests no more than 1 request per second
  static DateTime _lastRequestTime = DateTime.now();
  static const Duration _minRequestInterval = Duration(seconds: 1);

  // Ensure rate limiting
  static Future<void> _rateLimit() async {
    final now = DateTime.now();
    final timeSinceLastRequest = now.difference(_lastRequestTime);
    if (timeSinceLastRequest < _minRequestInterval) {
      await Future.delayed(_minRequestInterval - timeSinceLastRequest);
    }
    _lastRequestTime = DateTime.now();
  }

  // Get user's collection (owned, wishlist, want to play, etc.)
  static Future<BGGCollection> getUserCollection({
    required String username,
    bool? own,
    bool? wishlist,
    bool? wantToPlay,
    bool? wantToBuy,
    bool? preordered,
    bool? stats = true,
  }) async {
    await _rateLimit();
    
    final params = {
      'username': username,
      'stats': (stats ?? true) ? '1' : '0',
      if (own != null) 'own': own ? '1' : '0',
      if (wishlist != null) 'wishlist': wishlist ? '1' : '0',
      if (wantToPlay != null) 'wanttoplay': wantToPlay ? '1' : '0',
      if (wantToBuy != null) 'wanttobuy': wantToBuy ? '1' : '0',
      if (preordered != null) 'preordered': preordered ? '1' : '0',
    };

    final uri = Uri.parse('$baseUrl/collection').replace(queryParameters: params);
    
    try {
      final response = await http.get(uri);
      
      // BGG returns 202 when collection is being prepared
      if (response.statusCode == 202) {
        // Wait and retry
        await Future.delayed(const Duration(seconds: 5));
        return getUserCollection(
          username: username,
          own: own,
          wishlist: wishlist,
          wantToPlay: wantToPlay,
          wantToBuy: wantToBuy,
          preordered: preordered,
          stats: stats,
        );
      }
      
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        return BGGCollection.fromXml(document);
      } else {
        throw Exception('Failed to load collection: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching BGG collection: $e');
      rethrow;
    }
  }

  // Get detailed game information including images and stats
  static Future<BGGGameDetails?> getGameDetails({
    required int gameId,
    bool stats = true,
    bool videos = false,
    bool marketplace = false,
  }) async {
    await _rateLimit();
    
    final params = {
      'id': gameId.toString(),
      'stats': stats ? '1' : '0',
      'videos': videos ? '1' : '0',
      'marketplace': marketplace ? '1' : '0',
    };

    final uri = Uri.parse('$baseUrl/thing').replace(queryParameters: params);
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        
        if (items.isNotEmpty) {
          return BGGGameDetails.fromXml(items.first);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching game details: $e');
      return null;
    }
  }

  // Search for games
  static Future<List<BGGSearchResult>> searchGames({
    required String query,
    String? type = 'boardgame',
    bool exact = false,
  }) async {
    await _rateLimit();
    
    final params = {
      'query': query,
      if (type != null) 'type': type,
      if (exact) 'exact': '1',
    };

    final uri = Uri.parse('$baseUrl/search').replace(queryParameters: params);
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        
        return items.map((item) => BGGSearchResult.fromXml(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching BGG: $e');
      return [];
    }
  }

  // Get hot games list
  static Future<List<BGGHotItem>> getHotItems({String type = 'boardgame'}) async {
    await _rateLimit();
    
    final uri = Uri.parse('$baseUrl/hot').replace(queryParameters: {'type': type});
    
    try {
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        
        return items.map((item) => BGGHotItem.fromXml(item)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching hot items: $e');
      return [];
    }
  }

  // Get game recommendations based on user's collection
  static Future<List<BGGRecommendation>> getRecommendations({
    required List<int> ownedGameIds,
    int minRating = 7,
    int maxResults = 20,
  }) async {
    // This would typically use a more sophisticated algorithm
    // For now, we'll get games from similar categories/mechanics
    
    List<BGGRecommendation> recommendations = [];
    Set<String> userMechanics = {};
    Set<String> userCategories = {};
    
    // Analyze user's collection
    for (int gameId in ownedGameIds.take(10)) { // Limit to avoid too many API calls
      final details = await getGameDetails(gameId: gameId);
      if (details != null) {
        userMechanics.addAll(details.mechanics);
        userCategories.addAll(details.categories);
      }
    }
    
    // Get hot games and filter by similar mechanics/categories
    final hotGames = await getHotItems();
    
    for (final hotGame in hotGames.take(maxResults)) {
      if (!ownedGameIds.contains(hotGame.id)) {
        final details = await getGameDetails(gameId: hotGame.id);
        if (details != null && details.averageRating >= minRating) {
          // Calculate match score
          int matchScore = 0;
          for (final mechanic in details.mechanics) {
            if (userMechanics.contains(mechanic)) matchScore += 2;
          }
          for (final category in details.categories) {
            if (userCategories.contains(category)) matchScore += 1;
          }
          
          recommendations.add(BGGRecommendation(
            gameId: hotGame.id,
            name: hotGame.name,
            thumbnail: hotGame.thumbnail,
            rank: hotGame.rank,
            matchScore: matchScore,
            reason: matchScore > 5 
              ? 'Highly recommended based on your collection'
              : matchScore > 2 
                ? 'Similar to games you own'
                : 'Popular game you might enjoy',
          ));
        }
      }
    }
    
    // Sort by match score
    recommendations.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    
    return recommendations.take(maxResults).toList();
  }

  // Get hot/trending games
  static Future<List<BGGHotGame>> getHotGames() async {
    await _rateLimit();
    
    final url = Uri.parse('$baseUrl/hot');
    final params = {'type': 'boardgame'};
    final response = await http.get(url.replace(queryParameters: params));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to load hot games');
    }
    
    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    
    return items.map((item) => BGGHotGame.fromXml(item)).toList();
  }
  
  // Convert BGG game to our GameModel
  static GameModel convertToGameModel(BGGGameDetails bggGame, String userId) {
    return GameModel(
      gameId: 'bgg_${bggGame.id}',
      ownerId: userId,
      title: bggGame.primaryName,
      publisher: bggGame.publishers.isNotEmpty ? bggGame.publishers.first : 'Unknown',
      year: bggGame.yearPublished,
      designers: bggGame.designers,
      minPlayers: bggGame.minPlayers,
      maxPlayers: bggGame.maxPlayers,
      playTime: bggGame.playingTime,
      weight: bggGame.averageWeight,
      bggId: bggGame.id,
      bggRank: bggGame.rank,
      mechanics: bggGame.mechanics,
      categories: bggGame.categories,
      tags: [],
      coverImage: bggGame.image,
      thumbnailImage: bggGame.thumbnail,
      condition: GameCondition.good,
      location: 'Main Shelf',
      visibility: GameVisibility.public,
      importSource: ImportSource.bgg,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isAvailable: true,
      description: bggGame.description,
      minAge: bggGame.minAge,
    );
  }
}

// Data Models for BGG API responses

class BGGCollection {
  final int totalItems;
  final List<BGGCollectionItem> items;

  BGGCollection({required this.totalItems, required this.items});

  factory BGGCollection.fromXml(xml.XmlDocument document) {
    final root = document.rootElement;
    final totalItems = int.tryParse(root.getAttribute('totalitems') ?? '0') ?? 0;
    
    final items = root.findAllElements('item').map((item) {
      return BGGCollectionItem.fromXml(item);
    }).toList();

    return BGGCollection(totalItems: totalItems, items: items);
  }
}

class BGGCollectionItem {
  final int objectId;
  final String name;
  final int? yearPublished;
  final String? image;
  final String? thumbnail;
  final bool owned;
  final bool wishlist;
  final bool wantToPlay;
  final bool wantToBuy;
  final bool preordered;
  final int? numPlays;
  final double? rating;

  BGGCollectionItem({
    required this.objectId,
    required this.name,
    this.yearPublished,
    this.image,
    this.thumbnail,
    this.owned = false,
    this.wishlist = false,
    this.wantToPlay = false,
    this.wantToBuy = false,
    this.preordered = false,
    this.numPlays,
    this.rating,
  });

  factory BGGCollectionItem.fromXml(xml.XmlElement element) {
    final name = element.findElements('name').first.text;
    final yearPublished = int.tryParse(element.findElements('yearpublished').firstOrNull?.text ?? '');
    final image = element.findElements('image').firstOrNull?.text;
    final thumbnail = element.findElements('thumbnail').firstOrNull?.text;
    
    final status = element.findElements('status').firstOrNull;
    final stats = element.findElements('stats').firstOrNull;
    
    return BGGCollectionItem(
      objectId: int.parse(element.getAttribute('objectid')!),
      name: name,
      yearPublished: yearPublished,
      image: image,
      thumbnail: thumbnail,
      owned: status?.getAttribute('own') == '1',
      wishlist: (int.tryParse(status?.getAttribute('wishlist') ?? '0') ?? 0) > 0,
      wantToPlay: status?.getAttribute('wanttoplay') == '1',
      wantToBuy: status?.getAttribute('wanttobuy') == '1',
      preordered: status?.getAttribute('preordered') == '1',
      numPlays: int.tryParse(element.findElements('numplays').firstOrNull?.text ?? ''),
      rating: double.tryParse(stats?.findElements('rating')?.firstOrNull?.getAttribute('value') ?? ''),
    );
  }
}

class BGGGameDetails {
  final int id;
  final String primaryName;
  final List<String> alternateNames;
  final String description;
  final int yearPublished;
  final int minPlayers;
  final int maxPlayers;
  final int playingTime;
  final int minPlayTime;
  final int maxPlayTime;
  final String image;
  final String thumbnail;
  final List<String> publishers;
  final List<String> designers;
  final List<String> artists;
  final List<String> categories;
  final List<String> mechanics;
  final List<String> families;
  final List<String> expansions;
  final double averageRating;
  final double averageWeight;
  final int? rank;
  final int numOwned;
  final int numWant;
  final int numWish;
  final int? minAge;

  BGGGameDetails({
    required this.id,
    required this.primaryName,
    required this.alternateNames,
    required this.description,
    required this.yearPublished,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playingTime,
    required this.minPlayTime,
    required this.maxPlayTime,
    required this.image,
    required this.thumbnail,
    required this.publishers,
    required this.designers,
    required this.artists,
    required this.categories,
    required this.mechanics,
    required this.families,
    required this.expansions,
    required this.averageRating,
    required this.averageWeight,
    this.rank,
    required this.numOwned,
    required this.numWant,
    required this.numWish,
    this.minAge,
  });

  factory BGGGameDetails.fromXml(xml.XmlElement element) {
    // Parse names
    final names = element.findAllElements('name');
    String primaryName = '';
    List<String> alternateNames = [];
    
    for (final name in names) {
      if (name.getAttribute('type') == 'primary') {
        primaryName = name.getAttribute('value') ?? '';
      } else {
        alternateNames.add(name.getAttribute('value') ?? '');
      }
    }

    // Parse links
    final links = element.findAllElements('link');
    List<String> categories = [];
    List<String> mechanics = [];
    List<String> families = [];
    List<String> designers = [];
    List<String> artists = [];
    List<String> publishers = [];
    List<String> expansions = [];

    for (final link in links) {
      final type = link.getAttribute('type');
      final value = link.getAttribute('value') ?? '';
      
      switch (type) {
        case 'boardgamecategory':
          categories.add(value);
          break;
        case 'boardgamemechanic':
          mechanics.add(value);
          break;
        case 'boardgamefamily':
          families.add(value);
          break;
        case 'boardgamedesigner':
          designers.add(value);
          break;
        case 'boardgameartist':
          artists.add(value);
          break;
        case 'boardgamepublisher':
          publishers.add(value);
          break;
        case 'boardgameexpansion':
          expansions.add(value);
          break;
      }
    }

    // Parse statistics
    final statistics = element.findElements('statistics').firstOrNull;
    final ratings = statistics?.findElements('ratings').firstOrNull;
    
    // Parse ranks
    int? rank;
    final ranks = ratings?.findElements('ranks').firstOrNull?.findElements('rank');
    if (ranks != null) {
      for (final r in ranks) {
        if (r.getAttribute('name') == 'boardgame') {
          rank = int.tryParse(r.getAttribute('value') ?? '');
          break;
        }
      }
    }

    return BGGGameDetails(
      id: int.parse(element.getAttribute('id')!),
      primaryName: primaryName,
      alternateNames: alternateNames,
      description: element.findElements('description').firstOrNull?.text ?? '',
      yearPublished: int.tryParse(element.findElements('yearpublished').firstOrNull?.getAttribute('value') ?? '') ?? 0,
      minPlayers: int.tryParse(element.findElements('minplayers').firstOrNull?.getAttribute('value') ?? '') ?? 1,
      maxPlayers: int.tryParse(element.findElements('maxplayers').firstOrNull?.getAttribute('value') ?? '') ?? 4,
      playingTime: int.tryParse(element.findElements('playingtime').firstOrNull?.getAttribute('value') ?? '') ?? 60,
      minPlayTime: int.tryParse(element.findElements('minplaytime').firstOrNull?.getAttribute('value') ?? '') ?? 30,
      maxPlayTime: int.tryParse(element.findElements('maxplaytime').firstOrNull?.getAttribute('value') ?? '') ?? 120,
      image: element.findElements('image').firstOrNull?.text ?? '',
      thumbnail: element.findElements('thumbnail').firstOrNull?.text ?? '',
      publishers: publishers,
      designers: designers,
      artists: artists,
      categories: categories,
      mechanics: mechanics,
      families: families,
      expansions: expansions,
      averageRating: double.tryParse(ratings?.findElements('average').firstOrNull?.getAttribute('value') ?? '') ?? 0,
      averageWeight: double.tryParse(ratings?.findElements('averageweight').firstOrNull?.getAttribute('value') ?? '') ?? 0,
      rank: rank,
      numOwned: int.tryParse(ratings?.findElements('owned').firstOrNull?.getAttribute('value') ?? '') ?? 0,
      numWant: int.tryParse(ratings?.findElements('wanting').firstOrNull?.getAttribute('value') ?? '') ?? 0,
      numWish: int.tryParse(ratings?.findElements('wishing').firstOrNull?.getAttribute('value') ?? '') ?? 0,
      minAge: int.tryParse(element.findElements('minage').firstOrNull?.getAttribute('value') ?? ''),
    );
  }
}

class BGGSearchResult {
  final int id;
  final String name;
  final int? yearPublished;
  
  BGGSearchResult({
    required this.id,
    required this.name,
    this.yearPublished,
  });

  factory BGGSearchResult.fromXml(xml.XmlElement element) {
    return BGGSearchResult(
      id: int.parse(element.getAttribute('id')!),
      name: element.findElements('name').firstOrNull?.getAttribute('value') ?? '',
      yearPublished: int.tryParse(element.findElements('yearpublished')?.firstOrNull?.getAttribute('value') ?? ''),
    );
  }
}

class BGGHotItem {
  final int id;
  final int rank;
  final String name;
  final String? thumbnail;
  final int? yearPublished;

  BGGHotItem({
    required this.id,
    required this.rank,
    required this.name,
    this.thumbnail,
    this.yearPublished,
  });

  factory BGGHotItem.fromXml(xml.XmlElement element) {
    return BGGHotItem(
      id: int.parse(element.getAttribute('id')!),
      rank: int.parse(element.getAttribute('rank')!),
      name: element.findElements('name').first.getAttribute('value')!,
      thumbnail: element.findElements('thumbnail')?.firstOrNull?.getAttribute('value'),
      yearPublished: int.tryParse(element.findElements('yearpublished')?.firstOrNull?.getAttribute('value') ?? ''),
    );
  }
}

class BGGRecommendation {
  final int gameId;
  final String name;
  final String? thumbnail;
  final int? rank;
  final int matchScore;
  final String reason;

  BGGRecommendation({
    required this.gameId,
    required this.name,
    this.thumbnail,
    this.rank,
    required this.matchScore,
    required this.reason,
  });
}

class BGGHotGame {
  final int id;
  final String name;
  final int rank;
  final String? thumbnail;
  final int? yearPublished;

  BGGHotGame({
    required this.id,
    required this.name,
    required this.rank,
    this.thumbnail,
    this.yearPublished,
  });
  
  factory BGGHotGame.fromXml(xml.XmlElement element) {
    return BGGHotGame(
      id: int.parse(element.getAttribute('id')!),
      name: element.findElements('name').firstOrNull?.getAttribute('value') ?? '',
      rank: int.tryParse(element.getAttribute('rank') ?? '') ?? 0,
      thumbnail: element.findElements('thumbnail').firstOrNull?.getAttribute('value'),
      yearPublished: int.tryParse(element.findElements('yearpublished').firstOrNull?.getAttribute('value') ?? ''),
    );
  }
}