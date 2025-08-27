class CampaignData {
  final String campaignId;
  final String gameId;
  final String campaignName;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final int currentSession;
  final String? currentScenario;
  final String? currentMap;
  final Map<String, PlayerCampaignData> playerProgress;
  final Map<String, dynamic> gameState;
  final List<String> completedScenarios;
  final List<String> unlockedContent;
  final Map<String, int> globalAchievements;
  final String? notes;

  CampaignData({
    required this.campaignId,
    required this.gameId,
    required this.campaignName,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.currentSession = 1,
    this.currentScenario,
    this.currentMap,
    required this.playerProgress,
    required this.gameState,
    this.completedScenarios = const [],
    this.unlockedContent = const [],
    this.globalAchievements = const {},
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'campaignId': campaignId,
      'gameId': gameId,
      'campaignName': campaignName,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'currentSession': currentSession,
      'currentScenario': currentScenario,
      'currentMap': currentMap,
      'playerProgress': playerProgress.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'gameState': gameState,
      'completedScenarios': completedScenarios,
      'unlockedContent': unlockedContent,
      'globalAchievements': globalAchievements,
      'notes': notes,
    };
  }

  factory CampaignData.fromJson(Map<String, dynamic> json) {
    return CampaignData(
      campaignId: json['campaignId'],
      gameId: json['gameId'],
      campaignName: json['campaignName'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? true,
      currentSession: json['currentSession'] ?? 1,
      currentScenario: json['currentScenario'],
      currentMap: json['currentMap'],
      playerProgress: (json['playerProgress'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, PlayerCampaignData.fromJson(value)),
      ) ?? {},
      gameState: json['gameState'] ?? {},
      completedScenarios: List<String>.from(json['completedScenarios'] ?? []),
      unlockedContent: List<String>.from(json['unlockedContent'] ?? []),
      globalAchievements: Map<String, int>.from(json['globalAchievements'] ?? {}),
      notes: json['notes'],
    );
  }

  CampaignData copyWith({
    String? currentScenario,
    String? currentMap,
    Map<String, PlayerCampaignData>? playerProgress,
    Map<String, dynamic>? gameState,
    List<String>? completedScenarios,
    List<String>? unlockedContent,
    Map<String, int>? globalAchievements,
    String? notes,
    bool? isActive,
    DateTime? endDate,
  }) {
    return CampaignData(
      campaignId: campaignId,
      gameId: gameId,
      campaignName: campaignName,
      startDate: startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      currentSession: currentSession + (currentScenario != null ? 1 : 0),
      currentScenario: currentScenario ?? this.currentScenario,
      currentMap: currentMap ?? this.currentMap,
      playerProgress: playerProgress ?? this.playerProgress,
      gameState: gameState ?? this.gameState,
      completedScenarios: completedScenarios ?? this.completedScenarios,
      unlockedContent: unlockedContent ?? this.unlockedContent,
      globalAchievements: globalAchievements ?? this.globalAchievements,
      notes: notes ?? this.notes,
    );
  }
}

class PlayerCampaignData {
  final String playerName;
  final String? characterName;
  final String? characterClass;
  final int level;
  final int experience;
  final Map<String, int> stats; // HP, Gold, etc.
  final List<String> inventory;
  final List<String> abilities;
  final List<String> perks;
  final Map<String, bool> achievements;
  final String? notes;

  PlayerCampaignData({
    required this.playerName,
    this.characterName,
    this.characterClass,
    this.level = 1,
    this.experience = 0,
    this.stats = const {},
    this.inventory = const [],
    this.abilities = const [],
    this.perks = const [],
    this.achievements = const {},
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'characterName': characterName,
      'characterClass': characterClass,
      'level': level,
      'experience': experience,
      'stats': stats,
      'inventory': inventory,
      'abilities': abilities,
      'perks': perks,
      'achievements': achievements,
      'notes': notes,
    };
  }

  factory PlayerCampaignData.fromJson(Map<String, dynamic> json) {
    return PlayerCampaignData(
      playerName: json['playerName'],
      characterName: json['characterName'],
      characterClass: json['characterClass'],
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      stats: Map<String, int>.from(json['stats'] ?? {}),
      inventory: List<String>.from(json['inventory'] ?? []),
      abilities: List<String>.from(json['abilities'] ?? []),
      perks: List<String>.from(json['perks'] ?? []),
      achievements: Map<String, bool>.from(json['achievements'] ?? {}),
      notes: json['notes'],
    );
  }

  PlayerCampaignData copyWith({
    String? characterName,
    String? characterClass,
    int? level,
    int? experience,
    Map<String, int>? stats,
    List<String>? inventory,
    List<String>? abilities,
    List<String>? perks,
    Map<String, bool>? achievements,
    String? notes,
  }) {
    return PlayerCampaignData(
      playerName: playerName,
      characterName: characterName ?? this.characterName,
      characterClass: characterClass ?? this.characterClass,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      stats: stats ?? this.stats,
      inventory: inventory ?? this.inventory,
      abilities: abilities ?? this.abilities,
      perks: perks ?? this.perks,
      achievements: achievements ?? this.achievements,
      notes: notes ?? this.notes,
    );
  }
}

// Enhanced PlaySession for campaign games
class EnhancedPlaySession {
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
  
  // Campaign-specific fields
  final String? campaignId;
  final bool isCampaignSession;
  final int? sessionNumber;
  final String? scenario;
  final String? map;
  final Map<String, dynamic>? sessionState; // Save state for this session
  final List<String>? completedObjectives;
  final Map<String, int>? resourcesGained;
  final Map<String, List<String>>? itemsFound; // Player -> items
  
  final DateTime createdAt;

  EnhancedPlaySession({
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
    this.campaignId,
    this.isCampaignSession = false,
    this.sessionNumber,
    this.scenario,
    this.map,
    this.sessionState,
    this.completedObjectives,
    this.resourcesGained,
    this.itemsFound,
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
      'campaignId': campaignId,
      'isCampaignSession': isCampaignSession,
      'sessionNumber': sessionNumber,
      'scenario': scenario,
      'map': map,
      'sessionState': sessionState,
      'completedObjectives': completedObjectives,
      'resourcesGained': resourcesGained,
      'itemsFound': itemsFound,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EnhancedPlaySession.fromJson(Map<String, dynamic> json) {
    return EnhancedPlaySession(
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
      campaignId: json['campaignId'],
      isCampaignSession: json['isCampaignSession'] ?? false,
      sessionNumber: json['sessionNumber'],
      scenario: json['scenario'],
      map: json['map'],
      sessionState: json['sessionState'],
      completedObjectives: json['completedObjectives'] != null
          ? List<String>.from(json['completedObjectives'])
          : null,
      resourcesGained: json['resourcesGained'] != null
          ? Map<String, int>.from(json['resourcesGained'])
          : null,
      itemsFound: json['itemsFound'] != null
          ? (json['itemsFound'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            )
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Player {
  final String name;
  final int? score;
  final bool isWinner;
  final String? color;
  final String? characterName; // For campaign games
  
  Player({
    required this.name,
    this.score,
    this.isWinner = false,
    this.color,
    this.characterName,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'isWinner': isWinner,
      'color': color,
      'characterName': characterName,
    };
  }
  
  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'],
      score: json['score'],
      isWinner: json['isWinner'] ?? false,
      color: json['color'],
      characterName: json['characterName'],
    );
  }
}

enum PlaySessionStatus {
  inProgress,
  completed,
  abandoned,
  paused,
}