import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../features/auth/login_page.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await AuthService().logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            }
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
