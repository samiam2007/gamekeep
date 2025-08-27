import 'package:flutter/material.dart';
import '../models/friend_model.dart';
import '../services/friends_service.dart';
import 'friend_collection_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FriendsService _friendsService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initService();
  }

  Future<void> _initService() async {
    _friendsService = await FriendsService.getInstance();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Friends'),
            Tab(text: 'Loans'),
            Tab(text: 'Activity'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _FriendsListTab(friendsService: _friendsService),
              _LoansTab(friendsService: _friendsService),
              _ActivityTab(friendsService: _friendsService),
            ],
          ),
        ),
      ],
    );
  }
}

class _FriendsListTab extends StatefulWidget {
  final FriendsService friendsService;
  
  const _FriendsListTab({required this.friendsService});

  @override
  State<_FriendsListTab> createState() => _FriendsListTabState();
}

class _FriendsListTabState extends State<_FriendsListTab> {
  List<FriendModel> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final friends = await widget.friendsService.getFriends(status: FriendStatus.accepted);
    setState(() {
      _friends = friends;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadFriends,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.person_add, color: Colors.blue),
                title: const Text('Add Friends'),
                subtitle: const Text('Connect with other GameKeep users'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _showAddFriendDialog(context);
                },
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                    ? _buildEmptyState()
                    : _buildFriendsList(),
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
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No friends yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to share your collection',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddFriendDialog(context),
            icon: const Icon(Icons.qr_code),
            label: const Text('Share QR Code'),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        final friend = _friends[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: friend.friendAvatar?.isNotEmpty == true
                  ? Text(friend.friendAvatar!, style: const TextStyle(fontSize: 20))
                  : Text(friend.friendName[0].toUpperCase()),
            ),
            title: Text(friend.friendName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.friendEmail),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${friend.sharedGamesCount} games', 
                         style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 16),
                    Text('Borrowed: ${friend.borrowedGamesCount}', 
                         style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                    const SizedBox(width: 8),
                    Text('Lent: ${friend.lentGamesCount}', 
                         style: TextStyle(fontSize: 12, color: Colors.green[700])),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleFriendAction(value, friend),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Profile')),
                const PopupMenuItem(value: 'collection', child: Text('View Collection')),
                const PopupMenuItem(value: 'remove', child: Text('Remove Friend')),
              ],
            ),
            onTap: () => _showFriendProfile(friend),
          ),
        );
      },
    );
  }

  void _handleFriendAction(String action, FriendModel friend) {
    switch (action) {
      case 'view':
        _showFriendProfile(friend);
        break;
      case 'collection':
        _showFriendCollection(friend);
        break;
      case 'remove':
        _showRemoveFriendDialog(friend);
        break;
    }
  }

  void _showFriendProfile(FriendModel friend) {
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
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue[100],
                child: friend.friendAvatar?.isNotEmpty == true
                    ? Text(friend.friendAvatar!, style: const TextStyle(fontSize: 32))
                    : Text(friend.friendName[0].toUpperCase(), 
                           style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 16),
              Text(
                friend.friendName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                friend.friendEmail,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard(
                    title: 'Games',
                    value: '${friend.sharedGamesCount}',
                    icon: Icons.casino,
                  ),
                  _StatCard(
                    title: 'Borrowed',
                    value: '${friend.borrowedGamesCount}',
                    icon: Icons.call_received,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Lent',
                    value: '${friend.lentGamesCount}',
                    icon: Icons.call_made,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showFriendCollection(friend);
                      },
                      child: const Text('View Collection'),
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

  void _showFriendCollection(FriendModel friend) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendCollectionScreen(friend: friend),
      ),
    );
  }

  void _showRemoveFriendDialog(FriendModel friend) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: Text('Are you sure you want to remove ${friend.friendName} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.friendsService.removeFriend(friend.friendId);
              _loadFriends();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed ${friend.friendName}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    // Add friend dialog with form
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Friend',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Friend\'s Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Friend\'s Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
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
                      onPressed: () async {
                        if (emailController.text.isNotEmpty && nameController.text.isNotEmpty) {
                          Navigator.pop(context);
                          final success = await widget.friendsService.sendFriendRequest(
                            emailController.text,
                            nameController.text,
                          );
                          if (mounted) {
                            if (success) {
                              _loadFriends(); // Refresh the friends list
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Friend request sent!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to send request'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Send Request'),
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
}

class _LoansTab extends StatefulWidget {
  final FriendsService friendsService;
  
  const _LoansTab({required this.friendsService});

  @override
  State<_LoansTab> createState() => _LoansTabState();
}

class _LoansTabState extends State<_LoansTab> {
  List<LoanModel> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    final loans = await widget.friendsService.getLoans();
    setState(() {
      _loans = loans;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadLoans,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? _buildEmptyState()
              : _buildLoansList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No active loans',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Loaned games will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoansList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loans.length,
      itemBuilder: (context, index) {
        final loan = _loans[index];
        final isOverdue = loan.status == LoanStatus.overdue;
        final daysUntilDue = loan.dueDate?.difference(DateTime.now()).inDays ?? 0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isOverdue ? Colors.red[50] : null,
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isOverdue ? Colors.red[100] : Colors.grey[200],
              ),
              child: Icon(
                Icons.casino, 
                color: isOverdue ? Colors.red[600] : Colors.grey,
              ),
            ),
            title: Text(
              loan.gameTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isOverdue ? Colors.red[800] : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loaned to: ${loan.borrowerName}'),
                const SizedBox(height: 4),
                Text(
                  'Loaned: ${_formatDate(loan.loanDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (loan.notes?.isNotEmpty == true)
                  Text(
                    'Note: ${loan.notes}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (loan.status == LoanStatus.returned)
                  const Icon(Icons.check_circle, color: Colors.green)
                else if (isOverdue)
                  Text(
                    'OVERDUE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  )
                else if (loan.dueDate != null) ...[
                  const Text('Due in', style: TextStyle(fontSize: 12)),
                  Text(
                    '$daysUntilDue days',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: daysUntilDue <= 3 ? Colors.orange[700] : Colors.blue[700],
                    ),
                  ),
                ],
                PopupMenuButton<String>(
                  onSelected: (value) => _handleLoanAction(value, loan),
                  itemBuilder: (context) => [
                    if (loan.status == LoanStatus.active)
                      const PopupMenuItem(value: 'return', child: Text('Mark Returned')),
                    const PopupMenuItem(value: 'details', child: Text('View Details')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleLoanAction(String action, LoanModel loan) {
    switch (action) {
      case 'return':
        _showReturnConfirmation(loan);
        break;
      case 'details':
        _showLoanDetails(loan);
        break;
    }
  }

  void _showReturnConfirmation(LoanModel loan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Game'),
        content: Text('Mark "${loan.gameTitle}" as returned from ${loan.borrowerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.friendsService.returnGame(loan.loanId);
              _loadLoans();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Game marked as returned')),
                );
              }
            },
            child: const Text('Mark Returned'),
          ),
        ],
      ),
    );
  }

  void _showLoanDetails(LoanModel loan) {
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
                loan.gameTitle,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _DetailRow('Borrower:', loan.borrowerName),
              _DetailRow('Loaned:', _formatDate(loan.loanDate)),
              if (loan.dueDate != null) _DetailRow('Due:', _formatDate(loan.dueDate!)),
              if (loan.returnDate != null) _DetailRow('Returned:', _formatDate(loan.returnDate!)),
              _DetailRow('Status:', _getStatusText(loan.status)),
              if (loan.notes?.isNotEmpty == true) 
                _DetailRow('Notes:', loan.notes!),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusText(LoanStatus status) {
    switch (status) {
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.overdue:
        return 'Overdue';
      case LoanStatus.returned:
        return 'Returned';
      case LoanStatus.lost:
        return 'Lost';
    }
  }
}

class _ActivityTab extends StatefulWidget {
  final FriendsService friendsService;
  
  const _ActivityTab({required this.friendsService});

  @override
  State<_ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<_ActivityTab> {
  List<ActivityItem> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    final loans = await widget.friendsService.getLoans();
    final friends = await widget.friendsService.getFriends();
    
    List<ActivityItem> activities = [];
    
    // Add loan activities
    for (final loan in loans) {
      activities.add(ActivityItem(
        type: ActivityType.loanCreated,
        title: '${loan.gameTitle} loaned to ${loan.borrowerName}',
        subtitle: loan.dueDate != null 
          ? 'Due ${_formatDate(loan.dueDate!)}'
          : 'No due date set',
        timestamp: loan.loanDate,
        icon: Icons.card_giftcard,
        iconColor: Colors.blue,
      ));
      
      if (loan.returnDate != null) {
        activities.add(ActivityItem(
          type: ActivityType.gameReturned,
          title: '${loan.gameTitle} returned by ${loan.borrowerName}',
          subtitle: 'Returned on ${_formatDate(loan.returnDate!)}',
          timestamp: loan.returnDate!,
          icon: Icons.assignment_return,
          iconColor: Colors.green,
        ));
      }
    }
    
    // Add friend activities
    for (final friend in friends.where((f) => f.status == FriendStatus.accepted)) {
      activities.add(ActivityItem(
        type: ActivityType.friendAdded,
        title: '${friend.friendName} became your friend',
        subtitle: friend.acceptedAt != null 
          ? 'Connected on ${_formatDate(friend.acceptedAt!)}'
          : 'Recently connected',
        timestamp: friend.acceptedAt ?? friend.createdAt,
        icon: Icons.person_add,
        iconColor: Colors.purple,
      ));
    }
    
    // Sort by timestamp (newest first)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    setState(() {
      _activities = activities.take(20).toList(); // Show last 20 activities
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadActivity,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? _buildEmptyState()
              : _buildActivityList(),
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No activity yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Friend activities will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: activity.iconColor.withOpacity(0.2),
              child: Icon(activity.icon, color: activity.iconColor),
            ),
            title: Text(
              activity.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.subtitle),
                const SizedBox(height: 4),
                Text(
                  _getTimeAgo(activity.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 7) {
      return _formatDate(timestamp);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class ActivityItem {
  final ActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color iconColor;

  ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.iconColor,
  });
}

enum ActivityType {
  friendAdded,
  loanCreated,
  gameReturned,
  gameAdded,
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: color ?? Colors.blue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}