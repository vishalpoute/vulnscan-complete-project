import 'package:flutter/material.dart';
import 'package:vulnscan/config/routing/app_router.dart';

class MainAppShell extends StatefulWidget {
  final Widget child;

  const MainAppShell({
    required this.child,
    super.key,
  });

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  void _navigateTo(String route, int index) {
    setState(() => _selectedIndex = index);
    AppNavigator.pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        body: widget.child,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                _navigateTo(AppRoutes.dashboard, 0);
              case 1:
                _navigateTo(AppRoutes.scans, 1);
              case 2:
                _navigateTo(AppRoutes.settings, 2);
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Scans'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    _navigateTo(AppRoutes.dashboard, 0);
                  case 1:
                    _navigateTo(AppRoutes.scans, 1);
                  case 2:
                    _navigateTo(AppRoutes.settings, 2);
                }
              },
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.security), label: Text('Scans')),
                NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    }
  }
}
