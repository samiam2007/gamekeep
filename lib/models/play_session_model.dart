class PlaySession {
  final String sessionId;
  final String gameId;
  final String gameTitle;
  final String userId;
  final DateTime playDate;
  final int duration; // in minutes
  final List<Player> players;
  final String? winner;
  final int? yourScore;
  final int? highScore;
  final String location;
  final String? notes;
  final List<String> photos;
  final PlaySessionStatus status;
  final DateTime createdAt;

  PlaySession({
    required this.sessionId,
    required this.gameId,
    required this.gameTitle,
    required this.userId,
    required this.playDate,
    required this.duration,
    required this.players,
    this.winner,
    this.yourScore,
    this.highScore,
    required this.location,
    this.notes,
    this.photos = const [],
    this.status = PlaySessionStatus.completed,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'gameId': gameId,
      'gameTitle': gameTitle,
      'userId': userId,
      'playDate': playDate.toIso8601String(),
      'duration': duration,
      'players': players.map((p) => p.toJson()).toList(),
      'winner': winner,
      'yourScore': yourScore,
      'highScore': highScore,
      'location': location,
      'notes': notes,
      'photos': photos,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlaySession.fromJson(Map<String, dynamic> json) {
    return PlaySession(
      sessionId: json['sessionId'],
      gameId: json['gameId'],
      gameTitle: json['gameTitle'],
      userId: json['userId'],
      playDate: DateTime.parse(json['playDate']),
      duration: json['duration'],
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p))
          .toList(),
      winner: json['winner'],
      yourScore: json['yourScore'],
      highScore: json['highScore'],
      location: json['location'],
      notes: json['notes'],
      photos: List<String>.from(json['photos'] ?? []),
      status: PlaySessionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PlaySessionStatus.completed,
      ),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  PlaySession copyWith({
    String? sessionId,
    String? gameId,
    String? gameTitle,
    String? userId,
    DateTime? playDate,
    int? duration,
    List<Player>? players,
    String? winner,
    int? yourScore,
    int? highScore,
    String? location,
    String? notes,
    List<String>? photos,
    PlaySessionStatus? status,
    DateTime? createdAt,
  }) {
    return PlaySession(
      sessionId: sessionId ?? this.sessionId,
      gameId: gameId ?? this.gameId,
      gameTitle: gameTitle ?? this.gameTitle,
      userId: userId ?? this.userId,
      playDate: playDate ?? this.playDate,
      duration: duration ?? this.duration,
      players: players ?? this.players,
      winner: winner ?? this.winner,
      yourScore: yourScore ?? this.yourScore,
      highScore: highScore ?? this.highScore,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Player {
  final String name;
  final int? score;
  final bool isWinner;
  final String? color; // For identifying players
  
  Player({
    required this.name,
    this.score,
    this.isWinner = false,
    this.color,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'isWinner': isWinner,
      'color': color,
    };
  }
  
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      score: json['score'],
      isWinner: json['isWinner'] ?? false,
      color: json['color'],
    );
  }
}

enum PlaySessionStatus {
  inProgress,
  completed,
  abandoned
}

// Statistics aggregation classes
class GameStatistics {
  final String gameId;
  final String gameTitle;
  final int totalPlays;
  final int totalMinutesPlayed;
  final DateTime? lastPlayed;
  final DateTime? firstPlayed;
  final double averageScore;
  final int wins;
  final int losses;
  final double winRate;
  final List<String> mostFrequentPlayers;
  final String favoriteLocation;
  
  GameStatistics({
    required this.gameId,
    required this.gameTitle,
    required this.totalPlays,
    required this.totalMinutesPlayed,
    this.lastPlayed,
    this.firstPlayed,
    required this.averageScore,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.mostFrequentPlayers,
    required this.favoriteLocation,
  });
  
  int get averagePlayTime => totalPlays > 0 ? totalMinutesPlayed ~/ totalPlays : 0;
  
  String get playFrequency {
    if (firstPlayed == null || lastPlayed == null) return 'Never played';
    
    final daysSinceFirst = DateTime.now().difference(firstPlayed!).inDays;
    if (daysSinceFirst == 0) return 'Just started';
    
    final playsPerMonth = (totalPlays / (daysSinceFirst / 30)).toStringAsFixed(1);
    return '$playsPerMonth plays/month';
  }
}

class PlayerStatistics {
  final String playerName;
  final int gamesPlayedTogether;
  final int wins;
  final int losses;
  final double winRate;
  final List<String> favoriteGames;
  final DateTime? lastPlayedTogether;
  
  PlayerStatistics({
    required this.playerName,
    required this.gamesPlayedTogether,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.favoriteGames,
    this.lastPlayedTogether,
  });
}