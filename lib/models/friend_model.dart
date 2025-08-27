import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendStatus { pending, accepted, blocked }
enum RequestType { sent, received }

class FriendModel {
  final String friendId;
  final String userId;
  final String friendUserId;
  final String friendName;
  final String friendEmail;
  final String? friendAvatar;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final int sharedGamesCount;
  final int borrowedGamesCount;
  final int lentGamesCount;
  
  FriendModel({
    required this.friendId,
    required this.userId,
    required this.friendUserId,
    required this.friendName,
    required this.friendEmail,
    this.friendAvatar,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.sharedGamesCount = 0,
    this.borrowedGamesCount = 0,
    this.lentGamesCount = 0,
  });
  
  factory FriendModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FriendModel(
      friendId: doc.id,
      userId: data['userId'],
      friendUserId: data['friendUserId'],
      friendName: data['friendName'],
      friendEmail: data['friendEmail'],
      friendAvatar: data['friendAvatar'],
      status: FriendStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => FriendStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null 
          ? (data['acceptedAt'] as Timestamp).toDate() 
          : null,
      sharedGamesCount: data['sharedGamesCount'] ?? 0,
      borrowedGamesCount: data['borrowedGamesCount'] ?? 0,
      lentGamesCount: data['lentGamesCount'] ?? 0,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'friendUserId': friendUserId,
      'friendName': friendName,
      'friendEmail': friendEmail,
      'friendAvatar': friendAvatar,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'sharedGamesCount': sharedGamesCount,
      'borrowedGamesCount': borrowedGamesCount,
      'lentGamesCount': lentGamesCount,
    };
  }
  
  Map<String, dynamic> toJson() {
    return {
      'friendId': friendId,
      'userId': userId,
      'friendUserId': friendUserId,
      'friendName': friendName,
      'friendEmail': friendEmail,
      'friendAvatar': friendAvatar,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'sharedGamesCount': sharedGamesCount,
      'borrowedGamesCount': borrowedGamesCount,
      'lentGamesCount': lentGamesCount,
    };
  }
  
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      friendId: json['friendId'],
      userId: json['userId'],
      friendUserId: json['friendUserId'],
      friendName: json['friendName'],
      friendEmail: json['friendEmail'],
      friendAvatar: json['friendAvatar'],
      status: FriendStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => FriendStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      acceptedAt: json['acceptedAt'] != null 
          ? DateTime.parse(json['acceptedAt']) 
          : null,
      sharedGamesCount: json['sharedGamesCount'] ?? 0,
      borrowedGamesCount: json['borrowedGamesCount'] ?? 0,
      lentGamesCount: json['lentGamesCount'] ?? 0,
    );
  }
  
  FriendModel copyWith({
    String? friendId,
    String? userId,
    String? friendUserId,
    String? friendName,
    String? friendEmail,
    String? friendAvatar,
    FriendStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    int? sharedGamesCount,
    int? borrowedGamesCount,
    int? lentGamesCount,
  }) {
    return FriendModel(
      friendId: friendId ?? this.friendId,
      userId: userId ?? this.userId,
      friendUserId: friendUserId ?? this.friendUserId,
      friendName: friendName ?? this.friendName,
      friendEmail: friendEmail ?? this.friendEmail,
      friendAvatar: friendAvatar ?? this.friendAvatar,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      sharedGamesCount: sharedGamesCount ?? this.sharedGamesCount,
      borrowedGamesCount: borrowedGamesCount ?? this.borrowedGamesCount,
      lentGamesCount: lentGamesCount ?? this.lentGamesCount,
    );
  }
}

class LoanModel {
  final String loanId;
  final String gameId;
  final String gameTitle;
  final String lenderId;
  final String lenderName;
  final String borrowerId;
  final String borrowerName;
  final DateTime loanDate;
  final DateTime? dueDate;
  final DateTime? returnDate;
  final String? notes;
  final LoanStatus status;
  
  LoanModel({
    required this.loanId,
    required this.gameId,
    required this.gameTitle,
    required this.lenderId,
    required this.lenderName,
    required this.borrowerId,
    required this.borrowerName,
    required this.loanDate,
    this.dueDate,
    this.returnDate,
    this.notes,
    required this.status,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'loanId': loanId,
      'gameId': gameId,
      'gameTitle': gameTitle,
      'lenderId': lenderId,
      'lenderName': lenderName,
      'borrowerId': borrowerId,
      'borrowerName': borrowerName,
      'loanDate': loanDate.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'notes': notes,
      'status': status.toString().split('.').last,
    };
  }
  
  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      loanId: json['loanId'],
      gameId: json['gameId'],
      gameTitle: json['gameTitle'],
      lenderId: json['lenderId'],
      lenderName: json['lenderName'],
      borrowerId: json['borrowerId'],
      borrowerName: json['borrowerName'],
      loanDate: DateTime.parse(json['loanDate']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      returnDate: json['returnDate'] != null ? DateTime.parse(json['returnDate']) : null,
      notes: json['notes'],
      status: LoanStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => LoanStatus.active,
      ),
    );
  }
}

enum LoanStatus { active, overdue, returned, lost }