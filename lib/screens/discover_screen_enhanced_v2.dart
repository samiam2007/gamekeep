import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/bgg_api_service.dart';
import '../models/game_model.dart';
import '../services/game_storage_service.dart';
import '../widgets/navigation_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiscoverScreenEnhanced extends StatefulWidget {
  const DiscoverScreenEnhanced({Key? key}) : super(key: key);

  @override
  State<DiscoverScreenEnhanced> createState() => _DiscoverScreenEnhancedState();
}

class _DiscoverScreenEnhancedState extends State<DiscoverScreenEnhanced> {
  final TextEditingController _searchController = TextEditingController();
  List<BGGSearchResult> _searchResults = [];
  List<BGGSearchResult> _filteredSearchResults = [];
  List<BGGHotGame> _hotGames = [];
  List<BGGHotGame> _filteredHotGames = [];
  Map<int, BGGGameDetails> _gameDetailsCache = {};
  bool _isLoading = false;
  bool _isLoadingHot = true;
  bool _showFilters = false;
  
  // Filter values
  RangeValues _playerRange = const RangeValues(1, 10);
  RangeValues _timeRange = const RangeValues(15, 240);
  RangeValues _difficultyRange = const RangeValues(1, 5);
  RangeValues _ratingRange = const RangeValues(1, 10);
  
  // Selected mechanics/categories
  Set<String> _selectedMechanics = {};
  
