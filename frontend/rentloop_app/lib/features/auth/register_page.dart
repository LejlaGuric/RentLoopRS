import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final RegExp _phoneRegex = RegExp(r'^(\+?\d{8,15})$');

  bool _loading = false;

  String? _generalError;
  String? _usernameServerError;
  String? _emailServerError;
  String? _passwordServerError;
  String? _firstNameServerError;
  String? _lastNameServerError;
  String? _phoneServerError;
  String? _addressServerError;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  void _clearMappedErrors() {
    _generalError = null;
    _usernameServerError = null;
    _emailServerError = null;
    _passwordServerError = null;
    _firstNameServerError = null;
    _lastNameServerError = null;
    _phoneServerError = null;
    _addressServerError = null;
  }

  void _mapServerError(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('username')) {
      _usernameServerError = message;
      return;
    }

    if (msg.contains('email')) {
      _emailServerError = message;
      return;
    }

    if (msg.contains('password')) {
      _passwordServerError = message;
      return;
    }

    if (msg.contains('first name') || msg.contains('firstname') || msg.contains('ime')) {
      _firstNameServerError = message;
      return;
    }

    if (msg.contains('last name') || msg.contains('lastname') || msg.contains('prezime')) {
      _lastNameServerError = message;
      return;
    }

    if (msg.contains('phone') || msg.contains('telefon')) {
      _phoneServerError = message;
      return;
    }

    if (msg.contains('address') || msg.contains('adresa')) {
      _addressServerError = message;
      return;
    }

    _generalError = message;
  }

  void _clearFieldError(String field) {
    setState(() {
      _generalError = null;

      switch (field) {
        case 'username':
          _usernameServerError = null;
          break;
        case 'email':
          _emailServerError = null;
          break;
        case 'password':
          _passwordServerError = null;
          break;
        case 'firstName':
          _firstNameServerError = null;
          break;
        case 'lastName':
          _lastNameServerError = null;
          break;
        case 'phone':
          _phoneServerError = null;
          break;
        case 'address':
          _addressServerError = null;
          break;
      }
    });
  }

  String? _validateUsername(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) return 'Username je obavezan';
    if (v.length > 50) return 'Username može imati najviše 50 karaktera';
    if (_usernameServerError != null) return _usernameServerError;

    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) return 'Email je obavezan';
    if (v.length > 100) return 'Email može imati najviše 100 karaktera';
    if (!_emailRegex.hasMatch(v)) return 'Email format nije ispravan';
    if (_emailServerError != null) return _emailServerError;

    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';

    if (v.isEmpty) return 'Password je obavezan';
    if (v.length < 6) return 'Password mora imati najmanje 6 karaktera';
    if (v.length > 100) return 'Password može imati najviše 100 karaktera';
    if (_passwordServerError != null) return _passwordServerError;

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final v = value ?? '';

    if (v.isEmpty) return 'Potvrda passworda je obavezna';
    if (v != _passCtrl.text) return 'Passwordi se ne podudaraju';

    return null;
  }

  String? _validateFirstName(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) return 'Ime je obavezno';
    if (v.length > 50) return 'Ime može imati najviše 50 karaktera';
    if (_firstNameServerError != null) return _firstNameServerError;

    return null;
  }

  String? _validateLastName(String? value) {
    final v = value?.trim() ?? '';

    if (v.isEmpty) return 'Prezime je obavezno';
    if (v.length > 50) return 'Prezime može imati najviše 50 karaktera';
    if (_lastNameServerError != null) return _lastNameServerError;

    return null;
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';

    if (v.isNotEmpty) {
      if (v.length > 30) return 'Telefon može imati najviše 30 karaktera';
      if (!_phoneRegex.hasMatch(v)) return 'Telefon nije u ispravnom formatu';
    }

    if (_phoneServerError != null) return _phoneServerError;
    return null;
  }

  String? _validateAddress(String? value) {
    final v = value?.trim() ?? '';

    if (v.length > 200) return 'Adresa može imati najviše 200 karaktera';
    if (_addressServerError != null) return _addressServerError;

    return null;
  }

  Future<void> _submit() async {
    setState(_clearMappedErrors);

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() {
      _loading = true;
    });

    try {
      await _auth.register(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        firstName: _firstCtrl.text.trim(),
        lastName: _lastCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uspješno ste registrovani. Sada se prijavite.')),
      );

      Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registracija'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      if (_generalError != null && _generalError!.isNotEmpty) ...[
                        Text(
                          _generalError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateUsername,
                        onChanged: (_) => _clearFieldError('username'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateEmail,
                        onChanged: (_) => _clearFieldError('email'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: _validatePassword,
                        onChanged: (_) {
                          _clearFieldError('password');
                          _formKey.currentState?.validate();
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pass2Ctrl,
                        decoration: const InputDecoration(
                          labelText: 'Potvrdi password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: _validateConfirmPassword,
                        onChanged: (_) => _formKey.currentState?.validate(),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Lični podaci',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Ime',
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateFirstName,
                              onChanged: (_) => _clearFieldError('firstName'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Prezime',
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateLastName,
                              onChanged: (_) => _clearFieldError('lastName'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Telefon',
                                border: OutlineInputBorder(),
                              ),
                              validator: _validatePhone,
                              onChanged: (_) => _clearFieldError('phone'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _addressCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Adresa',
                                border: OutlineInputBorder(),
                              ),
                              validator: _validateAddress,
                              onChanged: (_) => _clearFieldError('address'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Registruj se'),
                      ),
                      const SizedBox(height: 10),

                      TextButton(
                        onPressed: _loading ? null : () => Navigator.pop(context),
                        child: const Text('Već imaš račun? Prijavi se'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}