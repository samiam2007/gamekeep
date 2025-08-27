import 'package:flutter/material.dart';
import '../models/play_session_model.dart';
import '../services/play_tracking_service.dart';
import '../utils/theme.dart';

class PlayHistoryScreen extends StatefulWidget {
  const PlayHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PlayHistoryScreen> createState() => _PlayHistoryScreenState();
}

class _PlayHistoryScreenState extends State<PlayHistoryScreen> {
  late PlayTrackingService _playService;
  List<PlaySession> _sessions = [];
  List<PlaySession> _filteredSessions = [];
  bool _isLoading = true;
  String _filterGame = 'All Games';
  String _filterPlayer = 'All Players';
  
  final Set<String> _gameNames = {'All Games'};
  final Set<String> _playerNames = {'All Players'};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _playService = await PlayTrackingService.getInstance();
    await _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    
    try {
      final sessions = await _playService.getPlaySessions();
      
      // Extract unique games and players for filters
      final games = <String>{'All Games'};
      final players = <String>{'All Players'};
      
      for (final session in sessions) {
        games.add(session.gameTitle);
        for (final player in session.players) {
          if (player.name != 'You') {
            players.add(player.name);
          }
        }
      }
      
      setState(() {
        _sessions = sessions;
        _filteredSessions = sessions;
        _gameNames.addAll(games);
        _playerNames.addAll(players);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredSessions = _sessions.where((session) {
        final gameMatch = _filterGame == 'All Games' || 
                          session.gameTitle == _filterGame;
        final playerMatch = _filterPlayer == 'All Players' ||
                           session.players.any((p) => p.name == _filterPlayer);
        return gameMatch && playerMatch;
      }).toList();
    });
  }

  Future<void> _deleteSession(PlaySession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Play Session'),
        content: Text('Are you sure you want to delete this play session of ${session.gameTitle}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await _playService.deletePlaySession(session.sessionId);
      if (success) {
        await _loadSessions();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Play session deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Play History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterBar(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSessions.isEmpty
              ? _buildEmptyState()
              : _buildSessionsList(),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterDropdown(
              'Game',
              _filterGame,
              _gameNames.toList(),
              (value) {
                setState(() => _filterGame = value!);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildFilterDropdown(
              'Player',
              _filterPlayer,
              _playerNames.toList(),
              (value) {
                setState(() => _filterPlayer = value!);
                _applyFilters();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF2A2A2A),
        style: const TextStyle(color: Colors.white),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSessionsList() {
    // Group sessions by month
    final Map<String, List<PlaySession>> groupedSessions = {};
    
    for (final session in _filteredSessions) {
      final monthKey = _getMonthKey(session.playDate);
      groupedSessions.putIfAbsent(monthKey, () => []).add(session);
    }
    
    final sortedKeys = groupedSessions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Sort months in descending order
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final monthKey = sortedKeys[index];
        final sessions = groupedSessions[monthKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _formatMonthKey(monthKey),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...sessions.map((session) => _buildSessionCard(session)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(PlaySession session) {
    final isWin = session.winner == 'You' ||
                 session.players.any((p) => p.name == 'You' && p.isWinner);
    
    return Dismissible(
      key: Key(session.sessionId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _deleteSession(session);
        return false; // We handle deletion ourselves
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => _showSessionDetails(session),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isWin 
                    ? Colors.green.withOpacity(0.3)
                    : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.gameTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isWin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Victory',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, 
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(session.playDate),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${session.duration} min',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        session.location,
                        style: TextStyle(color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: session.players.map((player) {
                    final isPlayerWinner = player.isWinner || 
                                          player.name == session.winner;
                    return Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPlayerWinner)
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                          if (isPlayerWinner) const SizedBox(width: 4),
                          Text(
                            player.name +
                                (player.score != null
                                    ? ' (${player.score})'
                                    : ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: player.name == 'You'
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.grey[800],
                    );
                  }).toList(),
                ),
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    session.notes!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(PlaySession session) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.gameTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.calendar_today, 
                            'Date', _formatFullDate(session.playDate)),
              _buildDetailRow(Icons.timer, 
                            'Duration', '${session.duration} minutes'),
              _buildDetailRow(Icons.location_on, 
                            'Location', session.location),
              if (session.winner != null)
                _buildDetailRow(Icons.emoji_events, 
                              'Winner', session.winner!),
              const SizedBox(height: 16),
              const Text(
                'Players & Scores',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...session.players.map((player) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      if (player.isWinner || player.name == session.winner)
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        player.name,
                        style: TextStyle(
                          color: player.name == 'You'
                              ? AppTheme.primaryColor
                              : Colors.white,
                        ),
                      ),
                      if (player.score != null) ...[
                        const Spacer(),
                        Text(
                          '${player.score} points',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              if (session.notes != null && session.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  session.notes!,
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 16),
          Text(
            'No play sessions found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging your games to see them here',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  String _formatMonthKey(String monthKey) {
    final parts = monthKey.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${monthNames[month - 1]} $year';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFullDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final weekday = weekdays[date.weekday - 1];
    return '$weekday, ${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}