  // Helper method for responsive grid columns
  int _getResponsiveColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4; // Desktop
    if (width > 600) return 2;  // Tablet
    return 1;                    // Phone
  }
  
  // Common mechanics and categories
  final List<String> _availableMechanics = [
    'Co-operative',
    'Deck Building',
    'Worker Placement',
    'Area Control',
    'Set Collection',
    'Hand Management',
    'Dice Rolling',
    'Card Drafting',
    'Engine Building',
    'Tile Placement',
    'Auction/Bidding',
    'Route Building',
    'Resource Management',
    'Pattern Building',
    'Push Your Luck',
    'Roll and Write',
    'Bluffing',
    'Deduction',
    'Trading',
    'Legacy',
  ];
  
  @override
  void initState() {
    super.initState();
    _loadHotGames();
  }
  
  Future<void> _loadHotGames() async {
    try {
      final hot = await BGGApiService.getHotGames();
      if (mounted) {
        setState(() {
          _hotGames = hot;
          _filteredHotGames = hot;
          _isLoadingHot = false;
        });
        // Preload details for hot games to get better images
        _preloadGameDetails(hot.map((g) => g.id).toList());
      }
    } catch (e) {
      print('Error loading hot games: $e');
      setState(() => _isLoadingHot = false);
    }
  }
  
  Future<void> _preloadGameDetails(List<int> gameIds) async {
    for (var id in gameIds.take(20)) { // Limit to first 20 to avoid too many requests
      if (!_gameDetailsCache.containsKey(id)) {
        try {
          final details = await BGGApiService.getGameDetails(gameId: id);
          if (details != null && mounted) {
            setState(() {
              _gameDetailsCache[id] = details;
            });
          }
        } catch (e) {
          print('Error loading details for game $id: $e');
        }
      }
    }
  }
  
  
  void _applyFilters() {
    setState(() {
      // Filter hot games
      _filteredHotGames = _hotGames.where((game) {
        final details = _gameDetailsCache[game.id];
        if (details == null) return true; // If we don't have details, show it
        
        // Check player count
        if (details.minPlayers > _playerRange.end.round() || 
            details.maxPlayers < _playerRange.start.round()) {
          return false;
        }
        
        // Check play time
        if (details.playingTime > 0) {
          if (details.playingTime < _timeRange.start.round() || 
              details.playingTime > _timeRange.end.round()) {
            return false;
          }
        }
        
        // Check difficulty/weight
        if (details.averageWeight > 0) {
          if (details.averageWeight < _difficultyRange.start || 
              details.averageWeight > _difficultyRange.end) {
            return false;
          }
        }
        
        // Check rating
        if (details.averageRating > 0) {
          if (details.averageRating < _ratingRange.start || 
              details.averageRating > _ratingRange.end) {
            return false;
          }
        }
        
        // Check mechanics
        if (_selectedMechanics.isNotEmpty) {
          bool hasMatchingMechanic = false;
          for (var mechanic in _selectedMechanics) {
            if (details.mechanics.any((m) => m.toLowerCase().contains(mechanic.toLowerCase())) ||
                details.categories.any((c) => c.toLowerCase().contains(mechanic.toLowerCase()))) {
              hasMatchingMechanic = true;
              break;
            }
          }
          if (!hasMatchingMechanic) return false;
        }
        
        return true;
      }).toList();
      
      // Filter search results similarly
      _filteredSearchResults = _searchResults.where((game) {
        final details = _gameDetailsCache[game.id];
        if (details == null) return true;
        
        // Apply same filters as above
        if (details.minPlayers > _playerRange.end.round() || 
            details.maxPlayers < _playerRange.start.round()) {
          return false;
        }
        
        if (details.playingTime > 0) {
          if (details.playingTime < _timeRange.start.round() || 
              details.playingTime > _timeRange.end.round()) {
            return false;
          }
        }
        
        if (details.averageWeight > 0) {
          if (details.averageWeight < _difficultyRange.start || 
              details.averageWeight > _difficultyRange.end) {
            return false;
          }
        }
        
        if (details.averageRating > 0) {
          if (details.averageRating < _ratingRange.start || 
              details.averageRating > _ratingRange.end) {
            return false;
          }
        }
        
        if (_selectedMechanics.isNotEmpty) {
          bool hasMatchingMechanic = false;
          for (var mechanic in _selectedMechanics) {
            if (details.mechanics.any((m) => m.toLowerCase().contains(mechanic.toLowerCase())) ||
                details.categories.any((c) => c.toLowerCase().contains(mechanic.toLowerCase()))) {
              hasMatchingMechanic = true;
              break;
            }
          }
          if (!hasMatchingMechanic) return false;
        }
        
        return true;
      }).toList();
    });
  }
  
  Future<void> _searchGames(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _searchResults = [];
      _filteredSearchResults = [];
    });
    
    try {
      final results = await BGGApiService.searchGames(
        query: query,
        exact: false,
      );
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _filteredSearchResults = results;
          _isLoading = false;
        });
        // Preload details for search results
        _preloadGameDetails(results.map((g) => g.id).toList());
        // Apply filters after loading
        _applyFilters();
      }
    } catch (e) {
      print('Search error: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _searchSimilarGames(String mechanicOrCategory) async {
    // Close the modal
    Navigator.pop(context);
    
    // Set the search term and trigger search
    _searchController.text = mechanicOrCategory;
    await _searchGames(mechanicOrCategory);
    
    // Also select the mechanic in filters if it matches
    if (_availableMechanics.any((m) => m.toLowerCase() == mechanicOrCategory.toLowerCase())) {
      setState(() {
        _selectedMechanics.add(mechanicOrCategory);
        _showFilters = true;
      });
      _applyFilters();
    }
  }
  
  Future<void> _importGame(int gameId) async {
    setState(() => _isLoading = true);
    
    try {
      final details = await BGGApiService.getGameDetails(gameId: gameId);
      if (details != null) {
        final gameModel = BGGApiService.convertToGameModel(details, 'demo_user');
        await GameStorageService.addImportedGames([gameModel]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${gameModel.title}" to your library!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      print('Import error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to import game'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _showGameDetails(int gameId) async {
    BGGGameDetails? details = _gameDetailsCache[gameId];
    
    if (details == null) {
      // Show loading state
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
      
      try {
        details = await BGGApiService.getGameDetails(gameId: gameId);
        Navigator.pop(context); // Close loading modal
        
        if (details != null) {
          _gameDetailsCache[gameId] = details;
        }
      } catch (e) {
        Navigator.pop(context); // Close loading modal
        print('Error loading game details: $e');
        return;
      }
    }
    
    if (details == null) return;
    
    final gameDetails = details; // Create non-nullable local variable
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppTheme.ironColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with image
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Game image
                          Container(
                            width: 120,
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: AppTheme.stoneColor,
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: gameDetails.image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: gameDetails.image,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.casino,
                                      color: AppTheme.primaryColor,
                                      size: 50,
                                    ),
                                  )
                                : const Icon(
                                    Icons.casino,
                                    color: AppTheme.primaryColor,
                                    size: 50,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gameDetails.primaryName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (gameDetails.yearPublished != null)
                                  Text(
                                    '${gameDetails.yearPublished}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (gameDetails.rank != null)
                                      _buildInfoChip(Icons.emoji_events, 'Rank #${gameDetails.rank}'),
                                    if (gameDetails.averageRating > 0)
                                      _buildInfoChip(Icons.star, gameDetails.averageRating.toStringAsFixed(1)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Game info grid
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.stoneColor.withOpacity(0.5),
                              AppTheme.stoneColor.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Players', '${gameDetails.minPlayers ?? '?'}-${gameDetails.maxPlayers ?? '?'}'),
                            Divider(color: AppTheme.primaryColor.withOpacity(0.3)),
                            _buildInfoRow('Play Time', '${gameDetails.playingTime > 0 ? gameDetails.playingTime : '?'} min'),
                            Divider(color: AppTheme.primaryColor.withOpacity(0.3)),
                            _buildInfoRow('Age', '${gameDetails.minAge ?? '?'}+'),
                            Divider(color: AppTheme.primaryColor.withOpacity(0.3)),
                            _buildInfoRow('Weight', gameDetails.averageWeight > 0 ? gameDetails.averageWeight.toStringAsFixed(1) : 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Description
                      if (gameDetails.description != null) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          gameDetails.description!,
                          style: TextStyle(
                            color: Colors.grey[300],
                            height: 1.5,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Mechanics - Clickable
                      if (gameDetails.mechanics.isNotEmpty) ...[
                        const Text(
                          'Mechanics',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: gameDetails.mechanics.map((m) => GestureDetector(
                            onTap: () => _searchSimilarGames(m),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.burgundyColor.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.burgundyColor.withOpacity(0.6),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    m,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Categories - Clickable
                      if (gameDetails.categories.isNotEmpty) ...[
                        const Text(
                          'Categories',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: gameDetails.categories.map((c) => GestureDetector(
                            onTap: () => _searchSimilarGames(c),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.stoneColor.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.stoneColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Import button - More prominent
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _importGame(gameId);
                          },
                          icon: const Icon(Icons.add, size: 24),
                          label: const Text(
                            'Add to Library',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
        // Custom header with search and filters
        Container(
          decoration: BoxDecoration(
            color: AppTheme.ironColor,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Title
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text(
                    'DISCOVER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                // Search bar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search BoardGameGeek...',
                            hintStyle: TextStyle(color: AppTheme.stoneColor),
                            fillColor: AppTheme.surfaceLight,
                            filled: true,
                            prefixIcon: Icon(Icons.search, color: AppTheme.stoneColor),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    color: AppTheme.stoneColor,
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchResults = [];
                                        _filteredSearchResults = [];
                                      });
                                    },
                                  ),
                                IconButton(
                                  icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
                                  color: AppTheme.primaryColor,
                                  onPressed: () => setState(() => _showFilters = !_showFilters),
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: _searchGames,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showFilters) _buildFilterPanel(),
              ],
            ),
          ),
        ),
        // Main content
        Expanded(
          child: _searchController.text.isEmpty && _searchResults.isEmpty
              ? _buildHotGames()
              : _buildSearchResults(),
        ),
        ],
      ),
    );
  }
  
  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(
          top: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player count
          Text('Players: ${_playerRange.start.round()}-${_playerRange.end.round()}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          RangeSlider(
            values: _playerRange,
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.stoneColor.withOpacity(0.3),
            onChanged: (values) {
              setState(() => _playerRange = values);
              _applyFilters();
            },
          ),
          
          // Play time
          Text('Play Time (minutes): ${_timeRange.start.round()}-${_timeRange.end.round()}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          RangeSlider(
            values: _timeRange,
            min: 15,
            max: 240,
            divisions: 15,
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.stoneColor.withOpacity(0.3),
            onChanged: (values) {
              setState(() => _timeRange = values);
              _applyFilters();
            },
          ),
          
          // Difficulty
          Text('Difficulty (Weight): ${_difficultyRange.start.toStringAsFixed(1)}-${_difficultyRange.end.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          RangeSlider(
            values: _difficultyRange,
            min: 1,
            max: 5,
            divisions: 8,
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.stoneColor.withOpacity(0.3),
            onChanged: (values) {
              setState(() => _difficultyRange = values);
              _applyFilters();
            },
          ),
          
          // BGG Rating
          Text('BGG Rating: ${_ratingRange.start.toStringAsFixed(1)}-${_ratingRange.end.toStringAsFixed(1)}',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          RangeSlider(
            values: _ratingRange,
            min: 1,
            max: 10,
            divisions: 18,
            activeColor: AppTheme.primaryColor,
            inactiveColor: AppTheme.stoneColor.withOpacity(0.3),
            onChanged: (values) {
              setState(() => _ratingRange = values);
              _applyFilters();
            },
          ),
          
          // Mechanics & Categories
          const SizedBox(height: 8),
          const Text('Mechanics & Categories:',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _availableMechanics.map((mechanic) {
                final isSelected = _selectedMechanics.contains(mechanic);
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedMechanics.remove(mechanic);
                          } else {
                            _selectedMechanics.add(mechanic);
                          }
                        });
                        _applyFilters();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppTheme.primaryColor 
                              : AppTheme.stoneColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? AppTheme.primaryColor 
                                : AppTheme.stoneColor.withOpacity(0.7),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            Text(
                              mechanic,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHotGames() {
    if (_isLoadingHot) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getResponsiveColumns(context),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: 8,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: AppTheme.stoneColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
    
    final gamesToShow = _filteredHotGames.isEmpty && _selectedMechanics.isEmpty 
        ? _hotGames 
        : _filteredHotGames;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRENDING NOW',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              if (_filteredHotGames.length != _hotGames.length)
                Text(
                  '${_filteredHotGames.length} of ${_hotGames.length} games',
                  style: TextStyle(
                    color: AppTheme.stoneColor,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: gamesToShow.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_off, size: 64, color: AppTheme.stoneColor),
                      const SizedBox(height: 16),
                      Text(
                        'No games match your filters',
                        style: TextStyle(color: AppTheme.stoneColor, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _playerRange = const RangeValues(1, 10);
                            _timeRange = const RangeValues(15, 240);
                            _difficultyRange = const RangeValues(1, 5);
                            _ratingRange = const RangeValues(1, 10);
                            _selectedMechanics.clear();
                            _filteredHotGames = _hotGames;
                          });
                        },
                        child: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getResponsiveColumns(context),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: gamesToShow.length,
                  itemBuilder: (context, index) => _buildGameCard(gamesToShow[index]),
                ),
        ),
      ],
    );
  }
  
  Widget _buildGameCard(BGGHotGame game) {
    final details = _gameDetailsCache[game.id];
    final imageUrl = details?.image ?? details?.thumbnail ?? game.thumbnail;
    
    return GestureDetector(
      onTap: () => _showGameDetails(game.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.ironColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Game image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.stoneColor.withOpacity(0.3),
                      AppTheme.stoneColor.withOpacity(0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.stoneColor.withOpacity(0.3),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.stoneColor.withOpacity(0.3),
                          child: const Icon(
                            Icons.casino,
                            color: AppTheme.primaryColor,
                            size: 30,
                          ),
                        ),
                      )
                    : Container(
                        color: AppTheme.stoneColor.withOpacity(0.3),
                        child: const Icon(
                          Icons.casino,
                          color: AppTheme.primaryColor,
                          size: 30,
                        ),
                      ),
                ),
              ),
            ),
            
            // Game info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${game.rank}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (game.yearPublished != null)
                          Text(
                            '${game.yearPublished}',
                            style: TextStyle(
                              color: AppTheme.stoneColor,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppTheme.stoneColor),
            const SizedBox(height: 16),
            Text(
              'No games found',
              style: TextStyle(color: AppTheme.stoneColor, fontSize: 18),
            ),
          ],
        ),
      );
    }
    
    final gamesToShow = _filteredSearchResults.isEmpty && _selectedMechanics.isEmpty 
        ? _searchResults 
        : _filteredSearchResults;
    
    if (gamesToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 64, color: AppTheme.stoneColor),
            const SizedBox(height: 16),
            Text(
              'No games match your filters',
              style: TextStyle(color: AppTheme.stoneColor, fontSize: 18),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _playerRange = const RangeValues(1, 10);
                  _timeRange = const RangeValues(15, 240);
                  _difficultyRange = const RangeValues(1, 5);
                  _ratingRange = const RangeValues(1, 10);
                  _selectedMechanics.clear();
                  _filteredSearchResults = _searchResults;
                });
              },
              child: const Text('Clear Filters'),
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
        childAspectRatio: 0.75,
      ),
      itemCount: gamesToShow.length,
      itemBuilder: (context, index) {
        final game = gamesToShow[index];
        final details = _gameDetailsCache[game.id];
        final imageUrl = details?.image ?? details?.thumbnail;
        
        return GestureDetector(
          onTap: () => _showGameDetails(game.id),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.ironColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.stoneColor.withOpacity(0.3),
                          AppTheme.stoneColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.stoneColor.withOpacity(0.3),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppTheme.stoneColor.withOpacity(0.3),
                              child: const Icon(
                                Icons.casino,
                                color: AppTheme.primaryColor,
                                size: 30,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.stoneColor.withOpacity(0.3),
                            child: const Icon(
                              Icons.casino,
                              color: AppTheme.primaryColor,
                              size: 30,
                            ),
                          ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          game.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (game.yearPublished != null)
                          Text(
                            '${game.yearPublished}',
                            style: TextStyle(
                              color: AppTheme.stoneColor,
                              fontSize: 10,
                            ),
                          ),
                      ],
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
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}