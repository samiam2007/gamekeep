import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import '../models/game_model.dart';

class BGGApiService {
  static const String baseUrl = 'https://boardgamegeek.com/xmlapi2';
  static DateTime _lastRequestTime = DateTime.now();
  static const Duration _minTimeBetweenRequests = Duration(seconds: 1);

  // Rate limiting
  static Future<void> _rateLimit() async {
    final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime);
    if (timeSinceLastRequest < _minTimeBetweenRequests) {
      await Future.delayed(_minTimeBetweenRequests - timeSinceLastRequest);
    }
    _lastRequestTime = DateTime.now();
  }
  
  // Helper to fix image URLs
  static String _fixImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // Debug logging
    print('BGG: Original URL: $url');
    
    // If URL already has protocol, return as is
    if (url.startsWith('http://') || url.startsWith('https://')) {
      print('BGG: URL already has protocol: $url');
      return url;
    }
    
    // If URL starts with //, add https:
    if (url.startsWith('//')) {
      final fixed = 'https:$url';
      print('BGG: Fixed // URL: $fixed');
      return fixed;
    }
    
    // If it's a relative path, prepend the BGG CDN URL
    if (url.startsWith('/')) {
      final fixed = 'https://cf.geekdo-images.com$url';
      print('BGG: Fixed relative URL: $fixed');
      return fixed;
    }
    
    // Otherwise assume it needs https://
    final fixed = 'https://$url';
    print('BGG: Added https to URL: $fixed');
    return fixed;
  }

  // Search for games
  static Future<List<BGGSearchResult>> searchGames({
    required String query,
    String type = 'boardgame',
    bool exact = false,
  }) async {
    await _rateLimit();
    
    final url = Uri.parse('$baseUrl/search');
    final params = {
      'query': query,
      'type': type,
      if (exact) 'exact': '1',
    };
    
    final response = await http.get(url.replace(queryParameters: params));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to search games');
    }
    
    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    
    return items.map((item) => BGGSearchResult.fromXml(item)).toList();
  }

  // Get game details
  static Future<BGGGameDetails?> getGameDetails({
    required int gameId,
    bool includeStats = true,
  }) async {
    await _rateLimit();
    
    final url = Uri.parse('$baseUrl/thing');
    final params = {
      'id': gameId.toString(),
      'type': 'boardgame',
      if (includeStats) 'stats': '1',
    };
    
    final response = await http.get(url.replace(queryParameters: params));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to get game details');
    }
    
    final document = xml.XmlDocument.parse(response.body);
    final item = document.findAllElements('item').firstOrNull;
    
    if (item != null) {
      return BGGGameDetails.fromXml(item);
    }
    
    return null;
  }

  // Get user's collection
  static Future<List<BGGCollectionItem>> getCollection({
    required String username,
    bool own = true,
    bool wishlist = false,
    bool wantToBuy = false,
    bool wantToPlay = false,
    bool preordered = false,
  }) async {
    await _rateLimit();
    
    final url = Uri.parse('$baseUrl/collection');
    final params = {
      'username': username,
      if (own) 'own': '1',
      if (wishlist) 'wishlist': '1',
      if (wantToBuy) 'want': '1',
      if (wantToPlay) 'wanttoplay': '1',
      if (preordered) 'preordered': '1',
      'subtype': 'boardgame',
      'stats': '1',
    };
    
    final response = await http.get(url.replace(queryParameters: params));
    
    if (response.statusCode == 202) {
      // Collection is being generated, wait and retry
      await Future.delayed(const Duration(seconds: 2));
      return getCollection(
        username: username,
        own: own,
        wishlist: wishlist,
        wantToBuy: wantToBuy,
        wantToPlay: wantToPlay,
        preordered: preordered,
      );
    }
    
    if (response.statusCode != 200) {
      throw Exception('Failed to get collection');
    }
    
    final document = xml.XmlDocument.parse(response.body);
    final items = document.findAllElements('item');
    
    return items.map((item) => BGGCollectionItem.fromXml(item)).toList();
  }

  // Get hot games
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
    
    // Parse hot games with fixed thumbnail URLs
    return items.map((item) => BGGHotGame.fromXml(item)).toList();
  }
  
  // Get recommended games based on user's collection
  static Future<List<BGGSearchResult>> getRecommendations({
    required List<int> gameIds,
    int limit = 20,
  }) async {
    // This would typically use a recommendation algorithm
    // For now, we'll get hot games as recommendations
    final hotGames = await getHotGames();
    
    // Filter out games already in collection
    final filtered = hotGames.where((game) => !gameIds.contains(game.id)).take(limit);
    
    // Convert to search results
    return filtered.map((game) => BGGSearchResult(
      id: game.id,
      name: game.name,
      yearPublished: game.yearPublished,
    )).toList();
  }
  
  // Convert BGG game to our GameModel
  static GameModel convertToGameModel(BGGGameDetails bggGame, String userId) {
    return GameModel(
      gameId: 'bgg_${bggGame.id}',
      ownerId: userId,
      title: bggGame.primaryName,
      edition: 'Standard',
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
      coverImage: _fixImageUrl(bggGame.image),
      thumbnailImage: _fixImageUrl(bggGame.thumbnail),
      condition: GameCondition.good,
      location: 'Main Collection',
      value: null,
      visibility: GameVisibility.private,
      importSource: ImportSource.bgg,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isAvailable: true,
      currentBorrowerId: null,
      loanDate: null,
      dueDate: null,
      purchasePrice: null,
      minAge: bggGame.minAge,
      description: bggGame.description,
    );
  }
}

