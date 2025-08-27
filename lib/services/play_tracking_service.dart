import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/play_session_model.dart';
import '../models/game_model.dart';

class PlayTrackingService {
  static PlayTrackingService? _instance;
  late SharedPreferences _prefs;
  static const String _playsKey = 'gamekeep_play_sessions';
  
  // Singleton pattern
  static Future<PlayTrackingService> getInstance() async {
    if (_instance == null) {
      _instance = PlayTrackingService._();
      await _instance!._init();
    }
    return _instance!;
  }
  
  PlayTrackingService._();
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _initializeDemoData();
  }
  
  // ============ PLAY SESSION METHODS ============
  
  /// Log a new play session
  Future<bool> logPlay(PlaySession session) async {
    try {
      final sessions = await getPlaySessions();
      sessions.add(session);
      
      // Sort by play date descending
      sessions.sort((a, b) => b.playDate.compareTo(a.playDate));
      
      return await _savePlaySessions(sessions);
    } catch (e) {
      print('Error logging play: $e');
      return false;
    }
  }
  
  /// Get all play sessions
  Future<List<PlaySession>> getPlaySessions() async {
    try {
      final String? data = _prefs.getString(_playsKey);
      if (data == null) return [];
      
      final List<dynamic> jsonList = json.decode(data);
      return jsonList.map((json) => PlaySession.fromJson(json)).toList();
    } catch (e) {
      print('Error loading play sessions: $e');
      return [];
    }
  }
  
  /// Get play sessions for a specific game
  Future<List<PlaySession>> getGamePlaySessions(String gameId) async {
    final sessions = await getPlaySessions();
    return sessions.where((s) => s.gameId == gameId).toList();
  }
  
  /// Get recent play sessions
  Future<List<PlaySession>> getRecentPlays({int limit = 10}) async {
    final sessions = await getPlaySessions();
    return sessions.take(limit).toList();
  }
  
  /// Delete a play session
  Future<bool> deletePlaySession(String sessionId) async {
    try {
      final sessions = await getPlaySessions();
      sessions.removeWhere((s) => s.sessionId == sessionId);
      return await _savePlaySessions(sessions);
    } catch (e) {
      print('Error deleting play session: $e');
      return false;
    }
  }
  
  // ============ STATISTICS METHODS ============
  
  /// Get statistics for all games
  Future<Map<String, GameStatistics>> getGameStatistics() async {
    final sessions = await getPlaySessions();
    final Map<String, List<PlaySession>> gameGroups = {};
    
    // Group sessions by game
    for (final session in sessions) {
      gameGroups.putIfAbsent(session.gameId, () => []).add(session);
    }
    
    // Calculate statistics for each game
    final Map<String, GameStatistics> stats = {};
    for (final entry in gameGroups.entries) {
      final gameId = entry.key;
      final gameSessions = entry.value;
      
      if (gameSessions.isEmpty) continue;
      
      final gameTitle = gameSessions.first.gameTitle;
      final totalPlays = gameSessions.length;
      final totalMinutes = gameSessions.fold<int>(0, (sum, s) => sum + s.duration);
      
      // Calculate wins and scores
      int wins = 0;
      int losses = 0;
      double totalScore = 0;
      int scoreCount = 0;
      
      for (final session in gameSessions) {
        if (session.winner == 'You' || 
            session.players.any((p) => p.name == 'You' && p.isWinner)) {
          wins++;
        } else if (session.status == PlaySessionStatus.completed) {
          losses++;
        }
        
        if (session.yourScore != null) {
          totalScore += session.yourScore!;
          scoreCount++;
        }
      }
      
      // Find most frequent players
      final playerCounts = <String, int>{};
      for (final session in gameSessions) {
        for (final player in session.players) {
          if (player.name != 'You') {
            playerCounts[player.name] = (playerCounts[player.name] ?? 0) + 1;
          }
        }
      }
      
      final sortedPlayers = playerCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final mostFrequentPlayers = sortedPlayers.take(3).map((e) => e.key).toList();
      
      // Find favorite location
      final locationCounts = <String, int>{};
      for (final session in gameSessions) {
        locationCounts[session.location] = 
            (locationCounts[session.location] ?? 0) + 1;
      }
      
      final favoriteLocation = locationCounts.isEmpty ? 'Home' :
          locationCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      
      stats[gameId] = GameStatistics(
        gameId: gameId,
        gameTitle: gameTitle,
        totalPlays: totalPlays,
        totalMinutesPlayed: totalMinutes,
        lastPlayed: gameSessions.first.playDate,
        firstPlayed: gameSessions.last.playDate,
        averageScore: scoreCount > 0 ? totalScore / scoreCount : 0,
        wins: wins,
        losses: losses,
        winRate: (wins + losses) > 0 ? wins / (wins + losses) : 0,
        mostFrequentPlayers: mostFrequentPlayers,
        favoriteLocation: favoriteLocation,
      );
    }
    
    return stats;
  }
  
  /// Get player statistics
  Future<List<PlayerStatistics>> getPlayerStatistics() async {
    final sessions = await getPlaySessions();
    final Map<String, List<PlaySession>> playerGroups = {};
    
    // Group sessions by player
    for (final session in sessions) {
      for (final player in session.players) {
        if (player.name != 'You') {
          playerGroups.putIfAbsent(player.name, () => []).add(session);
        }
      }
    }
    
    // Calculate statistics for each player
    final List<PlayerStatistics> stats = [];
    for (final entry in playerGroups.entries) {
      final playerName = entry.key;
      final playerSessions = entry.value;
      
      if (playerSessions.isEmpty) continue;
      
      int wins = 0;
      int losses = 0;
      
      for (final session in playerSessions) {
        if (session.winner == 'You' || 
            session.players.any((p) => p.name == 'You' && p.isWinner)) {
          wins++;
        } else if (session.players.any((p) => p.name == playerName && p.isWinner)) {
          losses++;
        }
      }
      
      // Find favorite games with this player
      final gameCounts = <String, int>{};
      for (final session in playerSessions) {
        gameCounts[session.gameTitle] = (gameCounts[session.gameTitle] ?? 0) + 1;
      }
      
      final sortedGames = gameCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final favoriteGames = sortedGames.take(3).map((e) => e.key).toList();
      
      stats.add(PlayerStatistics(
        playerName: playerName,
        gamesPlayedTogether: playerSessions.length,
        wins: wins,
        losses: losses,
        winRate: (wins + losses) > 0 ? wins / (wins + losses) : 0,
        favoriteGames: favoriteGames,
        lastPlayedTogether: playerSessions.first.playDate,
      ));
    }
    
    // Sort by games played together
    stats.sort((a, b) => b.gamesPlayedTogether.compareTo(a.gamesPlayedTogether));
    
    return stats;
  }
  
  /// Get overall statistics
  Future<Map<String, dynamic>> getOverallStatistics() async {
    final sessions = await getPlaySessions();
    
    if (sessions.isEmpty) {
      return {
        'totalPlays': 0,
        'totalHoursPlayed': 0,
        'uniqueGames': 0,
        'uniquePlayers': 0,
        'averagePlayTime': 0,
        'mostPlayedGame': null,
        'longestSession': null,
        'currentStreak': 0,
        'longestStreak': 0,
        'playsThisWeek': 0,
        'playsThisMonth': 0,
        'playsThisYear': 0,
      };
    }
    
    final totalMinutes = sessions.fold<int>(0, (sum, s) => sum + s.duration);
    final uniqueGames = sessions.map((s) => s.gameId).toSet().length;
    
    final allPlayers = <String>{};
    for (final session in sessions) {
      for (final player in session.players) {
        if (player.name != 'You') {
          allPlayers.add(player.name);
        }
      }
    }
    
    // Find most played game
    final gameCounts = <String, int>{};
    for (final session in sessions) {
      gameCounts[session.gameTitle] = (gameCounts[session.gameTitle] ?? 0) + 1;
    }
    
    String? mostPlayedGame;
    if (gameCounts.isNotEmpty) {
      final mostPlayed = gameCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      mostPlayedGame = '${mostPlayed.key} (${mostPlayed.value} plays)';
    }
    
    // Find longest session
    final longestSession = sessions.reduce((a, b) => a.duration > b.duration ? a : b);
    
    // Calculate streaks
    final streaks = _calculateStreaks(sessions);
    
    // Calculate recent plays
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));
    final yearAgo = now.subtract(const Duration(days: 365));
    
    final playsThisWeek = sessions.where((s) => s.playDate.isAfter(weekAgo)).length;
    final playsThisMonth = sessions.where((s) => s.playDate.isAfter(monthAgo)).length;
    final playsThisYear = sessions.where((s) => s.playDate.isAfter(yearAgo)).length;
    
    return {
      'totalPlays': sessions.length,
      'totalHoursPlayed': (totalMinutes / 60).toStringAsFixed(1),
      'uniqueGames': uniqueGames,
      'uniquePlayers': allPlayers.length,
      'averagePlayTime': sessions.isNotEmpty ? totalMinutes ~/ sessions.length : 0,
      'mostPlayedGame': mostPlayedGame,
      'longestSession': '${longestSession.gameTitle} (${longestSession.duration} min)',
      'currentStreak': streaks['current'],
      'longestStreak': streaks['longest'],
      'playsThisWeek': playsThisWeek,
      'playsThisMonth': playsThisMonth,
      'playsThisYear': playsThisYear,
    };
  }
  
  Map<String, int> _calculateStreaks(List<PlaySession> sessions) {
    if (sessions.isEmpty) return {'current': 0, 'longest': 0};
    
    // Sort sessions by date
    final sorted = List<PlaySession>.from(sessions)
      ..sort((a, b) => a.playDate.compareTo(b.playDate));
    
    int currentStreak = 0;
    int longestStreak = 0;
    DateTime? lastDate;
    
    for (final session in sorted) {
      final playDate = DateTime(
        session.playDate.year,
        session.playDate.month,
        session.playDate.day,
      );
      
      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final daysDiff = playDate.difference(lastDate).inDays;
        if (daysDiff == 1) {
          currentStreak++;
        } else if (daysDiff > 1) {
          currentStreak = 1;
        }
      }
      
      longestStreak = currentStreak > longestStreak ? currentStreak : longestStreak;
      lastDate = playDate;
    }
    
    // Check if streak is still active
    final today = DateTime.now();
    final daysSinceLastPlay = today.difference(lastDate!).inDays;
    if (daysSinceLastPlay > 1) {
      currentStreak = 0;
    }
    
    return {'current': currentStreak, 'longest': longestStreak};
  }
  
  // ============ HELPERS ============
  
  Future<bool> _savePlaySessions(List<PlaySession> sessions) async {
    try {
      final String data = json.encode(
        sessions.map((s) => s.toJson()).toList()
      );
      return await _prefs.setString(_playsKey, data);
    } catch (e) {
      print('Error saving play sessions: $e');
      return false;
    }
  }
  
  void _initializeDemoData() async {
    final sessions = await getPlaySessions();
    if (sessions.isNotEmpty) return; // Don't override existing data
    
    // Create demo play sessions
    final demoSessions = [
      PlaySession(
        sessionId: 'demo_1',
        gameId: '1',
        gameTitle: 'Wingspan',
        userId: 'demo_user',
        playDate: DateTime.now().subtract(const Duration(days: 1)),
        duration: 75,
        players: [
          Player(name: 'You', score: 82, isWinner: true),
          Player(name: 'Sarah', score: 76),
          Player(name: 'Mike', score: 71),
        ],
        winner: 'You',
        yourScore: 82,
        highScore: 82,
        location: 'Home',
        notes: 'Great game! Finally beat Sarah at Wingspan',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      PlaySession(
        sessionId: 'demo_2',
        gameId: '2',
        gameTitle: 'Catan',
        userId: 'demo_user',
        playDate: DateTime.now().subtract(const Duration(days: 3)),
        duration: 90,
        players: [
          Player(name: 'You', score: 8),
          Player(name: 'Alex', score: 10, isWinner: true),
          Player(name: 'Sarah', score: 9),
          Player(name: 'Mike', score: 7),
        ],
        winner: 'Alex',
        yourScore: 8,
        highScore: 10,
        location: 'Game Cafe',
        notes: 'Alex had amazing wheat production',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      PlaySession(
        sessionId: 'demo_3',
        gameId: '3',
        gameTitle: 'Azul',
        userId: 'demo_user',
        playDate: DateTime.now().subtract(const Duration(days: 5)),
        duration: 45,
        players: [
          Player(name: 'You', score: 68, isWinner: true),
          Player(name: 'Sarah', score: 62),
        ],
        winner: 'You',
        yourScore: 68,
        highScore: 68,
        location: 'Home',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      PlaySession(
        sessionId: 'demo_4',
        gameId: '1',
        gameTitle: 'Wingspan',
        userId: 'demo_user',
        playDate: DateTime.now().subtract(const Duration(days: 7)),
        duration: 70,
        players: [
          Player(name: 'You', score: 79),
          Player(name: 'Mike', score: 81, isWinner: true),
          Player(name: 'Alex', score: 72),
        ],
        winner: 'Mike',
        yourScore: 79,
        highScore: 81,
        location: 'Mike\'s House',
        notes: 'Mike had an amazing raven strategy',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
      PlaySession(
        sessionId: 'demo_5',
        gameId: '4',
        gameTitle: 'Ticket to Ride',
        userId: 'demo_user',
        playDate: DateTime.now().subtract(const Duration(days: 10)),
        duration: 60,
        players: [
          Player(name: 'You', score: 124, isWinner: true),
          Player(name: 'Sarah', score: 118),
          Player(name: 'Alex', score: 95),
        ],
        winner: 'You',
        yourScore: 124,
        highScore: 124,
        location: 'Home',
        notes: 'Completed all my destination tickets!',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ];
    
    await _savePlaySessions(demoSessions);
  }
}