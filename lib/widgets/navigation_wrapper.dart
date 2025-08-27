import 'package:flutter/material.dart';
import '../utils/theme.dart';

class NavigationWrapper extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final bool showNavigation;

  const NavigationWrapper({
    Key? key,
    required this.child,
    this.currentIndex = 0,
    this.showNavigation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showNavigation) {
      return child;
    }

    return Scaffold(
      body: child,
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
          currentIndex: currentIndex,
          onTap: (index) {
            // Navigate based on index
            switch (index) {
              case 0:
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                break;
              case 1:
                Navigator.pushNamed(context, '/friends');
                break;
              case 2:
                Navigator.pushNamed(context, '/discover');
                break;
              case 3:
                Navigator.pushNamed(context, '/profile');
                break;
            }
          },
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
    );
  }
}