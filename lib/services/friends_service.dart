import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/friend_model.dart';
import '../models/game_model.dart';
import 'storage_service.dart';

class FriendsService {
  static const String _friendsKey = 'gamekeep_friends_list';
  static const String _loansKey = 'gamekeep_loans';
  static const String _requestsKey = 'gamekeep_friend_requests';
  
  late SharedPreferences _prefs;
  late StorageService _storageService;
  static FriendsService? _instance;
  
  static Future<FriendsService> getInstance() async {
    if (_instance == null) {
      _instance = FriendsService._();
      await _instance!._init();
    }
    return _instance!;
  }
  
  FriendsService._();
  
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _storageService = await StorageService.getInstance();
  }
  
  // ============ FRIENDS MANAGEMENT ============
  
  /// Get all friends
  Future<List<FriendModel>> getFriends({FriendStatus? status}) async {
    try {
      final String? data = _prefs.getString(_friendsKey);
      if (data == null) return _getDemoFriends();
      
      final List<dynamic> friendsJson = json.decode(data);
      final friends = friendsJson
          .map((json) => FriendModel.fromJson(json))
          .toList();
      
      if (status != null) {
        return friends.where((f) => f.status == status).toList();
      }
      
      return friends;
    } catch (e) {
      print('Error loading friends: $e');
      return _getDemoFriends();
    }
  }
  
  /// Add a friend
  Future<bool> addFriend(FriendModel friend) async {
    try {
      final friends = await getFriends();
      
      // Check if friend already exists
      final exists = friends.any((f) => 
          f.friendUserId == friend.friendUserId || 
          f.friendEmail == friend.friendEmail
      );
      
      if (exists) return false;
      
      friends.add(friend);
      
      final String data = json.encode(
        friends.map((f) => f.toJson()).toList()
      );
      return await _prefs.setString(_friendsKey, data);
    } catch (e) {
      print('Error adding friend: $e');
      return false;
    }
  }
  
  /// Remove a friend
  Future<bool> removeFriend(String friendId) async {
    try {
      final friends = await getFriends();
      friends.removeWhere((f) => f.friendId == friendId);
      
      final String data = json.encode(
        friends.map((f) => f.toJson()).toList()
      );
      return await _prefs.setString(_friendsKey, data);
    } catch (e) {
      print('Error removing friend: $e');
      return false;
    }
  }
  
  /// Update friend status
  Future<bool> updateFriendStatus(String friendId, FriendStatus status) async {
    try {
      final friends = await getFriends();
      final index = friends.indexWhere((f) => f.friendId == friendId);
      
      if (index >= 0) {
        friends[index] = friends[index].copyWith(
          status: status,
          acceptedAt: status == FriendStatus.accepted ? DateTime.now() : null,
        );
        
        final String data = json.encode(
          friends.map((f) => f.toJson()).toList()
        );
        return await _prefs.setString(_friendsKey, data);
      }
      
      return false;
    } catch (e) {
      print('Error updating friend status: $e');
      return false;
    }
  }
  
  // ============ LENDING SYSTEM ============
  
  /// Create a new loan
  Future<bool> lendGame({
    required String gameId,
    required String borrowerId,
    DateTime? dueDate,
    String? notes,
  }) async {
    try {
      // Get game details
      final games = await _storageService.loadGames();
      final game = games.firstWhere((g) => g.gameId == gameId);
      
      // Get friend details
      final friends = await getFriends();
      final friend = friends.firstWhere((f) => f.friendUserId == borrowerId);
      
      // Create loan record
      final loan = LoanModel(
        loanId: 'loan_${DateTime.now().millisecondsSinceEpoch}',
        gameId: gameId,
        gameTitle: game.title,
        lenderId: 'demo_user',
        lenderName: 'You',
        borrowerId: borrowerId,
        borrowerName: friend.friendName,
        loanDate: DateTime.now(),
        dueDate: dueDate,
        notes: notes,
        status: LoanStatus.active,
      );
      
      // Save loan
      final loans = await getLoans();
      loans.add(loan);
      
      final String data = json.encode(
        loans.map((l) => l.toJson()).toList()
      );
      await _prefs.setString(_loansKey, data);
      
      // Update game availability
      await _storageService.loanGame(gameId, borrowerId, dueDate ?? DateTime.now().add(const Duration(days: 14)));
      
      // Update friend stats
      final updatedFriend = friend.copyWith(
        borrowedGamesCount: friend.borrowedGamesCount + 1,
      );
      await _updateFriend(updatedFriend);
      
      return true;
    } catch (e) {
      print('Error lending game: $e');
      return false;
    }
  }
  
  /// Return a loaned game
  Future<bool> returnGame(String loanId) async {
    try {
      final loans = await getLoans();
      final loanIndex = loans.indexWhere((l) => l.loanId == loanId);
      
      if (loanIndex >= 0) {
        final loan = loans[loanIndex];
        
        // Update loan status
        loans[loanIndex] = LoanModel(
          loanId: loan.loanId,
          gameId: loan.gameId,
          gameTitle: loan.gameTitle,
          lenderId: loan.lenderId,
          lenderName: loan.lenderName,
          borrowerId: loan.borrowerId,
          borrowerName: loan.borrowerName,
          loanDate: loan.loanDate,
          dueDate: loan.dueDate,
          returnDate: DateTime.now(),
          notes: loan.notes,
          status: LoanStatus.returned,
        );
        
        final String data = json.encode(
          loans.map((l) => l.toJson()).toList()
        );
        await _prefs.setString(_loansKey, data);
        
        // Update game availability
        await _storageService.returnGame(loan.gameId);
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error returning game: $e');
      return false;
    }
  }
  
  /// Get all loans
  Future<List<LoanModel>> getLoans({LoanStatus? status}) async {
    try {
      final String? data = _prefs.getString(_loansKey);
      if (data == null) return [];
      
      final List<dynamic> loansJson = json.decode(data);
      final loans = loansJson
          .map((json) => LoanModel.fromJson(json))
          .toList();
      
      // Update overdue status
      final now = DateTime.now();
      for (var loan in loans) {
        if (loan.status == LoanStatus.active && 
            loan.dueDate != null && 
            loan.dueDate!.isBefore(now)) {
          loan = LoanModel(
            loanId: loan.loanId,
            gameId: loan.gameId,
            gameTitle: loan.gameTitle,
            lenderId: loan.lenderId,
            lenderName: loan.lenderName,
            borrowerId: loan.borrowerId,
            borrowerName: loan.borrowerName,
            loanDate: loan.loanDate,
            dueDate: loan.dueDate,
            returnDate: loan.returnDate,
            notes: loan.notes,
            status: LoanStatus.overdue,
          );
        }
      }
      
      if (status != null) {
        return loans.where((l) => l.status == status).toList();
      }
      
      return loans;
    } catch (e) {
      print('Error loading loans: $e');
      return [];
    }
  }
  
  /// Get loans for a specific friend
  Future<List<LoanModel>> getLoansForFriend(String friendId) async {
    final loans = await getLoans();
    return loans.where((l) => l.borrowerId == friendId).toList();
  }
  
  // ============ FRIEND REQUESTS ============
  
  /// Send friend request
  Future<bool> sendFriendRequest(String email, String name) async {
    try {
      final friend = FriendModel(
        friendId: 'friend_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'demo_user',
        friendUserId: 'pending_$email',
        friendName: name,
        friendEmail: email,
        status: FriendStatus.pending,
        createdAt: DateTime.now(),
      );
      
      return await addFriend(friend);
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }
  
  /// Accept friend request
  Future<bool> acceptFriendRequest(String friendId) async {
    return await updateFriendStatus(friendId, FriendStatus.accepted);
  }
  
  /// Decline friend request
  Future<bool> declineFriendRequest(String friendId) async {
    return await removeFriend(friendId);
  }
  
  // ============ COLLECTION SHARING ============
  
  /// Get games shared with a friend
  Future<List<GameModel>> getSharedGames(String friendId) async {
    final games = await _storageService.loadGames();
    // In a real app, this would filter based on sharing permissions
    return games.where((g) => 
      g.visibility == GameVisibility.friends || 
      g.visibility == GameVisibility.public
    ).toList();
  }
  
  /// Get friend's collection (demo)
  Future<List<GameModel>> getFriendCollection(String friendId) async {
    // In a real app, this would fetch from the friend's shared collection
    // For demo, return some sample games
    return [
      GameModel(
        gameId: 'friend_game_1',
        ownerId: friendId,
        title: 'Ticket to Ride',
        publisher: 'Days of Wonder',
        year: 2004,
        designers: ['Alan R. Moon'],
        minPlayers: 2,
        maxPlayers: 5,
        playTime: 60,
        weight: 1.9,
        bggId: 9209,
        mechanics: ['Route Building'],
        categories: ['Trains'],
        tags: ['gateway'],
        coverImage: 'https://cf.geekdo-images.com/ZWJg0dCdrWHxVnc0eFXK8w__imagepage/img/KKp4ymhMRFWTfRaX8bODKwEoGk4=/fit-in/900x600/filters:no_upscale():strip_icc()/pic38668.jpg',
        thumbnailImage: 'https://cf.geekdo-images.com/ZWJg0dCdrWHxVnc0eFXK8w__thumb/img/o6L1g5dE4cM44lrTkJ1HxKJjK1c=/fit-in/200x150/filters:strip_icc()/pic38668.jpg',
        condition: GameCondition.good,
        location: "Friend's Collection",
        visibility: GameVisibility.friends,
        importSource: ImportSource.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      GameModel(
        gameId: 'friend_game_2',
        ownerId: friendId,
        title: 'Pandemic',
        publisher: 'Z-Man Games',
        year: 2008,
        designers: ['Matt Leacock'],
        minPlayers: 2,
        maxPlayers: 4,
        playTime: 45,
        weight: 2.4,
        bggId: 30549,
        mechanics: ['Cooperative'],
        categories: ['Medical'],
        tags: ['cooperative'],
        coverImage: 'https://cf.geekdo-images.com/S3ybV1LAp-8SnHIXLLjVIA__imagepage/img/g8ha1j-_pFxEasnNLnDAcNc_mOs=/fit-in/900x600/filters:no_upscale():strip_icc()/pic1534148.jpg',
        thumbnailImage: 'https://cf.geekdo-images.com/S3ybV1LAp-8SnHIXLLjVIA__thumb/img/EdkAyiKPTOtNK_AVA93Sm9YhINM=/fit-in/200x150/filters:strip_icc()/pic1534148.jpg',
        condition: GameCondition.mint,
        location: "Friend's Collection",
        visibility: GameVisibility.friends,
        importSource: ImportSource.manual,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  // ============ HELPERS ============
  
  Future<bool> _updateFriend(FriendModel friend) async {
    final friends = await getFriends();
    final index = friends.indexWhere((f) => f.friendId == friend.friendId);
    
    if (index >= 0) {
      friends[index] = friend;
      final String data = json.encode(
        friends.map((f) => f.toJson()).toList()
      );
      return await _prefs.setString(_friendsKey, data);
    }
    
    return false;
  }
  
  /// Demo friends for testing
  List<FriendModel> _getDemoFriends() {
    return [
      FriendModel(
        friendId: 'friend_1',
        userId: 'demo_user',
        friendUserId: 'alex_123',
        friendName: 'Alex Thompson',
        friendEmail: 'alex@example.com',
        friendAvatar: '👨‍💼',
        status: FriendStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        acceptedAt: DateTime.now().subtract(const Duration(days: 29)),
        sharedGamesCount: 15,
        borrowedGamesCount: 2,
        lentGamesCount: 1,
      ),
      FriendModel(
        friendId: 'friend_2',
        userId: 'demo_user',
        friendUserId: 'sarah_456',
        friendName: 'Sarah Chen',
        friendEmail: 'sarah@example.com',
        friendAvatar: '👩‍🔬',
        status: FriendStatus.accepted,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        acceptedAt: DateTime.now().subtract(const Duration(days: 19)),
        sharedGamesCount: 8,
        borrowedGamesCount: 0,
        lentGamesCount: 3,
      ),
      FriendModel(
        friendId: 'friend_3',
        userId: 'demo_user',
        friendUserId: 'mike_789',
        friendName: 'Mike Johnson',
        friendEmail: 'mike@example.com',
        friendAvatar: '👨‍🎮',
        status: FriendStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        sharedGamesCount: 0,
        borrowedGamesCount: 0,
        lentGamesCount: 0,
      ),
    ];
  }
}