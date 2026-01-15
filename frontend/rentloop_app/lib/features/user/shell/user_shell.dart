import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/notifications_page.dart';
import '../pages/profile_page.dart';
import '../pages/favorites_page.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;

  final _pages = const [
    HomePage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FavoritesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);
    const navBlue = Color(0xFF0B1C6D); // tamno plava kao na slici

    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------- APP BAR ----------------
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 110,
        titleSpacing: 12,
        leadingWidth: 220,

        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 110,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'RentLoop',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Favoriti',
            icon: const Icon(Icons.favorite_border, size: 34),
            color: blue,
            onPressed: _openFavorites,
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(child: _pages[_index]),

      // ---------------- BOTTOM NAV ----------------
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                color: navBlue,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavIcon(
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                  _NavIcon(
                    icon: Icons.notifications_none,
                    selectedIcon: Icons.notifications,
                    selected: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                  _NavIcon(
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    selected: _index == 2,
                    onTap: () => setState(() => _index = 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- HELPER WIDGET ----------------
class _NavIcon extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withOpacity(0.7);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Icon(
          selected ? selectedIcon : icon,
          color: color,
          size: 38,
        ),
      ),
    );
  }
}
