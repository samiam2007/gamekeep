import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/game_model.dart';
import '../models/friend_model.dart';
import '../models/campaign_data.dart';
import '../services/friends_service.dart';
import '../services/campaign_service.dart';
import '../services/game_storage_service.dart';
import 'log_play_campaign_screen.dart';
import '../widgets/navigation_wrapper.dart';

class GameDetailScreenSimple extends StatefulWidget {
  final GameModel game;

  const GameDetailScreenSimple({Key? key, required this.game}) : super(key: key);

  @override
  State<GameDetailScreenSimple> createState() => _GameDetailScreenSimpleState();
}

class _GameDetailScreenSimpleState extends State<GameDetailScreenSimple> {
  late GameModel game;

  @override
  void initState() {
    super.initState();
    game = widget.game;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      currentIndex: 0, // Library tab selected
      child: Scaffold(
        body: CustomScrollView(
        slivers: [
          // App Bar with Hero Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                game.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: game.coverImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: game.coverImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.casino, size: 80),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.casino, size: 80),
                    ),
            ),
          ),

          // Game Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _InfoItem(
                                icon: Icons.people,
                                label: 'Players',
                                value: '${game.minPlayers}-${game.maxPlayers}',
                              ),
                              _InfoItem(
                                icon: Icons.timer,
                                label: 'Play Time',
                                value: '${game.playTime} min',
                              ),
                              _InfoItem(
                                icon: Icons.psychology,
                                label: 'Weight',
                                value: game.weight.toStringAsFixed(1),
                              ),
                            ],
                          ),
                          if (game.bggRank != null) ...[
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.leaderboard,
                                        size: 16,
                                        color: Colors.blue[800],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'BGG Rank #${game.bggRank}',
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showLogPlayDialog(context),
                          icon: const Icon(Icons.play_circle),
                          label: const Text('Log Play'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: game.isAvailable
                              ? () => _showLoanDialog(context)
                              : null,
                          icon: const Icon(Icons.card_giftcard),
                          label: Text(
                            game.isAvailable ? 'Loan Game' : 'On Loan',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Details Section
                  _DetailSection(
                    title: 'Details',
                    content: Column(
                      children: [
                        _DetailRow('Publisher', game.publisher),
                        _DetailRow('Year', game.year.toString()),
                        if (game.designers.isNotEmpty)
                          _DetailRow('Designer', game.designers.join(', ')),
                        if (game.edition != null)
                          _DetailRow('Edition', game.edition!),
                        _DetailRow('Condition', game.condition.name.toUpperCase()),
                        _DetailRow('Location', game.location),
                        if (game.value != null)
                          _DetailRow('Value', '\$${game.value!.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),

                  // Description Section
                  if (game.description != null && game.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Description',
                      content: Text(
                        game.description!,
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                  ],

                  if (game.mechanics.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Mechanics',
                      content: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: game.mechanics.map((mechanic) {
                          return Chip(
                            label: Text(mechanic),
                            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  if (game.categories.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _DetailSection(
                      title: 'Categories',
                      content: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: game.categories.map((category) {
                          return Chip(
                            label: Text(category),
                            backgroundColor: Colors.green.withOpacity(0.1),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showEditDialog(context),
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }

  void _showLogPlayDialog(BuildContext context) async {
    // Check if there's an active campaign for this game
    final campaignService = await CampaignService.getInstance();
    final campaigns = await campaignService.getCampaignsForGame(game.gameId);
    final activeCampaigns = campaigns.where((c) => c.isActive).toList();
    
    CampaignData? selectedCampaign;
    
    if (activeCampaigns.isNotEmpty && mounted) {
      // Show campaign selection dialog if there are active campaigns
      selectedCampaign = await showDialog<CampaignData>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Play Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Do you want to continue a campaign or log a regular play?'),
              const SizedBox(height: 16),
              ...activeCampaigns.map((campaign) => 
                ListTile(
                  leading: const Icon(Icons.fort, color: Colors.blue),
                  title: Text(campaign.campaignName),
                  subtitle: Text('Session ${campaign.currentSession + 1}'),
                  onTap: () => Navigator.pop(context, campaign),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.casino),
                title: const Text('Regular Play'),
                subtitle: const Text('One-off game session'),
                onTap: () => Navigator.pop(context, null),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!mounted) return;
    
    print('Navigating to LogPlayCampaignScreen for game: ${game.title}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogPlayCampaignScreen(
          game: game,
          campaign: selectedCampaign,
        ),
      ),
    ).then((result) {
      print('Returned from LogPlayCampaignScreen with result: $result');
      if (result == true) {
        // Refresh the UI if needed
        setState(() {});
      }
    });
  }

  void _showLoanDialog(BuildContext context) async {
    final friendsService = await FriendsService.getInstance();
    final friends = await friendsService.getFriends(status: FriendStatus.accepted);
    
    if (!mounted) return;
    
    if (friends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No friends available. Add friends first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _LoanGameSheet(
          game: game,
          friends: friends,
          friendsService: friendsService,
          onLoanComplete: () {
            setState(() {
              game = GameModel(
                gameId: game.gameId,
                ownerId: game.ownerId,
                title: game.title,
                publisher: game.publisher,
                year: game.year,
                designers: game.designers,
                minPlayers: game.minPlayers,
                maxPlayers: game.maxPlayers,
                playTime: game.playTime,
                weight: game.weight,
                bggId: game.bggId,
                bggRank: game.bggRank,
                mechanics: game.mechanics,
                categories: game.categories,
                tags: game.tags,
                coverImage: game.coverImage,
                thumbnailImage: game.thumbnailImage,
                condition: game.condition,
                location: game.location,
                visibility: game.visibility,
                importSource: game.importSource,
                createdAt: game.createdAt,
                updatedAt: game.updatedAt,
                isAvailable: false,
                currentBorrowerId: game.currentBorrowerId,
              );
            });
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon')),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget content;

  const _DetailSection({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanGameSheet extends StatefulWidget {
  final GameModel game;
  final List<FriendModel> friends;
  final FriendsService friendsService;
  final VoidCallback onLoanComplete;

  const _LoanGameSheet({
    required this.game,
    required this.friends,
    required this.friendsService,
    required this.onLoanComplete,
  });

  @override
  State<_LoanGameSheet> createState() => _LoanGameSheetState();
}

class _LoanGameSheetState extends State<_LoanGameSheet> {
  FriendModel? _selectedFriend;
  DateTime? _dueDate;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Loan "${widget.game.title}"',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Friend Selection
          const Text(
            'Select Friend:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<FriendModel>(
              value: _selectedFriend,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: InputBorder.none,
                hintText: 'Choose a friend...',
              ),
              items: widget.friends.map((friend) {
                return DropdownMenuItem(
                  value: friend,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.blue[100],
                        child: friend.friendAvatar?.isNotEmpty == true
                            ? Text(friend.friendAvatar!, style: const TextStyle(fontSize: 14))
                            : Text(friend.friendName[0].toUpperCase(), 
                                   style: const TextStyle(fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              friend.friendName,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${friend.borrowedGamesCount} borrowed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (friend) {
                setState(() => _selectedFriend = friend);
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Due Date
          const Text(
            'Due Date (Optional):',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDueDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    _dueDate != null
                        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                        : 'Select due date...',
                    style: TextStyle(
                      color: _dueDate != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (_dueDate != null)
                    IconButton(
                      onPressed: () => setState(() => _dueDate = null),
                      icon: const Icon(Icons.clear, size: 18),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Add any notes about this loan...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedFriend != null ? _lendGame : null,
                  child: const Text('Loan Game'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  void _lendGame() async {
    if (_selectedFriend == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await widget.friendsService.lendGame(
      gameId: widget.game.gameId,
      borrowerId: _selectedFriend!.friendUserId,
      dueDate: _dueDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    // Hide loading
    if (mounted) Navigator.pop(context);
    
    // Close loan sheet
    if (mounted) Navigator.pop(context);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaned "${widget.game.title}" to ${_selectedFriend!.friendName}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Notify parent to refresh
      widget.onLoanComplete();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to loan game'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}