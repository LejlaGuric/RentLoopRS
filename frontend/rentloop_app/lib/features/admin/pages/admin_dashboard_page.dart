import 'package:flutter/material.dart';
import '../models/admin_stats.dart';
import '../services/admin_dashboard_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _service = AdminDashboardService();

  bool _loading = true;
  String _error = '';
  AdminStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final res = await _service.getStats();
      if (!mounted) return;

      setState(() {
        _stats = res;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }

    final s = _stats!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 3;
          if (constraints.maxWidth < 1100) crossAxisCount = 2;

          return GridView.count(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 2.2,
            children: [
              _StatCard(
                title: 'Korisnici',
                value: s.usersCount.toString(),
                icon: Icons.people,
              ),
              _StatCard(
                title: 'Aktivni korisnici',
                value: s.activeUsersCount.toString(),
                icon: Icons.verified_user,
              ),
              _StatCard(
                title: 'Stanovi',
                value: s.listingsCount.toString(),
                icon: Icons.home_work,
              ),
              _StatCard(
                title: 'Rezervacije',
                value: s.reservationsCount.toString(),
                icon: Icons.event_available,
              ),
              _StatCard(
                title: 'Na čekanju',
                value: s.pendingReservations.toString(),
                icon: Icons.hourglass_top,
              ),
              _StatCard(
                title: 'Prosječna ocjena',
                value: s.avgRating.toStringAsFixed(2),
                icon: Icons.star,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 30, color: Colors.blue),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
