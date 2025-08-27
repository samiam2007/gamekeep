import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/bgg_api_service.dart';
import '../services/game_storage_service.dart';
import '../providers/game_provider.dart';
import '../models/game_model.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';

class BGGImportEnhancedScreen extends StatefulWidget {
  const BGGImportEnhancedScreen({Key? key}) : super(key: key);

  @override
  State<BGGImportEnhancedScreen> createState() => _BGGImportEnhancedScreenState();
}

class _BGGImportEnhancedScreenState extends State<BGGImportEnhancedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  
  // Collection data
  List<BGGCollectionItem> _ownedGames = [];
  List<BGGCollectionItem> _wishlistGames = [];
  Set<int> _selectedGameIds = {};
  
  // Recommendations
  List<BGGSearchResult> _recommendations = [];
  
  // Hot games
  List<BGGHotGame> _hotGames = [];
  
  // Helper method for responsive grid columns
  int _getResponsiveColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4; // Desktop
    if (width > 600) return 2;  // Tablet
    return 1;                    // Phone
  }
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHotGames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCollection() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your BGG username';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load owned games
      final ownedCollection = await BGGApiService.getCollection(
        username: _usernameController.text.trim(),
        own: true,
      );
      
      // Load wishlist
      final wishlistCollection = await BGGApiService.getCollection(
        username: _usernameController.text.trim(),
        wishlist: true,
      );

      setState(() {
        _ownedGames = ownedCollection;
        _wishlistGames = wishlistCollection;
        _isLoading = false;
      });

      // Load recommendations based on owned games
      if (_ownedGames.isNotEmpty) {
        _loadRecommendations();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading collection: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRecommendations() async {
    final ownedIds = _ownedGames.map((g) => g.gameId).toList();
    
    try {
      final recommendations = await BGGApiService.getRecommendations(
        gameIds: ownedIds,
        limit: 10,
      );
      
      setState(() {
        _recommendations = recommendations;
      });
    } catch (e) {
      print('Error loading recommendations: $e');
    }
  }

  Future<void> _loadHotGames() async {
    try {
      final hotGames = await BGGApiService.getHotGames();
      setState(() {
        _hotGames = hotGames.take(20).toList();
      });
    } catch (e) {
      print('Error loading hot games: $e');
    }
  }

  Future<void> _importSelectedGames() async {
    if (_selectedGameIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select games to import')),
      );
      return;
    }

    setState(() => _isLoading = true);

    int imported = 0;
    final List<GameModel> gamesToImport = [];
    
    for (final gameId in _selectedGameIds) {
      // Get full game details
      final details = await BGGApiService.getGameDetails(gameId: gameId);
      
      if (details != null) {
        final gameModel = BGGApiService.convertToGameModel(details, 'demo_user');
        gamesToImport.add(gameModel);
        imported++;
      }
      
      // Show progress
      if (mounted) {
        setState(() {
          _errorMessage = 'Importing... $imported/${_selectedGameIds.length}';
        });
      }
    }

    // Save all imported games to storage
    if (gamesToImport.isNotEmpty) {
      await GameStorageService.addImportedGames(gamesToImport);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $imported games!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true); // Return true to indicate games were imported
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Import from BoardGameGeek'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Collection'),
            Tab(text: 'Wishlist'),
            Tab(text: 'Discover'),
            Tab(text: 'Hot Games'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Username input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'BGG Username',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
                      filled: true,
                      fillColor: const Color(0xFF2A2A2A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _loadUserCollection,
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                  label: const Text('Load'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          
          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withOpacity(0.1),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCollectionTab(_ownedGames, 'owned'),
                _buildCollectionTab(_wishlistGames, 'wishlist'),
                _buildRecommendationsTab(),
                _buildHotGamesTab(),
              ],
            ),
          ),
          
          // Import button
          if (_selectedGameIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _importSelectedGames,
                  icon: const Icon(Icons.download),
                  label: Text('Import ${_selectedGameIds.length} Games'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCollectionTab(List<BGGCollectionItem> games, String type) {
    if (games.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'owned' ? Icons.inventory : Icons.favorite_border,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              type == 'owned' 
                ? 'No owned games found\nEnter your BGG username above'
                : 'No wishlist games found\nEnter your BGG username above',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getResponsiveColumns(context),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final isSelected = _selectedGameIds.contains(game.gameId);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedGameIds.remove(game.gameId);
              } else {
                _selectedGameIds.add(game.gameId);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Game image
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          color: Colors.grey[800],
                        ),
                        child: game.thumbnail != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                              child: CachedNetworkImage(
                                imageUrl: game.thumbnail!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                errorWidget: (context, url, error) => const Center(
                                  child: Icon(Icons.casino, color: Colors.grey),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.casino, color: Colors.grey),
                            ),
                      ),
                    ),
                    // Game info
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (game.yearPublished != null)
                            Text(
                              '${game.yearPublished}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          if (game.rating != null)
                            Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  game.rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Selection overlay
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                // Play count badge
                if (game.numPlays != null && game.numPlays! > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${game.numPlays} plays',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationsTab() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.recommend, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Load your collection to see recommendations',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        final rec = _recommendations[index];
        
        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.casino, color: Colors.grey),
            ),
            title: Text(
              rec.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rec.yearPublished != null)
                  Text(
                    'Year: ${rec.yearPublished}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                Text(
                  'Recommended based on your collection',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            trailing: IconButton(
              icon: _selectedGameIds.contains(rec.id)
                ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                : const Icon(Icons.add_circle_outline, color: Colors.grey),
              onPressed: () {
                setState(() {
                  if (_selectedGameIds.contains(rec.id)) {
                    _selectedGameIds.remove(rec.id);
                  } else {
                    _selectedGameIds.add(rec.id);
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHotGamesTab() {
    if (_hotGames.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hotGames.length,
      itemBuilder: (context, index) {
        final game = _hotGames[index];
        final isSelected = _selectedGameIds.contains(game.id);
        
        return Card(
          color: const Color(0xFF2A2A2A),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: index < 3
                  ? const LinearGradient(
                      colors: [Colors.amber, Colors.orange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
                color: index >= 3 ? Colors.grey[700] : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '#${game.rank}',
                  style: TextStyle(
                    color: index < 3 ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              game.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: game.yearPublished != null
              ? Text(
                  'Released ${game.yearPublished}',
                  style: TextStyle(color: Colors.grey[500]),
                )
              : null,
            trailing: IconButton(
              icon: isSelected
                ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                : const Icon(Icons.add_circle_outline, color: Colors.grey),
              onPressed: () {
                setState(() {
                  if (isSelected) {
                    _selectedGameIds.remove(game.id);
                  } else {
                    _selectedGameIds.add(game.id);
                  }
                });
              },
            ),
          ),
        );
      },
    );
  }
}