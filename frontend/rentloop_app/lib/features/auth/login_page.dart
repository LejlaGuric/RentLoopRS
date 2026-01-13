import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../admin/admin_shell.dart';

// ✅ NEW: user shell with top bar + bottom navigation
import '../../features/user/shell/user_shell.dart';

// ✅ NEW: register page
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  String _error = '';

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final result = await _auth.login(
        usernameOrEmail: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;

      if (result.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminShell()),
        );
      } else {
        // ✅ CHANGED: user goes to UserShell (navigation is same on every page)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserShell()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Prijava',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _userCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username ili email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  onSubmitted: (_) => _loading ? null : _login(),
                  decoration: const InputDecoration(
                    labelText: 'Lozinka',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: Text(_loading ? 'Prijava...' : 'Prijavi se'),
                  ),
                ),

                const SizedBox(height: 10),

                // ✅ NEW: register link
                TextButton(
                  onPressed: _loading ? null : _openRegister,
                  child: const Text('Nemaš račun? Registruj se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
