import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart'; // Disabled for demo
import '../providers/game_provider.dart';
import '../models/game_model.dart';
import '../widgets/game_card.dart';
import '../widgets/animated_game_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/native_ad_widget.dart';
import '../utils/theme.dart';
import 'game_detail_screen.dart';
import 'camera_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  String _sortBy = 'title';
  String _filterBy = 'all';
  // late BannerAd _bannerAd;
  bool _isBannerAdReady = false;
  
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
    // _initBannerAd(); // Disabled for demo
    _loadGames();
  }

  // void _initBannerAd() {
  //   _bannerAd = BannerAd(
  //     adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ad unit
  //     request: const AdRequest(),
  //     size: AdSize.banner,
  //     listener: BannerAdListener(
  //       onAdLoaded: (_) {
  //         setState(() {
  //           _isBannerAdReady = true;
  //         });
  //       },
  //       onAdFailedToLoad: (ad, err) {
  //         print('Failed to load banner ad: ${err.message}');
  //         _isBannerAdReady = false;
  //         ad.dispose();
  //       },
  //     ),
  //   );
  //   _bannerAd.load();
  // }

  void _loadGames() {
    Future.microtask(() {
      context.read<GameProvider>().loadUserGames();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // _bannerAd.dispose(); // Disabled for demo
    super.dispose();
  }

  List<GameModel> _getFilteredGames(List<GameModel> games) {
    var filtered = games;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((game) {
        return game.title.toLowerCase().contains(query) ||
            game.publisher.toLowerCase().contains(query) ||
            game.designers.any((d) => d.toLowerCase().contains(query));
      }).toList();
    }

    // Apply category filter
    if (_filterBy != 'all') {
      filtered = filtered.where((game) {
        switch (_filterBy) {
          case 'available':
            return game.isAvailable;
          case 'loaned':
            return !game.isAvailable;
          case 'wishlist':
            return game.tags.contains('wishlist');
          default:
            return true;
        }
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
        filtered.sort((a, b) => (b.bggRank ?? 99999).compareTo(a.bggRank ?? 99999));
        break;
      case 'players':
        filtered.sort((a, b) => a.minPlayers.compareTo(b.minPlayers));
        break;
    }

    return filtered;
  }

  Widget _buildGameItem(GameModel game, int index, int totalGames) {
    // Insert native ad every 8-10 items
    if ((index + 1) % 9 == 0 && index < totalGames - 1) {
      return Column(
        children: [
          AnimatedGameCard(
            game: game,
            onTap: () => _navigateToGameDetail(game),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: NativeAdWidget(),
          ),
        ],
      );
    }

    return AnimatedGameCard(
      game: game,
      onTap: () => _navigateToGameDetail(game),
    );
  }

  void _navigateToGameDetail(GameModel game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameDetailScreen(game: game),
      ),
    );
  }

  void _navigateToCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final games = _getFilteredGames(gameProvider.games);

    return SafeArea(
      child: Column(
        children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search games...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
          ),
        ),

        // Filter Chips
        SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filterBy == 'all',
                    onSelected: (selected) {
                      setState(() => _filterBy = 'all');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Available'),
                    selected: _filterBy == 'available',
                    onSelected: (selected) {
                      setState(() => _filterBy = 'available');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Loaned'),
                    selected: _filterBy == 'loaned',
                    onSelected: (selected) {
                      setState(() => _filterBy = 'loaned');
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Wishlist'),
                    selected: _filterBy == 'wishlist',
                    onSelected: (selected) {
                      setState(() => _filterBy = 'wishlist');
                    },
                  ),
                ],
              ),
        ),

        // Sort and View Options
        Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButton<String>(
                    value: _sortBy,
                    onChanged: (value) {
                      setState(() => _sortBy = value!);
                    },
                    items: const [
                      DropdownMenuItem(value: 'title', child: Text('Title')),
                      DropdownMenuItem(value: 'recent', child: Text('Recent')),
                      DropdownMenuItem(value: 'rating', child: Text('Rating')),
                      DropdownMenuItem(value: 'players', child: Text('Players')),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                    onPressed: () {
                      setState(() => _isGridView = !_isGridView);
                    },
                  ),
                ],
              ),
        ),

        // Games List/Grid
        Expanded(
              child: gameProvider.isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: _isGridView
                          ? GridView.count(
                              crossAxisCount: _getResponsiveColumns(context),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              children: List.generate(6, (index) => const ShimmerCard()),
                            )
                          : const ShimmerList(itemCount: 5),
                    )
                  : games.isEmpty
                      ? EmptyState(
                          type: _searchController.text.isNotEmpty
                              ? EmptyStateType.noResults
                              : EmptyStateType.noGames,
                          action: _searchController.text.isEmpty
                              ? ElevatedButton.icon(
                                  onPressed: _navigateToCamera,
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text('Add Your First Game'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                )
                              : null,
                        )
                      : _isGridView
                          ? MasonryGridView.count(
                              padding: const EdgeInsets.all(16),
                              crossAxisCount: _getResponsiveColumns(context),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              itemCount: games.length,
                              itemBuilder: (context, index) {
                                return _buildGameItem(games[index], index, games.length);
                              },
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: games.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildGameItem(games[index], index, games.length),
                                );
                              },
                            ),
        ),

        // Banner Ad disabled for demo
            // if (_isBannerAdReady)
            //   Container(
            //     alignment: Alignment.center,
            //     width: _bannerAd.size.width.toDouble(),
            //     height: _bannerAd.size.height.toDouble(),
            //     child: AdWidget(ad: _bannerAd),
            //   ),
        ],
      ),
    );
  }
}