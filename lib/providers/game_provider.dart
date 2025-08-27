import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_model.dart';
import '../models/play_model.dart';
import '../models/loan_model.dart';
import '../services/bgg_service.dart';
import 'package:image/image.dart' as img;

class GameProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BGGService _bggService = BGGService();

  List<GameModel> _games = [];
  List<PlayModel> _plays = [];
  List<LoanModel> _loans = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<GameModel> get games => _games;
  List<PlayModel> get plays => _plays;
  List<LoanModel> get loans => _loans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Statistics
  int get totalGames => _games.length;
  int get availableGames => _games.where((g) => g.isAvailable).length;
  int get loanedGames => _games.where((g) => !g.isAvailable).length;
  int get totalPlays => _plays.length;

  // Load user's games
  Future<void> loadUserGames() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('games')
          .where('ownerId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      _games = snapshot.docs.map((doc) => GameModel.fromFirestore(doc)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load games: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new game
  Future<void> addGame(GameModel game, File? imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Update owner ID
      game = game.copyWith(ownerId: user.uid);

      // Upload image if provided
      if (imageFile != null) {
        final imageUrls = await _uploadGameImage(imageFile, game.gameId);
        game = game.copyWith(
          coverImage: imageUrls['full']!,
          thumbnailImage: imageUrls['thumbnail']!,
        );
      }

      // Add to Firestore
      await _firestore.collection('games').doc(game.gameId).set(game.toFirestore());

      // Add to local list
      _games.insert(0, game);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to add game: $e');
    }
  }

  // Update game
  Future<void> updateGame(GameModel game) async {
    try {
      game = game.copyWith(updatedAt: DateTime.now());
      await _firestore.collection('games').doc(game.gameId).update(game.toFirestore());

      final index = _games.indexWhere((g) => g.gameId == game.gameId);
      if (index != -1) {
        _games[index] = game;
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to update game: $e');
    }
  }

  // Delete game
  Future<void> deleteGame(String gameId) async {
    try {
      await _firestore.collection('games').doc(gameId).delete();
      _games.removeWhere((g) => g.gameId == gameId);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to delete game: $e');
    }
  }

  // Import games from BGG
  Future<void> importFromBGG(String username) async {
    if (username.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final collection = await _bggService.getUserCollection(username);
      int imported = 0;

      for (var bggGame in collection) {
        // Check if game already exists
        final existing = _games.any((g) => g.bggId == bggGame['bggId']);
        if (existing) continue;

        // Get full game details
        final details = await _bggService.getGameDetails(bggGame['bggId']);
        if (details == null) continue;

        // Create game model
        final game = GameModel(
          gameId: DateTime.now().millisecondsSinceEpoch.toString(),
          ownerId: _auth.currentUser!.uid,
          title: details['title'],
          publisher: details['publisher'] ?? '',
          year: details['year'],
          designers: List<String>.from(details['designers'] ?? []),
          minPlayers: details['minPlayers'],
          maxPlayers: details['maxPlayers'],
          playTime: details['playTime'],
          weight: details['weight'].toDouble(),
          bggId: bggGame['bggId'],
          bggRank: details['rank'],
          mechanics: List<String>.from(details['mechanics'] ?? []),
          categories: List<String>.from(details['categories'] ?? []),
          tags: [],
          coverImage: details['image'] ?? '',
          thumbnailImage: details['thumbnail'] ?? '',
          condition: GameCondition.good,
          location: 'Main Shelf',
          visibility: GameVisibility.friends,
          importSource: ImportSource.bgg,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await addGame(game, null);
        imported++;

        // Update progress
        notifyListeners();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to import from BGG: $e';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Log a play
  Future<void> logPlay(PlayModel play) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      play = play.copyWith(ownerId: user.uid);
      await _firestore.collection('plays').doc(play.playId).set(play.toFirestore());
      _plays.add(play);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to log play: $e');
    }
  }

  // Create loan request
  Future<void> createLoan(LoanModel loan) async {
    try {
      await _firestore.collection('loans').doc(loan.loanId).set(loan.toFirestore());
      
      // Update game availability
      final gameIndex = _games.indexWhere((g) => g.gameId == loan.gameId);
      if (gameIndex != -1) {
        _games[gameIndex] = _games[gameIndex].copyWith(
          isAvailable: false,
          currentBorrowerId: loan.borrowerId,
        );
      }

      _loans.add(loan);
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to create loan: $e');
    }
  }

  // Return loaned game
  Future<void> returnLoan(String loanId, List<String> checkinPhotos) async {
    try {
      final loan = _loans.firstWhere((l) => l.loanId == loanId);
      final updatedLoan = loan.copyWith(
        status: LoanStatus.returned,
        returnDate: DateTime.now(),
        checkinPhotos: checkinPhotos,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('loans').doc(loanId).update(updatedLoan.toFirestore());

      // Update game availability
      final gameIndex = _games.indexWhere((g) => g.gameId == loan.gameId);
      if (gameIndex != -1) {
        _games[gameIndex] = _games[gameIndex].copyWith(
          isAvailable: true,
          currentBorrowerId: null,
        );
      }

      final loanIndex = _loans.indexWhere((l) => l.loanId == loanId);
      if (loanIndex != -1) {
        _loans[loanIndex] = updatedLoan;
      }

      notifyListeners();
    } catch (e) {
      throw Exception('Failed to return loan: $e');
    }
  }

  // Upload game image
  Future<Map<String, String>> _uploadGameImage(File imageFile, String gameId) async {
    try {
      // Read and process image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Create thumbnail
      final thumbnail = img.copyResize(image, width: 200);
      
      // Upload full image
      final fullRef = _storage.ref().child('games/$gameId/cover.jpg');
      await fullRef.putData(img.encodeJpg(image));
      final fullUrl = await fullRef.getDownloadURL();

      // Upload thumbnail
      final thumbRef = _storage.ref().child('games/$gameId/thumbnail.jpg');
      await thumbRef.putData(img.encodeJpg(thumbnail));
      final thumbUrl = await thumbRef.getDownloadURL();

      return {
        'full': fullUrl,
        'thumbnail': thumbUrl,
      };
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Search games
  List<GameModel> searchGames(String query) {
    if (query.isEmpty) return _games;

    final lowercaseQuery = query.toLowerCase();
    return _games.where((game) {
      return game.title.toLowerCase().contains(lowercaseQuery) ||
          game.publisher.toLowerCase().contains(lowercaseQuery) ||
          game.designers.any((d) => d.toLowerCase().contains(lowercaseQuery)) ||
          game.categories.any((c) => c.toLowerCase().contains(lowercaseQuery)) ||
          game.mechanics.any((m) => m.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Filter games
  List<GameModel> filterGames({
    int? minPlayers,
    int? maxPlayers,
    int? maxPlayTime,
    double? maxWeight,
    List<String>? categories,
    List<String>? mechanics,
    bool? isAvailable,
  }) {
    return _games.where((game) {
      if (minPlayers != null && game.maxPlayers < minPlayers) return false;
      if (maxPlayers != null && game.minPlayers > maxPlayers) return false;
      if (maxPlayTime != null && game.playTime > maxPlayTime) return false;
      if (maxWeight != null && game.weight > maxWeight) return false;
      if (categories != null && categories.isNotEmpty &&
          !categories.any((c) => game.categories.contains(c))) return false;
      if (mechanics != null && mechanics.isNotEmpty &&
          !mechanics.any((m) => game.mechanics.contains(m))) return false;
      if (isAvailable != null && game.isAvailable != isAvailable) return false;
      return true;
    }).toList();
  }
}