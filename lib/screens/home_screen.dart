import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/friends_service.dart';
import '../models/friend_model.dart';
import '../providers/game_provider.dart';
import 'library_screen.dart';
import 'friends_screen.dart';
import 'discover_screen_enhanced_v2.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _overdueLoansCount = 0;
  int _pendingRequestsCount = 0;
  
  final List<Widget> _screens = [
    const LibraryScreen(),
    const FriendsScreen(),
    const DiscoverScreenEnhanced(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'My Library',
    'Friends',
    'Discover',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() {
      context.read<GameProvider>().loadUserGames();
      _checkOverdueLoans();
      _checkPendingRequests();
    });
  }

  Future<void> _checkOverdueLoans() async {
    try {
      final friendsService = await FriendsService.getInstance();
      final overdueLoans = await friendsService.getLoans(status: LoanStatus.overdue);
      final activeDueLoans = await friendsService.getLoans(status: LoanStatus.active);
      
      // Check for loans due in the next 2 days
      final now = DateTime.now();
      final dueSoonLoans = activeDueLoans.where((loan) {
        if (loan.dueDate == null) return false;
        final daysUntilDue = loan.dueDate!.difference(now).inDays;
        return daysUntilDue <= 2 && daysUntilDue >= 0;
      }).toList();
      
      if (overdueLoans.isNotEmpty || dueSoonLoans.isNotEmpty) {
        setState(() {
          _overdueLoansCount = overdueLoans.length + dueSoonLoans.length;
        });
        
        // Show loan reminder notification
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _showLoanReminders(overdueLoans, dueSoonLoans);
          }
        });
      }
    } catch (e) {
      print('Error checking overdue loans: $e');
    }
  }

  void _showLoanReminders(List<LoanModel> overdueLoans, List<LoanModel> dueSoonLoans) {
    if (overdueLoans.isEmpty && dueSoonLoans.isEmpty) return;
    
    final totalCount = overdueLoans.length + dueSoonLoans.length;
    String title = 'Loan Reminders';
    String message;
    
    if (overdueLoans.isNotEmpty && dueSoonLoans.isNotEmpty) {
      message = '${overdueLoans.length} overdue, ${dueSoonLoans.length} due soon';
    } else if (overdueLoans.isNotEmpty) {
      message = '${overdueLoans.length} ${overdueLoans.length == 1 ? 'loan is' : 'loans are'} overdue';
    } else {
      message = '${dueSoonLoans.length} ${dueSoonLoans.length == 1 ? 'loan is' : 'loans are'} due soon';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              overdueLoans.isNotEmpty ? Icons.warning : Icons.schedule,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: overdueLoans.isNotEmpty ? Colors.red : Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            setState(() => _currentIndex = 1); // Go to Friends tab
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          _buildNotificationIcon(),
          if (_currentIndex == 0) // Library screen actions
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search
              },
            ),
          if (_currentIndex == 3) // Profile screen actions
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: Navigate to settings
              },
            ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.casino_outlined),
            selectedIcon: Icon(Icons.casino),
            label: 'Library',
          ),
          NavigationDestination(
            icon: _buildFriendsIcon(false),
            selectedIcon: _buildFriendsIcon(true),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/camera');
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Game'),
      ) : null,
    );
  }

  Future<void> _checkPendingRequests() async {
    try {
      final friendsService = await FriendsService.getInstance();
      final pendingRequests = await friendsService.getFriends(status: FriendStatus.pending);
      
      setState(() {
        _pendingRequestsCount = pendingRequests.length;
      });
    } catch (e) {
      print('Error checking pending requests: $e');
    }
  }

  Widget _buildNotificationIcon() {
    final hasNotifications = _pendingRequestsCount > 0;
    
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: _showNotifications,
        ),
        if (hasNotifications)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(
                minWidth: 12,
                minHeight: 12,
              ),
              child: Text(
                '$_pendingRequestsCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotifications() async {
    final friendsService = await FriendsService.getInstance();
    final pendingRequests = await friendsService.getFriends(status: FriendStatus.pending);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _NotificationsSheet(
          pendingRequests: pendingRequests,
          friendsService: friendsService,
          onRequestHandled: () {
            _checkPendingRequests();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildFriendsIcon(bool selected) {
    final icon = Icon(selected ? Icons.people : Icons.people_outline);
    
    if (_overdueLoansCount == 0) {
      return icon;
    }
    
    return Stack(
      children: [
        icon,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: const BoxConstraints(
              minWidth: 12,
              minHeight: 12,
            ),
            child: Text(
              '$_overdueLoansCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  final List<FriendModel> pendingRequests;
  final FriendsService friendsService;
  final VoidCallback onRequestHandled;

  const _NotificationsSheet({
    required this.pendingRequests,
    required this.friendsService,
    required this.onRequestHandled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (pendingRequests.isNotEmpty)
                Chip(
                  label: Text('${pendingRequests.length}'),
                  backgroundColor: Colors.red[100],
                  labelStyle: TextStyle(color: Colors.red[800], fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (pendingRequests.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No new notifications',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const Text(
              'Friend Requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...pendingRequests.map((request) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: request.friendAvatar?.isNotEmpty == true
                      ? Text(request.friendAvatar!, style: const TextStyle(fontSize: 20))
                      : Text(request.friendName[0].toUpperCase()),
                ),
                title: Text(request.friendName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.friendEmail),
                    const SizedBox(height: 4),
                    Text(
                      'Sent ${_formatDate(request.createdAt)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _handleRequest(context, request, false),
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Decline',
                    ),
                    IconButton(
                      onPressed: () => _handleRequest(context, request, true),
                      icon: const Icon(Icons.check, color: Colors.green),
                      tooltip: 'Accept',
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  void _handleRequest(BuildContext context, FriendModel request, bool accept) async {
    final success = accept
        ? await friendsService.acceptFriendRequest(request.friendId)
        : await friendsService.declineFriendRequest(request.friendId);

    if (success) {
      onRequestHandled();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept
              ? 'Friend request accepted!'
              : 'Friend request declined'),
          backgroundColor: accept ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}