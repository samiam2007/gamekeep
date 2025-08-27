import 'package:cloud_firestore/cloud_firestore.dart';

class PlayModel {
  final String playId;
  final String gameId;
  final String ownerId;
  final DateTime date;
  final int duration; // in minutes
  final List<Player> players;
  final String notes;
  final List<String> photos;
  final String? location;
  final DateTime createdAt;

  PlayModel({
    required this.playId,
    required this.gameId,
    required this.ownerId,
    required this.date,
    required this.duration,
    required this.players,
    required this.notes,
    required this.photos,
    this.location,
    required this.createdAt,
  });

  factory PlayModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PlayModel(
      playId: doc.id,
      gameId: data['gameId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      duration: data['duration'] ?? 0,
      players: (data['players'] as List<dynamic>?)
              ?.map((p) => Player.fromMap(p))
              .toList() ??
          [],
      notes: data['notes'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gameId': gameId,
      'ownerId': ownerId,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'players': players.map((p) => p.toMap()).toList(),
      'notes': notes,
      'photos': photos,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  PlayModel copyWith({
    String? playId,
    String? gameId,
    String? ownerId,
    DateTime? date,
    int? duration,
    List<Player>? players,
    String? notes,
    List<String>? photos,
    String? location,
    DateTime? createdAt,
  }) {
    return PlayModel(
      playId: playId ?? this.playId,
      gameId: gameId ?? this.gameId,
      ownerId: ownerId ?? this.ownerId,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      players: players ?? this.players,
      notes: notes ?? this.notes,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class Player {
  final String name;
  final int? score;
  final bool isWinner;
  final String? userId;
  final String color;

  Player({
    required this.name,
    this.score,
    this.isWinner = false,
    this.userId,
    this.color = 'blue',
  });

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      name: map['name'] ?? '',
      score: map['score'],
      isWinner: map['isWinner'] ?? false,
      userId: map['userId'],
      color: map['color'] ?? 'blue',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'score': score,
      'isWinner': isWinner,
      'userId': userId,
      'color': color,
    };
  }
}