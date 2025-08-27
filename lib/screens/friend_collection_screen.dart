import 'package:flutter/material.dart';
import '../models/friend_model.dart';
import '../models/game_model.dart';
import '../services/friends_service.dart';

class FriendCollectionScreen extends StatefulWidget {
  final FriendModel friend;

  const FriendCollectionScreen({Key? key, required this.friend}) : super(key: key);

  @override
  State<FriendCollectionScreen> createState() => _FriendCollectionScreenState();
}

class _FriendCollectionScreenState extends State<FriendCollectionScreen> {
  List<GameModel> _games = [];
  bool _isLoading = true;
  late FriendsService _friendsService;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    _friendsService = await FriendsService.getInstance();
    _loadFriendCollection();
  }

  Future<void> _loadFriendCollection() async {
    final games = await _friendsService.getFriendCollection(widget.friend.friendUserId);
    setState(() {
      _games = games;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.friend.friendName}'s Collection"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
              ? _buildEmptyState()
              : _buildGamesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No shared games',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.friend.friendName} hasn\'t shared any games yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesList() {
    return RefreshIndicator(
      onRefresh: _loadFriendCollection,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: widget.friend.friendAvatar?.isNotEmpty == true
                            ? Text(widget.friend.friendAvatar!, style: const TextStyle(fontSize: 20))
                            : Text(widget.friend.friendName[0].toUpperCase()),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.friend.friendName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_games.length} ${_games.length == 1 ? 'game' : 'games'} shared',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final game = _games[index];
                  return _GameCard(
                    game: game,
                    friend: widget.friend,
                    onTap: () => _showGameDetail(game),
                  );
                },
                childCount: _games.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  void _showGameDetail(GameModel game) {
    showModalBottomSheet(
      context: context,
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
                game.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'From ${widget.friend.friendName}\'s collection',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _InfoChip(
                    icon: Icons.people,
                    label: '${game.minPlayers}-${game.maxPlayers} players',
                  ),
                  _InfoChip(
                    icon: Icons.timer,
                    label: '${game.playTime} min',
                  ),
                  _InfoChip(
                    icon: Icons.psychology,
                    label: 'Weight: ${game.weight.toStringAsFixed(1)}',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Publisher: ', style: TextStyle(color: Colors.grey[600])),
                  Text(game.publisher, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Year: ', style: TextStyle(color: Colors.grey[600])),
                  Text('${game.year}', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              if (game.designers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Designer: ', style: TextStyle(color: Colors.grey[600])),
                    Expanded(
                      child: Text(
                        game.designers.join(', '),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _askToBorrow(game);
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Ask to Borrow'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _askToBorrow(GameModel game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask to Borrow'),
        content: Text('Send a message to ${widget.friend.friendName} asking to borrow "${game.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request sent to ${widget.friend.friendName}!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Collection'),
          content: const TextField(
            decoration: InputDecoration(
              hintText: 'Enter game title...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Implement search functionality
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameModel game;
  final FriendModel friend;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.friend,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: game.coverImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            game.coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.casino, size: 40, color: Colors.grey),
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.casino, size: 40, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${game.minPlayers}-${game.maxPlayers} players',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${game.playTime} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (game.isAvailable) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Available',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'On Loan',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
    );
  }
}