import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_model.dart';

class GameStorageService {
  static const String _gamesKey = 'imported_games';
  static const String _lastImportKey = 'last_import_time';

  static Future<List<GameModel>> loadImportedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? gamesJson = prefs.getString(_gamesKey);
      
      if (gamesJson == null || gamesJson.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = json.decode(gamesJson);
      return decoded.map((json) => GameModel.fromJson(json)).toList();
    } catch (e) {
      print('Error loading imported games: $e');
      return [];
    }
  }

  static Future<bool> saveImportedGames(List<GameModel> games) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String gamesJson = json.encode(
        games.map((game) => game.toJson()).toList(),
      );
      
      await prefs.setString(_gamesKey, gamesJson);
      await prefs.setString(_lastImportKey, DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      print('Error saving imported games: $e');
      return false;
    }
  }

  static Future<bool> addImportedGames(List<GameModel> newGames) async {
    try {
      // Load existing games
      final existingGames = await loadImportedGames();
      
      // Create a map to avoid duplicates based on BGG ID
      final gamesMap = <String, GameModel>{};
      
      // Add existing games
      for (final game in existingGames) {
        final key = game.bggId?.toString() ?? game.gameId;
        gamesMap[key] = game;
      }
      
      // Add or update with new games
      for (final game in newGames) {
        final key = game.bggId?.toString() ?? game.gameId;
        gamesMap[key] = game;
      }
      
      // Save combined list
      return await saveImportedGames(gamesMap.values.toList());
    } catch (e) {
      print('Error adding imported games: $e');
      return false;
    }
  }

  static Future<bool> removeGame(String gameId) async {
    try {
      final games = await loadImportedGames();
      games.removeWhere((game) => 
        game.gameId == gameId || 
        game.bggId?.toString() == gameId
      );
      return await saveImportedGames(games);
    } catch (e) {
      print('Error removing game: $e');
      return false;
    }
  }

  static Future<void> clearImportedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_gamesKey);
      await prefs.remove(_lastImportKey);
    } catch (e) {
      print('Error clearing imported games: $e');
    }
  }

  static Future<DateTime?> getLastImportTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? timeStr = prefs.getString(_lastImportKey);
      if (timeStr != null) {
        return DateTime.parse(timeStr);
      }
    } catch (e) {
      print('Error getting last import time: $e');
    }
    return null;
  }
}