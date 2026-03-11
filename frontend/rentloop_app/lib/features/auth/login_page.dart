import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../admin/admin_shell.dart';
import '../../features/user/shell/user_shell.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;

  String? _generalError;
  String? _userServerError;
  String? _passServerError;

  void _clearMappedErrors() {
    _generalError = null;
    _userServerError = null;
    _passServerError = null;
  }

  void _mapServerError(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('usernameoremail')) {
      _userServerError = message;
      return;
    }

    if (msg.contains('username') || msg.contains('email')) {
      _userServerError = message;
      return;
    }

    if (msg.contains('password') || msg.contains('lozinka')) {
      _passServerError = message;
      return;
    }

    if (msg.contains('invalid credentials') || msg.contains('invalid')) {
      _userServerError = 'Pogrešan username/email ili lozinka';
      _passServerError = 'Pogrešan username/email ili lozinka';
      return;
    }

    if (msg.contains('inactive')) {
      _generalError = 'Korisnički račun nije aktivan';
      return;
    }

    _generalError = message;
  }

  void _clearFieldError(String field) {
    setState(() {
      _generalError = null;

      switch (field) {
        case 'user':
          _userServerError = null;
          break;
        case 'pass':
          _passServerError = null;
          break;
      }
    });
  }

  String? _validateUser(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) return 'Username ili email je obavezan';
    if (_userServerError != null) return _userServerError;

    return null;
  }

  String? _validatePass(String? value) {
    final v = value ?? '';

    if (v.isEmpty) return 'Lozinka je obavezna';
    if (_passServerError != null) return _passServerError;

    return null;
  }

  Future<void> _login() async {
    setState(_clearMappedErrors);

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() {
      _loading = true;
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();

      setState(() {
        _loading = false;
        _mapServerError(msg);
      });

      _formKey.currentState?.validate();
      return;
    }

    if (!mounted) return;
    setState(() => _loading = false);
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
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Prijava',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (_generalError != null && _generalError!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _generalError!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  TextFormField(
                    controller: _userCtrl,
                    textInputAction: TextInputAction.next,
                    validator: _validateUser,
                    onChanged: (_) => _clearFieldError('user'),
                    decoration: const InputDecoration(
                      labelText: 'Username ili email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    validator: _validatePass,
                    onChanged: (_) => _clearFieldError('pass'),
                    onFieldSubmitted: (_) => _loading ? null : _login(),
                    decoration: const InputDecoration(
                      labelText: 'Lozinka',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      child: Text(_loading ? 'Prijava...' : 'Prijavi se'),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: _loading ? null : _openRegister,
                    child: const Text('Nemaš račun? Registruj se'),
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