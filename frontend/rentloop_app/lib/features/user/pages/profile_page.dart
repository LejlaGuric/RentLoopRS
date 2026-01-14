import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';

import '../services/user_service.dart';
import '../services/reservations_service.dart';

// ✅ AuthService za change password + logout
import '../../../core/services/auth_service.dart';

// ✅ LoginPage
import '../../auth/login_page.dart';

// ✅ Reviews
import '../services/reviews_service.dart';
import '../models/review_create_request.dart';

// ✅ Payments
import '../services/payments_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _users = UserService();
  final _resv = ReservationsService();
  final _auth = AuthService();
  final _reviews = ReviewsService();
  final _payments = PaymentsService();

  // ✅ Deep link listener (PayPal return/cancel)
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;

  // ✅ zapamti koju rezervaciju plaćamo dok smo u PayPalu
  int? _pendingReservationId;

  bool _loading = true;
  String _error = '';

  UserProfileDto? _me;
  List<MyReservationDto> _myReservations = [];

  bool _editing = false;

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();

    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      // očekujemo:
      // rentloop://paypal-return?token=ORDER_ID
      // rentloop://paypal-cancel
      if (uri.scheme != 'rentloop') return;

      if (uri.host == 'paypal-return') {
        final orderId = uri.queryParameters['token'];
        if (orderId == null || _pendingReservationId == null) return;

        try {
          final status = await _payments.capturePayPal(_pendingReservationId!, orderId);

          if (!mounted) return;

          if (status == 'COMPLETED') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plaćanje uspješno ✅')),
            );
            _pendingReservationId = null;
            await _load();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('PayPal status: $status')),
            );
          }
        } catch (e) {
          if (!mounted) return;
          final msg = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Capture greška: $msg')),
          );
        }
      }

      if (uri.host == 'paypal-cancel') {
        if (!mounted) return;
        _pendingReservationId = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plaćanje otkazano.')),
        );
      }
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final me = await _users.me();
      final reservations = await _resv.myReservations();

      _me = me;
      _myReservations = reservations;

      _firstName.text = me.firstName ?? '';
      _lastName.text = me.lastName ?? '';
      _phone.text = me.phone ?? '';
      _address.text = me.address ?? '';

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      });
    }
  }

  Future<void> _save() async {
    if (_me == null) return;

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final req = UpdateMeRequest(
        firstName: _firstName.text.trim().isEmpty ? null : _firstName.text.trim(),
        lastName: _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
      );

      final updated = await _users.updateMe(req);

      _me = updated;
      _editing = false;

      setState(() => _loading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil uspješno sačuvan ✅')),
        );
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      });
    }
  }

  Future<void> _payReservation(MyReservationDto r) async {
    try {
      final created = await _payments.createPayPalOrder(r.id);

      // zapamti rezervaciju dok smo u PayPalu
      _pendingReservationId = r.id;

      if (!mounted) return;

      final uri = Uri.parse(created.approveUrl);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ne mogu otvoriti PayPal link.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PayPal greška: $msg')),
      );
    }
  }

  // ✅ Logout
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Odjava'),
        content: const Text('Da li ste sigurni da se želite odjaviti?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Odustani')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Odjavi se')),
        ],
      ),
    );

    if (ok != true) return;

    await _auth.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  // ✅ Change password dialog
  void _openChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    bool loading = false;
    String error = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> submit() async {
              if (currentCtrl.text.isEmpty || newCtrl.text.isEmpty || confirmCtrl.text.isEmpty) {
                setStateDialog(() => error = 'Sva polja su obavezna.');
                return;
              }

              if (newCtrl.text.length < 6) {
                setStateDialog(() => error = 'Nova lozinka mora imati min 6 karaktera.');
                return;
              }

              if (newCtrl.text != confirmCtrl.text) {
                setStateDialog(() => error = 'Lozinke se ne podudaraju.');
                return;
              }

              setStateDialog(() {
                loading = true;
                error = '';
              });

              try {
                await _auth.changePassword(
                  currentPassword: currentCtrl.text,
                  newPassword: newCtrl.text,
                );

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lozinka uspješno promijenjena 🔐')),
                );
              } catch (e) {
                setStateDialog(() {
                  loading = false;
                  error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
                });
              }
            }

            return AlertDialog(
              title: const Text('Promjena lozinke'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(error, style: const TextStyle(color: Colors.red)),
                      ),
                    TextField(
                      controller: currentCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Trenutna lozinka',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: newCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nova lozinka',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Potvrdi novu lozinku',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          currentCtrl.dispose();
                          newCtrl.dispose();
                          confirmCtrl.dispose();
                          Navigator.pop(ctx);
                        },
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Sačuvaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ✅ Rezervacije -> akcije
  void _openReservationActions(MyReservationDto r) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                r.listingTitle.isEmpty ? 'Rezervacija #${r.id}' : r.listingTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                '${_fmtDate(r.from)} → ${_fmtDate(r.to)}',
                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),

              if (r.statusId == 2) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openReviewDialog(r);
                    },
                    icon: const Icon(Icons.star_rate),
                    label: const Text('Ocijeni boravak'),
                  ),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _payReservation(r);
                    },
                    icon: const Icon(Icons.payments),
                    label: const Text('Plati (PayPal)'),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Text(
                    r.statusId == 1
                        ? 'Rezervacija je na čekanju (Pending).'
                        : r.statusId == 3
                            ? 'Rezervacija je odbijena (Rejected).'
                            : 'Rezervacija nije odobrena.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Zatvori'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Dialog za ocjenu
  void _openReviewDialog(MyReservationDto r) {
    int rating = 5;
    final commentCtrl = TextEditingController();
    bool loading = false;
    String error = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            Future<void> submit() async {
              final comment = commentCtrl.text.trim();

              if (comment.isEmpty) {
                setStateDialog(() => error = 'Komentar je obavezan.');
                return;
              }
              if (rating < 1 || rating > 5) {
                setStateDialog(() => error = 'Ocjena mora biti između 1 i 5.');
                return;
              }

              setStateDialog(() {
                loading = true;
                error = '';
              });

              try {
                final msg = await _reviews.createReview(
                  ReviewCreateRequest(
                    reservationId: r.id,
                    rating: rating,
                    comment: comment,
                  ),
                );

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

                await _load(); // refresh
              } catch (e) {
                setStateDialog(() {
                  loading = false;
                  error = e.toString().replaceFirst('Exception: ', '').replaceAll('"', '').trim();
                });
              }
            }

            return AlertDialog(
              title: const Text('Ocijeni boravak'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(error, style: const TextStyle(color: Colors.red)),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final star = i + 1;
                        final filled = star <= rating;
                        return IconButton(
                          onPressed: loading ? null : () => setStateDialog(() => rating = star),
                          icon: Icon(
                            filled ? Icons.star : Icons.star_border,
                            size: 30,
                            color: filled ? Colors.amber : Colors.black45,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentCtrl,
                      enabled: !loading,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Komentar',
                        border: OutlineInputBorder(),
                        hintText: 'Npr. čisto, lokacija super, sve preporuke…',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () {
                          commentCtrl.dispose();
                          Navigator.pop(ctx);
                        },
                  child: const Text('Odustani'),
                ),
                ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Pošalji'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _roleName(int role) {
    if (role == 1) return 'Admin';
    if (role == 2) return 'Korisnik';
    return 'Nepoznato';
  }

  String _statusLabel(int statusId, String fallback) {
    if (statusId == 1) return 'Pending';
    if (statusId == 2) return 'Approved';
    if (statusId == 3) return 'Rejected';
    return fallback.isNotEmpty ? fallback : 'Status $statusId';
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text('Moj profil'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _error.isNotEmpty
          ? _ErrorBox(message: _error, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ProfileHeader(
                    username: _me!.username,
                    email: _me!.email,
                    role: _roleName(_me!.role),
                    active: _me!.isActive,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openChangePasswordDialog,
                    icon: const Icon(Icons.lock),
                    label: const Text('Promijeni lozinku'),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'Podaci',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_editing)
                          TextButton.icon(
                            onPressed: () => setState(() => _editing = true),
                            icon: const Icon(Icons.edit, color: blue),
                            label: const Text('Edit', style: TextStyle(color: blue)),
                          )
                        else ...[
                          TextButton(
                            onPressed: () {
                              final me = _me!;
                              _firstName.text = me.firstName ?? '';
                              _lastName.text = me.lastName ?? '';
                              _phone.text = me.phone ?? '';
                              _address.text = me.address ?? '';
                              setState(() => _editing = false);
                            },
                            child: const Text('Odustani'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save),
                            label: const Text('Sačuvaj'),
                          ),
                        ],
                      ],
                    ),
                    child: Column(
                      children: [
                        _Field(label: 'Ime', controller: _firstName, enabled: _editing),
                        const SizedBox(height: 12),
                        _Field(label: 'Prezime', controller: _lastName, enabled: _editing),
                        const SizedBox(height: 12),
                        _Field(
                          label: 'Telefon',
                          controller: _phone,
                          enabled: _editing,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _Field(label: 'Adresa', controller: _address, enabled: _editing),
                        const SizedBox(height: 10),
                        _ReadOnlyRow(label: 'Email', value: _me!.email),
                        const SizedBox(height: 6),
                        _ReadOnlyRow(label: 'Username', value: _me!.username),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Card(
                    title: 'Moje rezervacije',
                    trailing: Text(
                      '${_myReservations.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    child: _myReservations.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Nema rezervacija još uvijek.'),
                          )
                        : Column(
                            children: _myReservations
                                .map(
                                  (r) => _ReservationTile(
                                    title: r.listingTitle.isEmpty ? 'Rezervacija #${r.id}' : r.listingTitle,
                                    dateRange: '${_fmtDate(r.from)} → ${_fmtDate(r.to)}',
                                    status: _statusLabel(r.statusId, r.statusName),
                                    price: r.totalPrice,
                                    onTap: () => _openReservationActions(r),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 22),
                ],
              ),
            ),
    );
  }

  static String _fmtDate(DateTime? d) {
    if (d == null) return '?';
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

// ---------------- UI widgets (isti kao što si imala) ----------------

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String username;
  final String email;
  final String role;
  final bool active;

  const _ProfileHeader({
    required this.username,
    required this.email,
    required this.role,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2F5BFF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: const [
          BoxShadow(blurRadius: 10, offset: Offset(0, 4), color: Color(0x11000000)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person, color: blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Chip(text: role),
                    const SizedBox(width: 8),
                    _Chip(text: active ? 'Aktivan' : 'Neaktivan'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Card({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6E6E6)),
        boxShadow: const [
          BoxShadow(blurRadius: 10, offset: Offset(0, 4), color: Color(0x11000000)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;

  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF6F6F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ReservationTile extends StatelessWidget {
  final String title;
  final String dateRange;
  final String status;
  final double price;
  final VoidCallback? onTap;

  const _ReservationTile({
    required this.title,
    required this.dateRange,
    required this.status,
    required this.price,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E8E8)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(dateRange, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(status, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${price.toStringAsFixed(2)} KM',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}
