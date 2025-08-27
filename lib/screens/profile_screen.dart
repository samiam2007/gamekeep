import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/game_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final gameProvider = context.watch<GameProvider>();
    final user = userProvider.currentUser;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: user?.avatar != null
                      ? ClipOval(
                          child: Image.network(
                            user!.avatar!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.displayName ?? 'GameKeep User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                if (user?.bggUsername != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'BGG: ${user!.bggUsername}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Statistics
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  value: gameProvider.totalGames.toString(),
                  label: 'Games',
                  icon: Icons.casino,
                ),
                _StatItem(
                  value: gameProvider.totalPlays.toString(),
                  label: 'Plays',
                  icon: Icons.play_circle,
                ),
                _StatItem(
                  value: gameProvider.loanedGames.toString(),
                  label: 'Loaned',
                  icon: Icons.card_giftcard,
                ),
                _StatItem(
                  value: '0',
                  label: 'Friends',
                  icon: Icons.people,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Menu Options
          _MenuSection(
            title: 'Collection',
            items: [
              _MenuItem(
                icon: Icons.download,
                title: 'Import from BGG',
                subtitle: 'Sync your BoardGameGeek collection',
                onTap: () => _showBGGImportDialog(context),
              ),
              _MenuItem(
                icon: Icons.upload,
                title: 'Export Collection',
                subtitle: 'Download your library as CSV',
                onTap: () {
                  // TODO: Export collection
                },
              ),
              _MenuItem(
                icon: Icons.history,
                title: 'Play History',
                subtitle: 'View all your game sessions',
                onTap: () {
                  // TODO: Navigate to play history
                },
              ),
            ],
          ),

          _MenuSection(
            title: 'Settings',
            items: [
              _MenuItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your information',
                onTap: () {
                  // TODO: Edit profile
                },
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage push notifications',
                onTap: () {
                  // TODO: Notification settings
                },
              ),
              _MenuItem(
                icon: Icons.dark_mode_outlined,
                title: 'Appearance',
                subtitle: 'Theme and display options',
                onTap: () {
                  // TODO: Theme settings
                },
              ),
            ],
          ),

          _MenuSection(
            title: 'About',
            items: [
              _MenuItem(
                icon: Icons.star_outline,
                title: 'Rate GameKeep',
                subtitle: 'Help us improve with your feedback',
                onTap: () {
                  // TODO: Open app store
                },
              ),
              _MenuItem(
                icon: Icons.share_outlined,
                title: 'Share GameKeep',
                subtitle: 'Tell your friends about us',
                onTap: () {
                  // TODO: Share app
                },
              ),
              _MenuItem(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version 1.0.0',
                onTap: () {
                  // TODO: Show about dialog
                },
              ),
            ],
          ),

          // Sign Out Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthService>().signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showBGGImportDialog(BuildContext context) {
    final usernameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import from BGG'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your BoardGameGeek username to import your collection:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'BGG Username',
                  hintText: 'e.g., johndoe',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (usernameController.text.isNotEmpty) {
                  // Show loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Importing collection...'),
                      duration: Duration(seconds: 30),
                    ),
                  );
                  
                  try {
                    await context.read<GameProvider>().importFromBGG(
                      usernameController.text,
                    );
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Collection imported successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Import failed: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
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

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}