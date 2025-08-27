import 'package:flutter/material.dart';
import 'utils/theme.dart';
import 'widgets/animated_game_card.dart';
import 'widgets/empty_state.dart';
import 'widgets/glass_container.dart';
import 'widgets/shimmer_loading.dart';
import 'models/game_model.dart';

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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
      coverImage: '',
      thumbnailImage: '',
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
      coverImage: '',
      thumbnailImage: '',
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
      coverImage: '',
      thumbnailImage: '',
      condition: GameCondition.mint,
      location: 'Shelf A',
      visibility: GameVisibility.public,
      importSource: ImportSource.photo,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
      isAvailable: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              AppTheme.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildLibraryView(),
              _buildFriendsView(),
              _buildDiscoverView(),
              _buildProfileView(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
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
          ? GlassButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Camera screen would open here'),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Game',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildLibraryView() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'My Game Library',
                  style: AppTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search games...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
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
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Available'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Loaned'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Games grid
        Expanded(
          child: _isLoading
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: List.generate(4, (index) => const ShimmerCard()),
                  ),
                )
              : _demoGames.isEmpty
                  ? EmptyState(
                      type: EmptyStateType.noGames,
                      action: ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          Future.delayed(const Duration(seconds: 2), () {
                            setState(() => _isLoading = false);
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Load Demo Games'),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.7,
                      ),
                      itemCount: _demoGames.length,
                      itemBuilder: (context, index) {
                        return AnimatedGameCard(
                          game: _demoGames[index],
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Selected: ${_demoGames[index].title}'),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                            );
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFriendsView() {
    return Center(
      child: EmptyState(
        type: EmptyStateType.noFriends,
        action: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.person_add),
          label: const Text('Add Friends'),
        ),
      ),
    );
  }

  Widget _buildDiscoverView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured game hero
          GlassCard(
            title: 'Game of the Week',
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.casino,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Wingspan',
                      style: AppTheme.headlineMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Engine-building strategy game',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Trending Games',
            style: AppTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          const ShimmerList(itemCount: 3),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Demo User',
            style: AppTheme.headlineMedium,
          ),
          Text(
            'demo@gamekeep.app',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          // Stats
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Games', '${_demoGames.length}', Icons.casino),
                _buildStat('Plays', '15', Icons.play_circle),
                _buildStat('Friends', '8', Icons.people),
                _buildStat('Loaned', '1', Icons.swap_horiz),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Menu items
          GlassCard(
            child: Column(
              children: [
                _buildMenuItem(Icons.import_export, 'Import from BGG'),
                const Divider(),
                _buildMenuItem(Icons.settings, 'Settings'),
                const Divider(),
                _buildMenuItem(Icons.dark_mode, 'Dark Mode'),
                const Divider(),
                _buildMenuItem(Icons.info, 'About'),
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
          style: AppTheme.headlineSmall,
        ),
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    );
  }
}