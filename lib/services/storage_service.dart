import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';

class StorageService {
  static const String _gamesKey = 'gamekeep_games';
  static const String _userPrefsKey = 'gamekeep_prefs';
  static const String _friendsKey = 'gamekeep_friends';
  static const String _playsKey = 'gamekeep_plays';
  static const String _statsKey = 'gamekeep_stats';
  
  late SharedPreferences _prefs;
  static StorageService? _instance;
  
  // Singleton pattern
  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      await _instance!._init();
    }
    return _instance!;
  }
  
  StorageService._();
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // ============ GAME COLLECTION METHODS ============
  
  /// Save entire game collection
  Future<bool> saveGames(List<GameModel> games) async {
    try {
      final List<Map<String, dynamic>> gamesJson = 
          games.map((game) => game.toJson()).toList();
      final String encodedData = json.encode(gamesJson);
      return await _prefs.setString(_gamesKey, encodedData);
    } catch (e) {
      print('Error saving games: $e');
      return false;
    }
  }
  
  /// Load all games from storage
  Future<List<GameModel>> loadGames() async {
    try {
      final String? encodedData = _prefs.getString(_gamesKey);
      if (encodedData == null) return [];
      
      final List<dynamic> gamesJson = json.decode(encodedData);
      return gamesJson.map((json) => 
          GameModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading games: $e');
      return [];
    }
  }
  
  /// Add a single game
  Future<bool> addGame(GameModel game) async {
    final games = await loadGames();
    
    // Check if game already exists
    final existingIndex = games.indexWhere(
      (g) => g.bggId == game.bggId || g.gameId == game.gameId
    );
    
    if (existingIndex >= 0) {
      // Update existing game
      games[existingIndex] = game;
    } else {
      // Add new game
      games.add(game);
    }
    
    return await saveGames(games);
  }
  
  /// Remove a game
  Future<bool> removeGame(String gameId) async {
    final games = await loadGames();
    games.removeWhere((game) => game.gameId == gameId);
    return await saveGames(games);
  }
  
  /// Update a game
  Future<bool> updateGame(GameModel updatedGame) async {
    final games = await loadGames();
    final index = games.indexWhere((g) => g.gameId == updatedGame.gameId);
    
    if (index >= 0) {
      games[index] = updatedGame;
      return await saveGames(games);
    }
    return false;
  }
  
  /// Search games locally
  Future<List<GameModel>> searchGames(String query) async {
    if (query.isEmpty) return [];
    
    final games = await loadGames();
    final lowerQuery = query.toLowerCase();
    
    return games.where((game) {
      return game.title.toLowerCase().contains(lowerQuery) ||
             game.publisher.toLowerCase().contains(lowerQuery) ||
             game.designers.any((d) => d.toLowerCase().contains(lowerQuery)) ||
             game.categories.any((c) => c.toLowerCase().contains(lowerQuery)) ||
             game.mechanics.any((m) => m.toLowerCase().contains(lowerQuery));
    }).toList();
  }
  
  /// Get games by filter
  Future<List<GameModel>> getFilteredGames({
    bool? isAvailable,
    GameCondition? condition,
    int? minPlayers,
    int? maxPlayers,
    int? maxPlayTime,
    double? minWeight,
    double? maxWeight,
    List<String>? tags,
  }) async {
    final games = await loadGames();
    
    return games.where((game) {
      if (isAvailable != null && game.isAvailable != isAvailable) {
        return false;
      }
      if (condition != null && game.condition != condition) {
        return false;
      }
      if (minPlayers != null && game.minPlayers > minPlayers) {
        return false;
      }
      if (maxPlayers != null && game.maxPlayers < maxPlayers) {
        return false;
      }
      if (maxPlayTime != null && game.playTime > maxPlayTime) {
        return false;
      }
      if (minWeight != null && game.weight < minWeight) {
        return false;
      }
      if (maxWeight != null && game.weight > maxWeight) {
        return false;
      }
      if (tags != null && tags.isNotEmpty) {
        if (!tags.any((tag) => game.tags.contains(tag))) {
          return false;
        }
      }
      return true;
    }).toList();
  }
  
  // ============ USER PREFERENCES ============
  
  /// Save user preferences
  Future<bool> saveUserPreferences(Map<String, dynamic> prefs) async {
    try {
      final String encodedData = json.encode(prefs);
      return await _prefs.setString(_userPrefsKey, encodedData);
    } catch (e) {
      print('Error saving preferences: $e');
      return false;
    }
  }
  
  /// Load user preferences
  Future<Map<String, dynamic>> loadUserPreferences() async {
    try {
      final String? encodedData = _prefs.getString(_userPrefsKey);
      if (encodedData == null) {
        return _getDefaultPreferences();
      }
      return json.decode(encodedData);
    } catch (e) {
      print('Error loading preferences: $e');
      return _getDefaultPreferences();
    }
  }
  
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'theme': 'dark',
      'sortBy': 'title',
      'viewMode': 'grid',
      'showUnavailable': true,
      'defaultLocation': '',
      'currency': 'USD',
      'language': 'en',
      'notifications': {
        'loanReminders': true,
        'newGames': true,
        'friendActivity': true,
      },
    };
  }
  
  // ============ PLAY HISTORY ============
  
  /// Save a play session
  Future<bool> savePlay(Map<String, dynamic> playData) async {
    try {
      final plays = await loadPlays();
      plays.add(playData);
      
      final String encodedData = json.encode(plays);
      return await _prefs.setString(_playsKey, encodedData);
    } catch (e) {
      print('Error saving play: $e');
      return false;
    }
  }
  
  /// Load play history
  Future<List<Map<String, dynamic>>> loadPlays() async {
    try {
      final String? encodedData = _prefs.getString(_playsKey);
      if (encodedData == null) return [];
      
      final List<dynamic> plays = json.decode(encodedData);
      return plays.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading plays: $e');
      return [];
    }
  }
  
  /// Get plays for specific game
  Future<List<Map<String, dynamic>>> getPlaysForGame(String gameId) async {
    final plays = await loadPlays();
    return plays.where((play) => play['gameId'] == gameId).toList();
  }
  
  // ============ STATISTICS ============
  
  /// Update statistics
  Future<bool> updateStats() async {
    try {
      final games = await loadGames();
      final plays = await loadPlays();
      
      final stats = {
        'totalGames': games.length,
        'availableGames': games.where((g) => g.isAvailable).length,
        'loanedGames': games.where((g) => !g.isAvailable).length,
        'totalPlays': plays.length,
        'uniqueGamesPlayed': plays.map((p) => p['gameId']).toSet().length,
        'averageWeight': games.isEmpty ? 0.0 : 
            games.map((g) => g.weight).reduce((a, b) => a + b) / games.length,
        'totalValue': games.map((g) => g.purchasePrice ?? 0).reduce((a, b) => a + b),
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      final String encodedData = json.encode(stats);
      return await _prefs.setString(_statsKey, encodedData);
    } catch (e) {
      print('Error updating stats: $e');
      return false;
    }
  }
  
  /// Load statistics
  Future<Map<String, dynamic>> loadStats() async {
    try {
      final String? encodedData = _prefs.getString(_statsKey);
      if (encodedData == null) {
        await updateStats();
        return loadStats();
      }
      return json.decode(encodedData);
    } catch (e) {
      print('Error loading stats: $e');
      return {
        'totalGames': 0,
        'availableGames': 0,
        'loanedGames': 0,
        'totalPlays': 0,
        'uniqueGamesPlayed': 0,
        'averageWeight': 0.0,
        'totalValue': 0.0,
      };
    }
  }
  
  // ============ FRIENDS & LENDING ============
  
  /// Save friends list
  Future<bool> saveFriends(List<Map<String, dynamic>> friends) async {
    try {
      final String encodedData = json.encode(friends);
      return await _prefs.setString(_friendsKey, encodedData);
    } catch (e) {
      print('Error saving friends: $e');
      return false;
    }
  }
  
  /// Load friends list
  Future<List<Map<String, dynamic>>> loadFriends() async {
    try {
      final String? encodedData = _prefs.getString(_friendsKey);
      if (encodedData == null) return [];
      
      final List<dynamic> friends = json.decode(encodedData);
      return friends.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading friends: $e');
      return [];
    }
  }
  
  /// Record a loan
  Future<bool> loanGame(String gameId, String friendId, DateTime dueDate) async {
    final games = await loadGames();
    final gameIndex = games.indexWhere((g) => g.gameId == gameId);
    
    if (gameIndex >= 0) {
      games[gameIndex] = games[gameIndex].copyWith(
        isAvailable: false,
        currentBorrowerId: friendId,
        loanDate: DateTime.now(),
        dueDate: dueDate,
      );
      
      return await saveGames(games);
    }
    return false;
  }
  
  /// Return a loaned game
  Future<bool> returnGame(String gameId) async {
    final games = await loadGames();
    final gameIndex = games.indexWhere((g) => g.gameId == gameId);
    
    if (gameIndex >= 0) {
      games[gameIndex] = games[gameIndex].copyWith(
        isAvailable: true,
        currentBorrowerId: null,
        loanDate: null,
        dueDate: null,
      );
      
      return await saveGames(games);
    }
    return false;
  }
  
  // ============ IMPORT/EXPORT ============
  
  /// Export all data as JSON
  Future<String> exportAllData() async {
    final data = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'games': (await loadGames()).map((g) => g.toJson()).toList(),
      'plays': await loadPlays(),
      'friends': await loadFriends(),
      'preferences': await loadUserPreferences(),
      'stats': await loadStats(),
    };
    
    return json.encode(data);
  }
  
  /// Import data from JSON
  Future<bool> importData(String jsonData) async {
    try {
      final data = json.decode(jsonData);
      
      // Import games
      if (data['games'] != null) {
        final games = (data['games'] as List)
            .map((g) => GameModel.fromJson(g))
            .toList();
        await saveGames(games);
      }
      
      // Import plays
      if (data['plays'] != null) {
        final plays = (data['plays'] as List).cast<Map<String, dynamic>>();
        for (final play in plays) {
          await savePlay(play);
        }
      }
      
      // Import friends
      if (data['friends'] != null) {
        await saveFriends((data['friends'] as List).cast<Map<String, dynamic>>());
      }
      
      // Import preferences
      if (data['preferences'] != null) {
        await saveUserPreferences(data['preferences']);
      }
      
      // Update stats
      await updateStats();
      
      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
  
  /// Clear all data
  Future<bool> clearAllData() async {
    try {
      await _prefs.clear();
      return true;
    } catch (e) {
      print('Error clearing data: $e');
      return false;
    }
  }
}