import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../reports/admin_users_pdf_report.dart';
import '../services/admin_users_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _service = AdminUsersService();
  final _pdfReport = AdminUsersPdfReport();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  String _error = '';

  List<AdminUser> _all = [];
  List<AdminUser> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final users = await _service.getAll();
      if (!mounted) return;

      setState(() {
        _all = users;
        _filtered = users;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _all);
      return;
    }

    setState(() {
      _filtered = _all.where((u) {
        final hay = [
          u.username,
          u.email,
          u.fullName,
          u.phone ?? '',
          u.address ?? '',
          u.roleText,
        ].join(' ').toLowerCase();
        return hay.contains(q);
      }).toList();
    });
  }

  Future<void> _generatePdf() async {
    try {
      await _pdfReport.generate(_filtered);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Greška pri generisanju PDF-a: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeactivate(AdminUser user) async {
    if (user.role == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin se ne može deaktivirati ovdje.')),
      );
      return;
    }

    if (!user.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Korisnik je već deaktiviran.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deaktivacija korisnika'),
        content: Text('Deaktivirati korisnika "${user.username}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deaktiviraj'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.deactivate(user.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Korisnik deaktiviran.')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _confirmDelete(AdminUser user) async {
    if (user.role == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin se ne može obrisati ovdje.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Brisanje korisnika'),
        content: Text(
          'Da li sigurno želiš obrisati korisnika "${user.username}"?\n\nOva akcija se ne može vratiti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _service.delete(user.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Korisnik obrisan.')),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openCreateUserDialog() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CreateUserDialog(service: _service),
    );

    if (created == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Korisnik uspješno dodan.')),
      );
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Pretraga (username, email, ime...)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _openCreateUserDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Add user'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message:
                    'PDF izvještaj korisnika je optimizovan za horizontalni prikaz.',
                child: OutlinedButton.icon(
                  onPressed: _filtered.isEmpty ? null : _generatePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF korisnici'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowHeight: 56,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 72,
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Username')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Ime i prezime')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Aktivan')),
                        DataColumn(label: Text('Akcije')),
                      ],
                      rows: _filtered.map((u) {
                        final activeText = u.isActive ? 'DA' : 'NE';

                        return DataRow(
                          cells: [
                            DataCell(Text(u.id.toString())),
                            DataCell(Text(u.username)),
                            DataCell(Text(u.email)),
                            DataCell(Text(u.fullName)),
                            DataCell(Text(u.roleText)),
                            DataCell(
                              Text(
                                activeText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: u.isActive ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: (u.role == 2 && u.isActive)
                                        ? () => _confirmDeactivate(u)
                                        : null,
                                    child: const Text('Deactivate'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: u.role == 2
                                        ? () => _confirmDelete(u)
                                        : null,
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  final AdminUsersService service;

  const _CreateUserDialog({required this.service});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final RegExp _phoneRegex = RegExp(r'^(\+?\d{8,15})$');

  int _role = 2;
  bool _submitting = false;

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
    _passwordCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
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

    if (msg.contains('first name') || msg.contains('firstname')) {
      _firstNameServerError = message;
      return;
    }

    if (msg.contains('last name') || msg.contains('lastname')) {
      _lastNameServerError = message;
      return;
    }

    if (msg.contains('phone')) {
      _phoneServerError = message;
      return;
    }

    if (msg.contains('address')) {
      _addressServerError = message;
      return;
    }

    _generalError = message;
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
      if (!_phoneRegex.hasMatch(v)) {
        return 'Telefon nije u ispravnom formatu';
      }
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

  Future<void> _submit() async {
    setState(_clearMappedErrors);

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() {
      _submitting = true;
    });

    try {
      await widget.service.create(
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        role: _role,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');

      setState(() {
        _mapServerError(message);
        _submitting = false;
      });

      _formKey.currentState?.validate();
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj korisnika'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_generalError != null && _generalError!.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _generalError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: _validateUsername,
                  onChanged: (_) => _clearFieldError('username'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _validateEmail,
                  onChanged: (_) => _clearFieldError('email'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: _validatePassword,
                  onChanged: (_) => _clearFieldError('password'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(labelText: 'Ime'),
                        validator: _validateFirstName,
                        onChanged: (_) => _clearFieldError('firstName'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(labelText: 'Prezime'),
                        validator: _validateLastName,
                        onChanged: (_) => _clearFieldError('lastName'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Telefon'),
                        validator: _validatePhone,
                        onChanged: (_) => _clearFieldError('phone'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(labelText: 'Adresa'),
                        validator: _validateAddress,
                        onChanged: (_) => _clearFieldError('address'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('Client')),
                    DropdownMenuItem(value: 1, child: Text('Admin')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 2),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Odustani'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}