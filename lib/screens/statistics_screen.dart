import 'package:flutter/material.dart';
import '../services/play_tracking_service.dart';
import '../models/play_session_model.dart';
import '../utils/theme.dart';
import 'play_history_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late PlayTrackingService _playService;
  late TabController _tabController;
  
  Map<String, dynamic> _overallStats = {};
  Map<String, GameStatistics> _gameStats = {};
  List<PlayerStatistics> _playerStats = [];
  List<PlaySession> _recentPlays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    _playService = await PlayTrackingService.getInstance();
    await _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);
    
    try {
      final overall = await _playService.getOverallStatistics();
      final games = await _playService.getGameStatistics();
      final players = await _playService.getPlayerStatistics();
      final recent = await _playService.getRecentPlays(limit: 5);
      
      setState(() {
        _overallStats = overall;
        _gameStats = games;
        _playerStats = players;
        _recentPlays = recent;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading statistics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PlayHistoryScreen(),
                ),
              ).then((_) => _loadStatistics());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Games'),
            Tab(text: 'Players'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildGamesTab(),
                _buildPlayersTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Play History Button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PlayHistoryScreen(),
              ),
            );
          },
          icon: const Icon(Icons.history),
          label: const Text('View Full Play History with Filters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Key Metrics
        _buildKeyMetrics(),
        const SizedBox(height: 24),
        
        // Streaks
        _buildStreakSection(),
        const SizedBox(height: 24),
        
        // Activity Chart
        _buildActivitySection(),
        const SizedBox(height: 24),
        
        // Recent Plays
        _buildRecentPlaysSection(),
      ],
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lifetime Stats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildStatCard(
              'Total Plays',
              '${_overallStats['totalPlays'] ?? 0}',
              Icons.casino,
              Colors.blue,
            ),
            _buildStatCard(
              'Hours Played',
              '${_overallStats['totalHoursPlayed'] ?? 0}',
              Icons.timer,
              Colors.green,
            ),
            _buildStatCard(
              'Games Owned',
              '${_overallStats['uniqueGames'] ?? 0}',
              Icons.grid_view,
              Colors.orange,
            ),
            _buildStatCard(
              'Gaming Friends',
              '${_overallStats['uniquePlayers'] ?? 0}',
              Icons.people,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStreakSection() {
    final currentStreak = _overallStats['currentStreak'] ?? 0;
    final longestStreak = _overallStats['longestStreak'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.2),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Current Streak',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          Text(
            '$currentStreak ${currentStreak == 1 ? 'Day' : 'Days'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Longest: $longestStreak days',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActivityStat(
              'This Week',
              '${_overallStats['playsThisWeek'] ?? 0}',
              Colors.green,
            ),
            _buildActivityStat(
              'This Month',
              '${_overallStats['playsThisMonth'] ?? 0}',
              Colors.blue,
            ),
            _buildActivityStat(
              'This Year',
              '${_overallStats['playsThisYear'] ?? 0}',
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPlaysSection() {
    if (_recentPlays.isEmpty) {
      return _buildEmptyState('No plays recorded yet');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Plays',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PlayHistoryScreen(),
                  ),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._recentPlays.map((play) => _buildPlayTile(play)),
      ],
    );
  }

  Widget _buildPlayTile(PlaySession play) {
    final isWin = play.winner == 'You' || 
                 play.players.any((p) => p.name == 'You' && p.isWinner);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWin ? Colors.green.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isWin 
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isWin ? Icons.emoji_events : Icons.casino,
              color: isWin ? Colors.green : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  play.gameTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${play.players.length} players • ${play.duration} min',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(play.playDate),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesTab() {
    if (_gameStats.isEmpty) {
      return _buildEmptyState('No game statistics available');
    }
    
    final sortedGames = _gameStats.values.toList()
      ..sort((a, b) => b.totalPlays.compareTo(a.totalPlays));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedGames.length,
      itemBuilder: (context, index) {
        final stats = sortedGames[index];
        return _buildGameStatCard(stats);
      },
    );
  }

  Widget _buildGameStatCard(GameStatistics stats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  stats.gameTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${stats.totalPlays} plays',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat('Win Rate', '${(stats.winRate * 100).toStringAsFixed(0)}%'),
              _buildMiniStat('Avg Time', '${stats.averagePlayTime} min'),
              _buildMiniStat('Avg Score', stats.averageScore.toStringAsFixed(0)),
            ],
          ),
          if (stats.lastPlayed != null) ...[
            const SizedBox(height: 12),
            Text(
              'Last played ${_formatRelativeDate(stats.lastPlayed!)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
          if (stats.mostFrequentPlayers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: stats.mostFrequentPlayers.map((player) {
                return Chip(
                  label: Text(
                    player,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.grey[800],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
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

  Widget _buildPlayersTab() {
    if (_playerStats.isEmpty) {
      return _buildEmptyState('No player statistics available');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _playerStats.length,
      itemBuilder: (context, index) {
        final stats = _playerStats[index];
        return _buildPlayerStatCard(stats);
      },
    );
  }

  Widget _buildPlayerStatCard(PlayerStatistics stats) {
    final winPercentage = (stats.winRate * 100).toStringAsFixed(0);
    final isRival = stats.winRate < 0.4; // You win less than 40% against them
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRival ? Colors.red.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isRival ? Colors.red[100] : Colors.blue[100],
                child: Text(
                  stats.playerName[0].toUpperCase(),
                  style: TextStyle(
                    color: isRival ? Colors.red[800] : Colors.blue[800],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.playerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isRival)
                      Text(
                        'Your Rival',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${stats.gamesPlayedTogether} games',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Win rate: $winPercentage%',
                    style: TextStyle(
                      color: stats.winRate >= 0.5 ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (stats.favoriteGames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Favorite games together:',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: stats.favoriteGames.map((game) {
                return Chip(
                  label: Text(
                    game,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.grey[800],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      final months = difference.inDays ~/ 30;
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = difference.inDays ~/ 365;
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}