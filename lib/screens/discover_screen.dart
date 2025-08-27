import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/bgg_api_service.dart';
import '../models/game_model.dart';
import '../services/game_storage_service.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/navigation_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BGGSearchResult> _searchResults = [];
  List<BGGHotGame> _hotGames = [];
  bool _isLoading = false;
  bool _isLoadingHot = true;
  String _searchType = 'boardgame';
  
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
          _isLoadingHot = false;
        });
      }
    } catch (e) {
      print('Error loading hot games: $e');
      setState(() => _isLoadingHot = false);
    }
  }
  
  Future<void> _searchGames(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _searchResults = [];
    });
    
    try {
      final results = await BGGApiService.searchGames(
        query: query,
        exact: false,
      );
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
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
              backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          title: const Text(
            'DISCOVER',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search BoardGameGeek...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  fillColor: const Color(0xFF2A2A2A),
                  filled: true,
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchResults = []);
                        },
                      )
                    : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _searchGames,
              ),
            ),
          ),
        ),
        body: _searchController.text.isEmpty && _searchResults.isEmpty
          ? _buildHotGames()
          : _buildSearchResults(),
      ),
    );
  }
  
  Widget _buildHotGames() {
    if (_isLoadingHot) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[800]?.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'TRENDING NOW',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ..._hotGames.map((game) => _buildHotGameCard(game)),
      ],
    );
  }
  
  Widget _buildHotGameCard(BGGHotGame game) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.primaryColor.withOpacity(0.1),
          ),
          child: game.thumbnail != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: game.thumbnail!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.casino,
                    color: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                ),
              )
            : Icon(
                Icons.casino,
                color: AppTheme.primaryColor.withOpacity(0.5),
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
              'Rank #${game.rank} • Year ${game.yearPublished}',
              style: TextStyle(color: Colors.grey[500]),
            )
          : Text(
              'Rank #${game.rank}',
              style: TextStyle(color: Colors.grey[500]),
            ),
        trailing: IconButton(
          onPressed: () => _importGame(game.id),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
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
            Icon(Icons.search_off, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'No games found',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final game = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.2),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              game.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: game.yearPublished != null
              ? Text(
                  'Year: ${game.yearPublished}',
                  style: TextStyle(color: Colors.grey[500]),
                )
              : null,
            trailing: IconButton(
              onPressed: () => _importGame(game.id),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
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