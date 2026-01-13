import 'package:flutter/material.dart';
import '../models/admin_user.dart';
import '../services/admin_users_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _service = AdminUsersService();
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
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deaktiviraj')),
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

      await _load(); // refresh liste
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ✅ NOVO: Add User modal
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
            ElevatedButton(onPressed: _load, child: const Text('Pokušaj ponovo')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header: Search + Add + Refresh
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Pretraga (username, email, ime...)',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ✅ NOVO: Add user
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
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Card(
              elevation: 1.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowHeight: 56,
                      dataRowMinHeight: 56,
                      dataRowMaxHeight: 64,
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

// ✅ DIALOG WIDGET: Create user forma
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

  int _role = 2; // default Client
  bool _submitting = false;
  String _error = '';

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

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() {
      _submitting = true;
      _error = '';
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
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dodaj korisnika'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_error, style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 10),
                ],

                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Username je obavezan' : null,
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email je obavezan';
                    if (!v.contains('@')) return 'Unesi validan email';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password je obavezan';
                    if (v.length < 6) return 'Password min 6 karaktera';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameCtrl,
                        decoration: const InputDecoration(labelText: 'Ime'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameCtrl,
                        decoration: const InputDecoration(labelText: 'Prezime'),
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
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _addressCtrl,
                        decoration: const InputDecoration(labelText: 'Adresa'),
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
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
