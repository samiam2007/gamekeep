import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'widgets/animated_game_card.dart';
import 'widgets/empty_state.dart';
import 'widgets/glass_container.dart';
import 'widgets/shimmer_loading.dart';
import 'models/game_model.dart';
import 'screens/game_detail_screen_simple.dart';
import 'screens/camera_capture_screen.dart';
import 'screens/bgg_import_enhanced_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/discover_screen_enhanced_v2.dart';
import 'services/game_storage_service.dart';

void main() {
  runApp(const GameKeepDemoApp()); 
}

class GameKeepDemoApp extends StatelessWidget {
  const GameKeepDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameKeep Demo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DemoHomeScreen(),
    );
  }
}

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({Key? key}) : super(key: key);

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Demo games
  final List<GameModel> _demoGames = [
    GameModel(
      gameId: '1',
      ownerId: 'demo',
      title: 'Wingspan',
      publisher: 'Stonemaier Games',
      year: 2019,
      designers: ['Elizabeth Hargrave'],
      minPlayers: 1,
      maxPlayers: 5,
      playTime: 70,
      weight: 2.4,
      bggId: 266192,
      bggRank: 15,
      mechanics: ['Engine Building', 'Card Drafting'],
      categories: ['Animals', 'Card Game'],
      tags: ['favorite', 'engine-building'],
      coverImage: 'https://cf.geekdo-images.com/yLZJCVLlIx4c7eJEWUNJ7w__imagepage/img/Vhhms7zsV_lDHBz5-fxBugvRQ6I=/fit-in/900x600/filters:no_upscale():strip_icc()/pic4458123.jpg',
      thumbnailImage: 'https://cf.geekdo-images.com/yLZJCVLlIx4c7eJEWUNJ7w__thumb/img/B084XUFMjgJFGkwLkVjz6FcLFLo=/fit-in/200x150/filters:strip_icc()/pic4458123.jpg',
      condition: GameCondition.mint,
      location: 'Shelf A',
      visibility: GameVisibility.public,
      importSource: ImportSource.bgg,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isAvailable: true,
    ),
    GameModel(
      gameId: '2',
      ownerId: 'demo',
      title: 'Catan',
      publisher: 'Catan Studio',
      year: 1995,
      designers: ['Klaus Teuber'],
      minPlayers: 3,
      maxPlayers: 4,
      playTime: 90,
      weight: 2.3,
      bggId: 13,
      bggRank: 453,
      mechanics: ['Trading', 'Dice Rolling'],
      categories: ['Economic', 'Negotiation'],
      tags: ['classic'],
      coverImage: 'https://cf.geekdo-images.com/W3Bsga_uLP9kO91gZ7H8yw__imagepage/img/qTMkYwtjkWW5L9h7LRJAj_x_I0w=/fit-in/900x600/filters:no_upscale():strip_icc()/pic2419375.jpg',
      thumbnailImage: 'https://cf.geekdo-images.com/W3Bsga_uLP9kO91gZ7H8yw__thumb/img/5g2k8Eogq9-4RbOyJXYFZIbRrAA=/fit-in/200x150/filters:strip_icc()/pic2419375.jpg',
      condition: GameCondition.good,
      location: 'Shelf B',
      visibility: GameVisibility.friends,
      importSource: ImportSource.manual,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      isAvailable: false,
      currentBorrowerId: 'friend1',
    ),
    GameModel(
      gameId: '3',
      ownerId: 'demo',
      title: 'Azul',
      publisher: 'Plan B Games',
      year: 2017,
      designers: ['Michael Kiesling'],
      minPlayers: 2,
      maxPlayers: 4,
      playTime: 45,
      weight: 1.8,
      bggId: 230802,
      bggRank: 42,
      mechanics: ['Pattern Building', 'Tile Placement'],
      categories: ['Abstract Strategy'],
      tags: ['family', 'quick'],
      coverImage: 'https://cf.geekdo-images.com/aPSHJO0d0XOpQR5X-wJonw__imagepage/img/q4iJYlKKyE9GUPPFnODHC9EiCPY=/fit-in/900x600/filters:no_upscale():strip_icc()/pic3718275.jpg',
      thumbnailImage: 'https://cf.geekdo-images.com/aPSHJO0d0XOpQR5X-wJonw__thumb/img/qjbGBifrClz7ZRq1BW7wGy-vLkk=/fit-in/200x150/filters:strip_icc()/pic3718275.jpg',
      condition: GameCondition.mint,
      location: 'Shelf A',
      visibility: GameVisibility.public,
      importSource: ImportSource.photo,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
      isAvailable: true,
    ),
    GameModel(
      gameId: '4',
      ownerId: 'demo',
      title: 'Ticket to Ride',
      publisher: 'Days of Wonder',
      year: 2004,
      designers: ['Alan R. Moon'],
      minPlayers: 2,
      maxPlayers: 5,
      playTime: 60,
      weight: 1.9,
      bggId: 9209,
      bggRank: 169,
      mechanics: ['Route Building', 'Set Collection'],
      categories: ['Trains', 'Travel'],
      tags: ['gateway', 'family'],
      coverImage: 'https://cf.geekdo-images.com/ZWJg0dCdrWHxVnc0eFXK8w__imagepage/img/KKp4ymhMRFWTfRaX8bODKwEoGk4=/fit-in/900x600/filters:no_upscale():strip_icc()/pic38668.jpg',
      thumbnailImage: 'https://cf.geekdo-images.com/ZWJg0dCdrWHxVnc0eFXK8w__thumb/img/o6L1g5dE4cM44lrTkJ1HxKJjK1c=/fit-in/200x150/filters:strip_icc()/pic38668.jpg',
      condition: GameCondition.good,
      location: 'Shelf C',
      visibility: GameVisibility.public,
      importSource: ImportSource.bgg,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
      updatedAt: DateTime.now(),
      isAvailable: true,
    ),
    GameModel(
      gameId: '5',
      ownerId: 'demo',
      title: 'Gloomhaven',
      publisher: 'Cephalofair Games',
      year: 2017,
      designers: ['Isaac Childres'],
      minPlayers: 1,
      maxPlayers: 4,
      playTime: 120,
      weight: 3.9,
      bggId: 174430,
      bggRank: 1,
      mechanics: ['Campaign', 'Hand Management', 'Modular Board', 'Scenario'],
      categories: ['Adventure', 'Campaign', 'Fantasy', 'Fighting'],
      tags: ['campaign', 'legacy', 'cooperative'],
      coverImage: 'https://cf.geekdo-images.com/sZYp_3BTDGjh2unaZfZmuA__imagepage/img/pBaOL7vV402nn1I5dHsdSKsFHqA=/fit-in/900x600/filters:no_upscale():strip_icc()/pic2437871.jpg',
      thumbnailImage: 'https://cf.geekdo-images.com/sZYp_3BTDGjh2unaZfZmuA__thumb/img/OMC6V0fi5K6NaP7u3PLNy_mNT8s=/fit-in/200x150/filters:strip_icc()/pic2437871.jpg',
      condition: GameCondition.mint,
      location: 'Campaign Shelf',
      visibility: GameVisibility.public,
      importSource: ImportSource.bgg,
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now(),
      isAvailable: true,
    ),
    GameModel(
      gameId: '6',
      ownerId: 'demo',
      title: 'Pandemic Legacy: Season 1',
      publisher: 'Z-Man Games',
      year: 2015,
      designers: ['Rob Daviau', 'Matt Leacock'],
      minPlayers: 2,
      maxPlayers: 4,
      playTime: 60,
      weight: 2.8,
      bggId: 161936,
      bggRank: 2,
      mechanics: ['Campaign', 'Cooperative', 'Legacy', 'Hand Management'],
      categories: ['Medical', 'Environmental'],
      tags: ['legacy', 'cooperative', 'campaign'],
      coverImage: 'https://cf.geekdo-images.com/-Qer2BBPG7qGGDu6KcVDIw__imagepage/img/BZm-Cazr5G1wOA7V8ezGqaKvTGQ=/fit-in/900x600/filters:no_upscale():strip_icc()/pic2452831.png',
      thumbnailImage: 'https://cf.geekdo-images.com/-Qer2BBPG7qGGDu6KcVDIw__thumb/img/CMxQ7MztTgNvBiyifMlcrnQGQoQ=/fit-in/200x150/filters:strip_icc()/pic2452831.png',
      condition: GameCondition.good,
      location: 'Campaign Shelf',
      visibility: GameVisibility.private,
      importSource: ImportSource.bgg,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now(),
      isAvailable: true,
    ),
  ];
  
  // Combined list of demo and imported games
  List<GameModel> _allGames = [];
  List<GameModel> _importedGames = [];
  
  @override
  void initState() {
    super.initState();
    // Initialize with demo games immediately
    _allGames = [..._demoGames];
    // Then load any imported games
    _loadGames();
  }
  
  Future<void> _loadGames() async {
    try {
      // Load imported games from storage
      final imported = await GameStorageService.loadImportedGames();
      
      if (mounted) {
        setState(() {
          _importedGames = imported;
          _allGames = [..._demoGames, ..._importedGames];
        });
      }
    } catch (e) {
      print('Error loading games: $e');
      // Keep using demo games if loading fails
      if (mounted) {
        setState(() {
          _allGames = [..._demoGames];
        });
      }
    }
  }

  void _navigateToGameDetail(GameModel game) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GameDetailScreenSimple(game: game),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  void _showAddGameOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AppTheme.primaryColor, width: 0.5),
            left: BorderSide(color: AppTheme.primaryColor, width: 0.5),
            right: BorderSide(color: AppTheme.primaryColor, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add New Game',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildAddOption(Icons.camera_alt, 'Take Photo', 'Use AI to scan game box'),
            const SizedBox(height: 12),
            _buildAddOption(Icons.qr_code, 'Scan Barcode', 'Quick add with barcode'),
            const SizedBox(height: 12),
            _buildAddOption(Icons.search, 'Search BGG', 'Import from BoardGameGeek'),
            const SizedBox(height: 12),
            _buildAddOption(Icons.edit, 'Manual Entry', 'Add game details manually'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAddOption(IconData icon, String title, String subtitle) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        if (title == 'Take Photo') {
          // Navigate to camera screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraCaptureScreen(),
            ),
          );
        } else if (title == 'Search BGG') {
          // Navigate to BGG import screen and reload games if imported
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BGGImportEnhancedScreen(),
            ),
          );
          
          // If games were imported, reload the library
          if (result == true) {
            _loadGames();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title feature coming soon!'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[700], size: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildLibraryView(),
            const FriendsScreen(),
            const DiscoverScreenEnhanced(),
            _buildProfileView(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(
            top: BorderSide(
              color: AppTheme.primaryColor.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: const Color(0xFF1A1A1A),
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.casino),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Friends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddGameOptions,
              backgroundColor: AppTheme.primaryColor,
              label: const Text(
                'Add Game',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.black),
            )
          : null,
    );
  }

  Widget _buildLibraryView() {
    return Column(
      children: [
        // Header
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
          child: Column(
            children: [
              const Text(
                'MY COLLECTION',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search games...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: true,
                      onSelected: (_) {},
                      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                      labelStyle: const TextStyle(color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Available'),
                      selected: false,
                      onSelected: (_) {},
                      labelStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Loaned'),
                      selected: false,
                      onSelected: (_) {},
                      labelStyle: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Games grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: _allGames.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _navigateToGameDetail(_allGames[index]),
                child: AnimatedGameCard(
                  game: _allGames[index],
                  onTap: () => _navigateToGameDetail(_allGames[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Friends view replaced with FriendsScreen widget

  Widget _buildDiscoverView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: const Text(
              'DISCOVER',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured game
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.3),
                        const Color(0xFF1A1A1A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        bottom: -50,
                        child: Icon(
                          Icons.casino,
                          size: 200,
                          color: AppTheme.primaryColor.withOpacity(0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.5),
                                ),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Gloomhaven',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Epic tactical combat in a dark fantasy world',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.star, color: AppTheme.primaryColor, size: 20),
                                const SizedBox(width: 4),
                                const Text(
                                  '4.9',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.people, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '1-4 Players',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Trending Games',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...['Ark Nova', 'Brass: Birmingham', 'Spirit Island'].map((game) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.casino,
                            color: AppTheme.primaryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                game,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Strategy • 2-4 Players',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[700],
                          size: 16,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
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
            child: const Text(
              'PROFILE',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryDark],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Game Master',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'player@gamekeep.app',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                // Stats
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('Games', '${_allGames.length}', Icons.casino),
                      Container(width: 1, height: 40, color: AppTheme.primaryColor.withOpacity(0.2)),
                      _buildStat('Plays', '27', Icons.play_circle),
                      Container(width: 1, height: 40, color: AppTheme.primaryColor.withOpacity(0.2)),
                      _buildStat('Friends', '0', Icons.people),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Menu items
                ...[
                  {'icon': Icons.import_export, 'label': 'Import from BGG'},
                  {'icon': Icons.bar_chart, 'label': 'Statistics'},
                  {'icon': Icons.settings, 'label': 'Settings'},
                  {'icon': Icons.help, 'label': 'Help & Support'},
                  {'icon': Icons.logout, 'label': 'Sign Out'},
                ].map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: AppTheme.primaryColor,
                      ),
                      title: Text(
                        item['label'] as String,
                        style: const TextStyle(color: Colors.white),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[700],
                        size: 16,
                      ),
                      onTap: () async {
                        if (item['label'] == 'Import from BGG') {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BGGImportEnhancedScreen(),
                            ),
                          );
                          // Reload games if any were imported
                          if (result == true) {
                            _loadGames();
                          }
                        } else if (item['label'] == 'Statistics') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StatisticsScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item['label']} coming soon!'),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          );
                        }
                      },
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}