// BGG Collection Item model
class BGGCollectionItem {
  final int gameId;
  final String name;
  final int? yearPublished;
  final String? image;
  final String? thumbnail;
  final int numPlays;
  final double? rating;
  final bool owned;
  final bool wishlist;
  final bool wantToPlay;
  final bool wantToBuy;
  final bool preordered;
  final String? comment;

  BGGCollectionItem({
    required this.gameId,
    required this.name,
    this.yearPublished,
    this.image,
    this.thumbnail,
    required this.numPlays,
    this.rating,
    required this.owned,
    required this.wishlist,
    required this.wantToPlay,
    required this.wantToBuy,
    required this.preordered,
    this.comment,
  });

  factory BGGCollectionItem.fromXml(xml.XmlElement element) {
    final stats = element.findElements('stats').firstOrNull;
    final rating = stats?.findElements('rating')?.firstOrNull;
    
    return BGGCollectionItem(
      gameId: int.parse(element.getAttribute('objectid')!),
      name: element.findElements('name').firstOrNull?.text ?? '',
      yearPublished: int.tryParse(element.findElements('yearpublished')?.firstOrNull?.text ?? ''),
      image: BGGApiService._fixImageUrl(element.findElements('image')?.firstOrNull?.text),
      thumbnail: BGGApiService._fixImageUrl(element.findElements('thumbnail')?.firstOrNull?.text),
      numPlays: int.tryParse(element.findElements('numplays')?.firstOrNull?.text ?? '0') ?? 0,
      rating: double.tryParse(rating?.getAttribute('value') ?? ''),
      owned: element.findElements('status')?.firstOrNull?.getAttribute('own') == '1',
      wishlist: element.findElements('status')?.firstOrNull?.getAttribute('wishlist') == '1',
      wantToPlay: element.findElements('status')?.firstOrNull?.getAttribute('wanttoplay') == '1',
      wantToBuy: element.findElements('status')?.firstOrNull?.getAttribute('want') == '1',
      preordered: element.findElements('status')?.firstOrNull?.getAttribute('preordered') == '1',
      comment: element.findElements('comment')?.firstOrNull?.text,
    );
  }
}

// BGG Game Details model
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
    String primaryName = '';
    List<String> alternateNames = [];
    final names = element.findElements('name');
    for (final name in names) {
      final type = name.getAttribute('type');
      final value = name.getAttribute('value') ?? '';
      if (type == 'primary') {
        primaryName = value;
      } else if (type == 'alternate') {
        alternateNames.add(value);
      }
    }

    // Parse links (publishers, designers, etc.)
    List<String> publishers = [];
    List<String> designers = [];
    List<String> artists = [];
    List<String> categories = [];
    List<String> mechanics = [];
    List<String> families = [];
    List<String> expansions = [];
    
    final links = element.findElements('link');
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
          final rankValue = r.getAttribute('value');
          if (rankValue != null && rankValue != 'Not Ranked') {
            rank = int.tryParse(rankValue);
          }
          break;
        }
      }
    }
    
    // Extract image URLs and fix them
    final imageUrl = element.findElements('image').firstOrNull?.text ?? '';
    final thumbnailUrl = element.findElements('thumbnail').firstOrNull?.text ?? '';

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
      image: BGGApiService._fixImageUrl(imageUrl),
      thumbnail: BGGApiService._fixImageUrl(thumbnailUrl),
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

// Search result model
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

// Hot games model
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
    // Hot games don't include thumbnails in the API response
    // We'll need to fetch details separately to get images
    return BGGHotGame(
      id: int.parse(element.getAttribute('id')!),
      name: element.findElements('name').firstOrNull?.getAttribute('value') ?? '',
      rank: int.tryParse(element.getAttribute('rank') ?? '') ?? 0,
      thumbnail: null, // Will be fetched separately
      yearPublished: int.tryParse(element.findElements('yearpublished').firstOrNull?.getAttribute('value') ?? ''),
    );
  }
}