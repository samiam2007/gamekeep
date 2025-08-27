import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String email;
  final String displayName;
  final String? avatar;
  final UserSettings settings;
  final List<String> friends;
  final String? bggUsername;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatar,
    required this.settings,
    required this.friends,
    this.bggUsername,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      avatar: data['avatar'],
      settings: UserSettings.fromMap(data['settings'] ?? {}),
      friends: List<String>.from(data['friends'] ?? []),
      bggUsername: data['bggUsername'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'avatar': avatar,
      'settings': settings.toMap(),
      'friends': friends,
      'bggUsername': bggUsername,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  UserModel copyWith({
    String? userId,
    String? email,
    String? displayName,
    String? avatar,
    UserSettings? settings,
    List<String>? friends,
    String? bggUsername,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      settings: settings ?? this.settings,
      friends: friends ?? this.friends,
      bggUsername: bggUsername ?? this.bggUsername,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserSettings {
  final bool darkMode;
  final bool pushNotifications;
  final String defaultVisibility;
  final bool autoSync;
  final String language;

  UserSettings({
    this.darkMode = false,
    this.pushNotifications = true,
    this.defaultVisibility = 'friends',
    this.autoSync = true,
    this.language = 'en',
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      darkMode: map['darkMode'] ?? false,
      pushNotifications: map['pushNotifications'] ?? true,
      defaultVisibility: map['defaultVisibility'] ?? 'friends',
      autoSync: map['autoSync'] ?? true,
      language: map['language'] ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'darkMode': darkMode,
      'pushNotifications': pushNotifications,
      'defaultVisibility': defaultVisibility,
      'autoSync': autoSync,
      'language': language,
    };
  }
}