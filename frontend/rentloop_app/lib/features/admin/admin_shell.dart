import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_page.dart';
import 'pages/admin_dashboard_page.dart';
import 'pages/admin_users_page.dart';
import 'pages/admin_listings_page.dart';
import 'pages/admin_reservations_page.dart';
import 'pages/admin_chat_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _pages = const [
  AdminDashboardPage(),
  AdminListingsPage(),
  AdminUsersPage(),
  AdminChatPage(),
  AdminReservationsPage(),
];


  final _titles = const [
    'Dashboard',
    'Stanovi',
    'Korisnici',
    'Chat',
    'Rezervacije',
  ];

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Desktop: sidebar + content
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                const Text(
                  'RentLoop Admin',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _SideItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _SideItem(
                  icon: Icons.home_work,
                  title: 'Stanovi',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _SideItem(
                  icon: Icons.people,
                  title: 'Korisnici',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _SideItem(
                  icon: Icons.chat,
                  title: 'Chat',
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
                _SideItem(
                  icon: Icons.event_available,
                  title: 'Rezervacije',
                  selected: _index == 4,
                  onTap: () => setState(() => _index = 4),
                ),

                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Text(
                    _titles[_index],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),

                // Page
                Expanded(
                  child: _pages[_index],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _SideItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.blue.withOpacity(0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.blueAccent : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
