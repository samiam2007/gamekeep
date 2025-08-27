import 'package:cloud_firestore/cloud_firestore.dart';

enum GameCondition { mint, good, fair, poor }
enum GameVisibility { private, friends, public }
enum ImportSource { manual, photo, bgg, barcode }

class GameModel {
  final String gameId;
  final String ownerId;
  final String title;
  final String? edition;
  final String publisher;
  final int year;
  final List<String> designers;
  final int minPlayers;
  final int maxPlayers;
  final int playTime;
  final double weight;
  final int? bggId;
  final int? bggRank;
  final List<String> mechanics;
  final List<String> categories;
  final List<String> tags;
  final String coverImage;
  final String thumbnailImage;
  final GameCondition condition;
  final String location;
  final double? value;
  final GameVisibility visibility;
  final ImportSource importSource;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;
  final String? currentBorrowerId;
  final DateTime? loanDate;
  final DateTime? dueDate;
  final double? purchasePrice;
  final int? minAge;
  final String? description;

  GameModel({
    required this.gameId,
    required this.ownerId,
    required this.title,
    this.edition,
    required this.publisher,
    required this.year,
    required this.designers,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTime,
    required this.weight,
    this.bggId,
    this.bggRank,
    required this.mechanics,
    required this.categories,
    required this.tags,
    required this.coverImage,
    required this.thumbnailImage,
    required this.condition,
    required this.location,
    this.value,
    required this.visibility,
    required this.importSource,
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable = true,
    this.currentBorrowerId,
    this.loanDate,
    this.dueDate,
    this.purchasePrice,
    this.minAge,
    this.description,
  });

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GameModel(
      gameId: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      edition: data['edition'],
      publisher: data['publisher'] ?? '',
      year: data['year'] ?? 0,
      designers: List<String>.from(data['designers'] ?? []),
      minPlayers: data['minPlayers'] ?? 1,
      maxPlayers: data['maxPlayers'] ?? 4,
      playTime: data['playTime'] ?? 0,
      weight: (data['weight'] ?? 0).toDouble(),
      bggId: data['bggId'],
      bggRank: data['bggRank'],
      mechanics: List<String>.from(data['mechanics'] ?? []),
      categories: List<String>.from(data['categories'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      coverImage: data['coverImage'] ?? '',
      thumbnailImage: data['thumbnailImage'] ?? '',
      condition: GameCondition.values.firstWhere(
        (e) => e.toString().split('.').last == data['condition'],
        orElse: () => GameCondition.good,
      ),
      location: data['location'] ?? '',
      value: data['value']?.toDouble(),
      visibility: GameVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == data['visibility'],
        orElse: () => GameVisibility.friends,
      ),
      importSource: ImportSource.values.firstWhere(
        (e) => e.toString().split('.').last == data['importSource'],
        orElse: () => ImportSource.manual,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isAvailable: data['isAvailable'] ?? true,
      currentBorrowerId: data['currentBorrowerId'],
      loanDate: data['loanDate'] != null ? (data['loanDate'] as Timestamp).toDate() : null,
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      purchasePrice: data['purchasePrice']?.toDouble(),
      minAge: data['minAge'],
      description: data['description'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'title': title,
      'edition': edition,
      'publisher': publisher,
      'year': year,
      'designers': designers,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'playTime': playTime,
      'weight': weight,
      'bggId': bggId,
      'bggRank': bggRank,
      'mechanics': mechanics,
      'categories': categories,
      'tags': tags,
      'coverImage': coverImage,
      'thumbnailImage': thumbnailImage,
      'condition': condition.toString().split('.').last,
      'location': location,
      'value': value,
      'visibility': visibility.toString().split('.').last,
      'importSource': importSource.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isAvailable': isAvailable,
      'currentBorrowerId': currentBorrowerId,
      'loanDate': loanDate != null ? Timestamp.fromDate(loanDate!) : null,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'purchasePrice': purchasePrice,
      'minAge': minAge,
      'description': description,
    };
  }
  
  // JSON serialization for local storage
  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'ownerId': ownerId,
      'title': title,
      'edition': edition,
      'publisher': publisher,
      'year': year,
      'designers': designers,
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'playTime': playTime,
      'weight': weight,
      'bggId': bggId,
      'bggRank': bggRank,
      'mechanics': mechanics,
      'categories': categories,
      'tags': tags,
      'coverImage': coverImage,
      'thumbnailImage': thumbnailImage,
      'condition': condition.toString().split('.').last,
      'location': location,
      'value': value,
      'visibility': visibility.toString().split('.').last,
      'importSource': importSource.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isAvailable': isAvailable,
      'currentBorrowerId': currentBorrowerId,
      'loanDate': loanDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'purchasePrice': purchasePrice,
      'minAge': minAge,
      'description': description,
    };
  }
  
  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      gameId: json['gameId'],
      ownerId: json['ownerId'],
      title: json['title'],
      edition: json['edition'],
      publisher: json['publisher'],
      year: json['year'],
      designers: List<String>.from(json['designers']),
      minPlayers: json['minPlayers'],
      maxPlayers: json['maxPlayers'],
      playTime: json['playTime'],
      weight: json['weight'].toDouble(),
      bggId: json['bggId'],
      bggRank: json['bggRank'],
      mechanics: List<String>.from(json['mechanics']),
      categories: List<String>.from(json['categories']),
      tags: List<String>.from(json['tags']),
      coverImage: json['coverImage'],
      thumbnailImage: json['thumbnailImage'],
      condition: GameCondition.values.firstWhere(
        (e) => e.toString().split('.').last == json['condition'],
        orElse: () => GameCondition.good,
      ),
      location: json['location'],
      value: json['value']?.toDouble(),
      visibility: GameVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == json['visibility'],
        orElse: () => GameVisibility.friends,
      ),
      importSource: ImportSource.values.firstWhere(
        (e) => e.toString().split('.').last == json['importSource'],
        orElse: () => ImportSource.manual,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isAvailable: json['isAvailable'],
      currentBorrowerId: json['currentBorrowerId'],
      loanDate: json['loanDate'] != null ? DateTime.parse(json['loanDate']) : null,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      purchasePrice: json['purchasePrice']?.toDouble(),
      minAge: json['minAge'],
      description: json['description'],
    );
  }

  GameModel copyWith({
    String? gameId,
    String? ownerId,
    String? title,
    String? edition,
    String? publisher,
    int? year,
    List<String>? designers,
    int? minPlayers,
    int? maxPlayers,
    int? playTime,
    double? weight,
    int? bggId,
    int? bggRank,
    List<String>? mechanics,
    List<String>? categories,
    List<String>? tags,
    String? coverImage,
    String? thumbnailImage,
    GameCondition? condition,
    String? location,
    double? value,
    GameVisibility? visibility,
    ImportSource? importSource,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    String? currentBorrowerId,
    DateTime? loanDate,
    DateTime? dueDate,
    double? purchasePrice,
    int? minAge,
    String? description,
  }) {
    return GameModel(
      gameId: gameId ?? this.gameId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      edition: edition ?? this.edition,
      publisher: publisher ?? this.publisher,
      year: year ?? this.year,
      designers: designers ?? this.designers,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      playTime: playTime ?? this.playTime,
      weight: weight ?? this.weight,
      bggId: bggId ?? this.bggId,
      bggRank: bggRank ?? this.bggRank,
      mechanics: mechanics ?? this.mechanics,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      coverImage: coverImage ?? this.coverImage,
      thumbnailImage: thumbnailImage ?? this.thumbnailImage,
      condition: condition ?? this.condition,
      location: location ?? this.location,
      value: value ?? this.value,
      visibility: visibility ?? this.visibility,
      importSource: importSource ?? this.importSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      currentBorrowerId: currentBorrowerId ?? this.currentBorrowerId,
      loanDate: loanDate ?? this.loanDate,
      dueDate: dueDate ?? this.dueDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      minAge: minAge ?? this.minAge,
      description: description ?? this.description,
    );
  }
}